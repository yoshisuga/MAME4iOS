//
//  ZipFile.m
//
//  Created by Todd Laney on 2/12/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//

#import "ZipFile.h"
#import <Compression.h>

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#ifdef DEBUG
#define ERROR(...) (NSLog(@"ZipFile: " __VA_ARGS__), FALSE)
#else
#define ERROR(...) FALSE
#endif

@interface NSFileHandle (NSFileHandle_ReadWrite)
- (uint64_t)lengthOfFile;
- (uint64_t)offsetInFileSafe;
- (NSData*) readDataOfLength:(size_t)length atOffset:(uint64_t)offset;
- (BOOL) writeDataSafe:(NSData*)data;               // a *safe* version of writeData:
- (BOOL) writeBytes:(const void *)bytes length:(size_t)length;
@end

@interface NSData (NSData_Compression)
- (NSData*) inflated:(NSUInteger)expected_length;
- (NSData*) deflated;
- (uint32_t) crc32;
@end

@interface NSDate (NSDate_MSDOS)
+ (NSDate*) dateWithDosDateTime:(NSUInteger)datetime;
- (NSUInteger) dosDateTime;
@end

@implementation ZipFile

#pragma mark - ZipFile reading

// simple read-only access to a standard [ZIP](https://en.wikipedia.org/wiki/Zip_(file_format)) archive.
//
// ISO/IEC 21320-1:2015 requires the following main restrictions of the ZIP file format:
//
// * Files in ZIP archives may only be stored uncompressed, or using the "deflate" compression (i.e. compression method may contain the value "0" - stored or "8" - deflated).
// * The encryption features are prohibited.
// * The digital signature features are prohibited.
// * The "patched data" features are prohibited.
// * Archives may not span multiple volumes or be segmented.
//
// # Usage
// ```
// [ZipFile enumerate:path withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
//     NSLog(@"%@ %ld", info.name, info.uncompressed_size);
// }];
// ```
+ (BOOL)enumerate:(NSString*)path withOptions:(ZipFileEnumOptions)options usingBlock:(void (^)(ZipFileInfo* info))block
{ @autoreleasepool {
    
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:path];
    
    if (file == nil)
        return ERROR(@"cant open file");
    
    NSUInteger num_files = 0;
    NSUInteger central_dir_size;
    uint64_t   central_dir_offset;
    
    NSData*         buffer_data;
    const uint8_t*  buffer_ptr;
    NSUInteger      buffer_len;

#define LOAD(file, offset, num_bytes) \
    buffer_data = [file readDataOfLength:num_bytes atOffset:offset]; \
    buffer_ptr = [buffer_data bytes]; \
    buffer_len = [buffer_data length];
    
#define READ2()  (buffer_ptr += 2, buffer_len -= 2, OSReadLittleInt16(buffer_ptr, -2))
#define READ4()  (buffer_ptr += 4, buffer_len -= 4, OSReadLittleInt32(buffer_ptr, -4))
#define READ8()  (buffer_ptr += 8, buffer_len -= 8, OSReadLittleInt64(buffer_ptr, -8))
#define READN(n) (buffer_ptr += n, buffer_len -= n, [NSData dataWithBytes:buffer_ptr - n length:n])
#define SKIP(n)  (buffer_ptr += n, buffer_len -= n)

    // seek to the end and look for the EOCD, very very important! search backward! we dont want to find signature in an embedded zip!
    LOAD(file, file.lengthOfFile - 512, 512);
    uint8_t eocd_sig[] = {0x50, 0x4b, 0x05, 0x06};
    NSRange r = [buffer_data rangeOfData:[NSData dataWithBytes:&eocd_sig length:4] options:NSDataSearchBackwards range:NSMakeRange(0, [buffer_data length])];

    if (r.location == NSNotFound)
        return ERROR(@"bad zip file (cant find central directory)");

    SKIP(r.location - 20);

    // see if we have a ZIP64 EOCD header
    if (READ4() == 0x07064b50)
    {
        // zip64 end of central dir locator
        // signature                4 bytes  (0x07064b50)
        // disk number of EOCD      4 bytes
        // offset to EOCD64         8 bytes
        // total number of disks    4 bytes

        if (READ4() != 0)
            return ERROR(@"unsupported zip file (cant handle multifile)");

        LOAD(file, READ8(), 512);
        
        // zip64 end of central dir
        // signature                            4 bytes  (0x06064b50)
        // size of directory record             8 bytes
        // version made by                      2 bytes
        // version needed to extract            2 bytes
        // number of this disk                  4 bytes
        // number of the disk with EOCD         4 bytes
        // total number of entries on this disk 8 bytes
        // total number of entries              8 bytes
        // size of the central directory        8 bytes
        // offset of start of central directory 8 bytes
        // zip64 extensible data sector         (variable size)
        if (READ4() != 0x06064b50)
            return ERROR(@"bad zip file (cant find central directory)");
        SKIP(20);         // size + versions + disk numbers
        num_files = READ8();
        if (READ8() != num_files)
            return ERROR(@"unsupported zip file (cant handle multifile)");
                    
        central_dir_size = READ8();
        central_dir_offset = READ8();
    }
    else
    {
        SKIP(16);

        //  End of central directory record (EOCD)
        //  Offset   Bytes  Description
        //  0        4      End of central directory signature = 0x06054b50
        //  4        2      Number of this disk
        //  6        2      Disk where central directory starts
        //  8        2      Number of central directory records on this disk
        //  10       2      Total number of central directory records
        //  12       4      Size of central directory (bytes)
        //  16       4      Offset of start of central directory, relative to start of archive
        //  20       2      Comment length (n)
        //  22       n      Comment
        if (READ4() != 0x06054b50)
            return ERROR(@"bad zip file (cant find central directory)");

        SKIP(4);  // disk num
        num_files = READ2();
        if (READ2() != num_files)
            return ERROR(@"unsupported zip file (cant handle multifile)");
        
        central_dir_size = READ4(); // size of central directory
        central_dir_offset = READ4();
    }

    if (num_files == 0)
        return TRUE;
    
    if (block == nil)
        return TRUE;
    
    // read the entire central directory into memory
    LOAD(file, central_dir_offset, central_dir_size);
    
    if ([buffer_data length] != central_dir_size)
        return ERROR(@"bad zip file (cant read central directory)");
    
    for (int i=0; i<num_files; i++) @autoreleasepool {
        
        ZipFileInfo* info = [[ZipFileInfo alloc] init];
        
        // Central directory file header
        //        Offset    Bytes    Description
        //        0         4    Central directory file header signature = 0x02014b50
        //        4         2    Version made by
        //        6         2    Version needed to extract (minimum)
        //        8         2    General purpose bit flag
        //        10        2    Compression method
        //        12        2    File last modification time
        //        14        2    File last modification date
        //        16        4    CRC-32
        //        20        4    Compressed size
        //        24        4    Uncompressed size
        //        28        2    File name length (n)
        //        30        2    Extra field length (m)
        //        32        2    File comment length (k)
        //        34        2    Disk number where file starts
        //        36        2    Internal file attributes
        //        38        4    External file attributes
        //        42        4    Relative offset of local file header.
        //        46        n    File name
        //        46+n      m    Extra field
        //        46+n+m    k    File comment
        if (READ4()!= 0x02014b50)
            return ERROR(@"bad zip file (cant find central directory)");
        SKIP(6);   // versions, bit flag
        uint16_t compression = READ2();
        if (!(compression == 0 || compression == 8))
            return ERROR(@"unsupported zip file (bad compression)");
        uint32_t datetime = READ4();
        uint32_t crc32 = READ4();
        uint64_t compressed_size = READ4();
        uint64_t uncompressed_size = READ4();
        uint16_t name_len = READ2();
        uint16_t extra_len = READ2();
        uint16_t comment_len = READ2();
        SKIP(8);  // disk_num, internal_attr, external_attr
        uint64_t local_offset = READ4();
        NSData* name = READN(name_len);
        
        // get ZIP64 offset and size
        while (extra_len > 0)
        {
            uint16_t tag = READ2();
            uint16_t size = READ2();
            if (tag == 0x0001)
            {
                if (compressed_size == 0xFFFFFFFF)
                    compressed_size = READ8();
                if (uncompressed_size == 0xFFFFFFFF)
                    uncompressed_size = READ8();
                if (local_offset == 0xFFFFFFFF)
                    local_offset = READ8();
            }
            else {
                SKIP(size);
            }
            extra_len -= (size + 4);
        }
        SKIP(comment_len);
        
        // if the name is valid UTF8 use that, else assume [dosLatinUS](https://en.wikipedia.org/wiki/Code_page_437)
        info.name = [[NSString alloc] initWithData:name encoding:NSUTF8StringEncoding] ?:
                    [[NSString alloc] initWithData:name encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatinUS)];
        
        info.uncompressed_size = uncompressed_size;
        info.compressed_size = compressed_size;
        info.crc32 = crc32;
        info.method = compression;
        info.date = [NSDate dateWithDosDateTime:datetime];
        info.file = file;
        info.data = nil;

        if (uncompressed_size != 0)
        {
            NSData*         buffer_data;
            const uint8_t*  buffer_ptr;
            NSUInteger      buffer_len;
            
            // seek to the local file header and find location of the data
            LOAD(file, local_offset, 512);
            
            //  Local file header
            //  Offset    Bytes   Description
            //  0         4       Local file header signature = 0x04034b50 (read as a little-endian number)
            //  4         2       Version needed to extract (minimum)
            //  6         2       General purpose bit flag
            //  8         2       Compression method
            //  10        2       File last modification time
            //  12        2       File last modification date
            //  14        4       CRC-32
            //  18        4       Compressed size
            //  22        4       Uncompressed size
            //  26        2       File name length (n)
            //  28        2       Extra field length (m)
            //  30        n       File name
            //  30+n      m       Extra field
            if (READ4() != 0x04034b50)
                return ERROR(@"bad zip file (cant find local file header)");
            SKIP(22);    // verion, flags, compression. datetime, crc32, compressed size, uncompressed size
            name_len = READ2();
            extra_len = READ2();
            info.offset = local_offset + 30 + name_len + extra_len;
            
            // if the caller wants the data, load it and fail if error.
            if (options & ZipFileEnumLoadData)
            {
                if (info.data == nil)
                    return FALSE;
            }
        }

        if (!(options & ZipFileEnumDirectories) && info.isDirectory)
            continue;
        
        if (!(options & ZipFileEnumHidden) && info.isHidden)
            continue;
        
        block(info);
    }
    
    return TRUE;
}}

#pragma mark - ZipFile writing

// create a ZipFile from any user supplied data, callback is required to convert item in array to a ZipFileInfo
+ (BOOL)exportTo:(NSString*)path fromItems:(NSArray*)items withOptions:(ZipFileWriteOptions)options usingBlock:(ZipFileInfo* (^)(id item))loadHandler
{
    if (options & ZipFileWriteAtomic) {
        NSError* error = nil;
        NSURL* fileURL = [NSURL fileURLWithPath:path];
        NSURL* tempDIR = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:fileURL create:TRUE error:&error];

        if (error != nil)
            return ERROR(@"CANT CREATE TEMP DIRECTORY: %@", error);
        
        NSURL* tempURL = [tempDIR URLByAppendingPathComponent:[fileURL lastPathComponent]];
    
        BOOL result = [ZipFile exportTo:tempURL.path fromItems:items withOptions:(options & ~ZipFileWriteAtomic) usingBlock:loadHandler];
        
        if (result) {
            result = [NSFileManager.defaultManager replaceItemAtURL:fileURL withItemAtURL:tempURL backupItemName:nil options:0 resultingItemURL:nil error:&error];
            
            if (error != nil)
                return ERROR(@"CANT REPLACE FILE: %@ => %@ (%@)", tempURL, fileURL, error);
        }
        
        // delete the temp directory and everything in it.
        [NSFileManager.defaultManager removeItemAtURL:tempDIR error:nil];
        
        return result;
    }
    
    [NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:path];
   
#define BYTE2(x)    (((x) >> 0) & 0xFF), (((x) >> 8) & 0xFF)
#define BYTE4(x)    BYTE2(x), BYTE2(x >> 16)
#define BYTE8(x)    BYTE4(x), BYTE4((uint64_t)(x) >> 32)

    if (file == nil)
        return ERROR(@"cant open for writing");
    
    BOOL result = TRUE;
    NSMutableArray* all_info = [[NSMutableArray alloc] init];
    
    for (id item in items) @autoreleasepool {
        ZipFileInfo* info = loadHandler(item);
        
        if (info == nil)
            break;
    
        if (info.name == nil || info.name.length == 0)
            continue;
        
        if (!(options & ZipFileWriteDirectories) && [info isDirectory])
            continue;
        
        if (!(options & ZipFileWriteHidden) && [info isHidden])
            continue;
        
        NSData* data = info.data;
        uint32_t crc32 = [data crc32];
        uint64_t uncompressed_size = [data length];
        uint32_t datetime = (uint32_t)info.date.dosDateTime;
        if (!(options & ZipFileWriteNoCompress))
            data = [data deflated] ?: data;
        uint64_t compressed_size = [data length];
        uint32_t method = (compressed_size == uncompressed_size) ? 0 : 8;
        NSData* name_data = [info.name dataUsingEncoding:NSUTF8StringEncoding];
        uint16_t name_len = [name_data length];

        if (uncompressed_size >= 0xFFFFFFFF)
            return ERROR("big ZIP");

        uint8_t local_file_header[] = {
            BYTE4(0x04034b50),      // Local file header signature = 0x04034b50 (read as a little-endian number)
            BYTE2(45),              // Version needed to extract (minimum)
            BYTE2(0),               // General purpose bit flag
            BYTE2(method),          // Compression method
            BYTE4(datetime),        // last modification datetime
            BYTE4(crc32),           // CRC-32
            BYTE4(compressed_size), // Compressed size
            BYTE4(uncompressed_size),// Uncompressed size
            BYTE2(name_len),        // File name length
            BYTE2(0),               // Extra field length
        };
        [file writeBytes:local_file_header length:sizeof(local_file_header)];
        [file writeDataSafe:name_data];
        info.offset = [file offsetInFileSafe];
        [file writeDataSafe:data];
        
        if (([file offsetInFileSafe] - info.offset) != data.length)
            return ERROR("write error");

        info.crc32 = crc32;
        info.uncompressed_size = uncompressed_size;
        info.compressed_size = compressed_size;
        info.data = nil;
        [all_info addObject:info];
    }
    
    uint64_t central_directory_offset = [file offsetInFileSafe];
    
    for (ZipFileInfo* info in all_info) @autoreleasepool {
        
        uint32_t crc32 = info.crc32;
        uint32_t uncompressed_size = (uint32_t)info.uncompressed_size;
        uint32_t compressed_size = (uint32_t)info.compressed_size;
        uint32_t method = (compressed_size == uncompressed_size) ? 0 : 8;
        uint32_t datetime = (uint32_t)info.date.dosDateTime;
        NSData* name_data = [info.name dataUsingEncoding:NSUTF8StringEncoding];
        uint16_t name_len = [name_data length];
        uint64_t offset = info.offset - (30 + name_len);
        uint16_t extra_len = 0;
        uint32_t external_attr = (0100644<<16);     // -rw-r--r--
                                  
        if ([info isDirectory])
            external_attr = (040755<<16) + 0x10;    // drwxr-xr-x + MS-DOS dir bit

        // handle ZIP64
        if (offset >= 0xFFFFFFFF || (options & ZipFileWriteZip64)) {
            offset = 0xFFFFFFFF;
            extra_len = 12;
        }

        uint8_t central_directory_file_header[] = {
            BYTE4(0x02014b50),      // Central directory file header signature = 0x02014b50
            BYTE2(45 + 0x0300),     // Version made by (4.5) + OS (Unix)
            BYTE2(45),              // Version needed (4.5)
            BYTE2(0),               // General purpose bit flag
            BYTE2(method),          // Compression method
            BYTE4(datetime),        // last modification datetime
            BYTE4(crc32),           // CRC-32
            BYTE4(compressed_size), // Compressed size
            BYTE4(uncompressed_size),// Uncompressed size
            BYTE2(name_len),        // File name length
            BYTE2(extra_len),       // Extra field length
            BYTE2(0),               // comment length
            BYTE2(0),               // disk number
            BYTE2(0),               // Internal file attributes
            BYTE4(external_attr),   // External file attributes
            BYTE4(offset),          // offset of local file header
        };
        [file writeBytes:central_directory_file_header length:sizeof(central_directory_file_header)];
        [file writeDataSafe:name_data];
        if (extra_len) {
            uint64_t offset = info.offset - (30 + name_len);
            uint8_t extra[] = {
                BYTE2(0x0001),
                BYTE2(8),
                BYTE8(offset),
            };
            [file writeBytes:extra length:sizeof(extra)];
        }
    }
    uint64_t central_directory_size = [file offsetInFileSafe] - central_directory_offset;
    uint64_t central_directory_count = [all_info count];
    
    // handle ZIP64
    if (central_directory_offset >= 0xFFFFFFFF || (options & ZipFileWriteZip64)) {
        uint64_t offset = [file offsetInFileSafe];

        uint8_t central_directory_end_64[] = {
            BYTE4(0x06064b50),              // Zip64 End of central directory signature = 0x06064b50
            BYTE8(44),                      // size of this record
            BYTE2(45),                      // Version made by
            BYTE2(45),                      // Version needed
            BYTE4(0),                       // Number of this disk
            BYTE4(0),                       // Disk where central directory starts
            BYTE8(central_directory_count), // Number of central directory records on this disk
            BYTE8(central_directory_count), // Total number of central directory records
            BYTE8(central_directory_size),  // Size of central directory (bytes)
            BYTE8(central_directory_offset),// Offset of start of central directory
            
            BYTE4(0x07064b50),              // Zip64 End of central directory locator signature = 0x07064b50
            BYTE4(0),                       // disk number of EOCD
            BYTE8(offset),                  // offset to EOCD64
            BYTE4(1),                       // total number of disks
        };
        [file writeBytes:central_directory_end_64 length:sizeof(central_directory_end_64)];
        central_directory_offset = 0xFFFFFFFF;
    }
    
    uint8_t central_directory_end[] = {
        BYTE4(0x06054b50),              // End of central directory signature = 0x06054b50
        BYTE2(0),                       // Number of this disk
        BYTE2(0),                       // Disk where central directory starts
        BYTE2(central_directory_count), // Number of central directory records on this disk
        BYTE2(central_directory_count), // Total number of central directory records
        BYTE4(central_directory_size),  // Size of central directory (bytes)
        BYTE4(central_directory_offset),// Offset of start of central directory
        BYTE2(0),                       // Comment length
    };
    [file writeBytes:central_directory_end length:sizeof(central_directory_end)];
    
    return result;
}

// create a ZipFile from files in a directory.
+ (BOOL)exportTo:(NSString*)path fromDirectory:(NSString*)root withFiles:(nullable NSArray<NSString*>*)files withOptions:(ZipFileWriteOptions)options progressBlock:(nullable BOOL (^)(double progress))block
{
    BOOL isDirectory;
    if (!([NSFileManager.defaultManager fileExistsAtPath:root isDirectory:&isDirectory] && isDirectory))
        return ERROR("BAD DIRECTORY: %@", root);
    
    if (![root hasSuffix:@"/"])
        root = [root stringByAppendingString:@"/"];

    if (files == nil)
        files = [[NSFileManager.defaultManager enumeratorAtPath:root] allObjects];

    if (files.count == 0 && (options & ZipFileWriteDirectoryName))
        files = @[@""];
    
    BOOL result = [ZipFile exportTo:path fromItems:files withOptions:options usingBlock:^ZipFileInfo* (NSString* name) {
        
        ZipFileInfo* info = [[ZipFileInfo alloc] init];

        if (block) {
            BOOL cancel = block((double)[files indexOfObject:name] / [files count]);
            if (cancel)
                return nil;
        }
            
        if ([name hasPrefix:root])
            name = [name substringFromIndex:[root length]];
        
        NSString* path = [root stringByAppendingPathComponent:name];
        
        if (options & ZipFileWriteDirectoryName)
            name = [[root lastPathComponent] stringByAppendingPathComponent:name];
        
        BOOL isDirectory;
        if (![NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory])
            return info; // info.name == nil, item will be skiped.

        if (isDirectory) {
            if (![name hasSuffix:@"/"])
                name = [name stringByAppendingString:@"/"];
        }
        else {
            info.data = [NSData dataWithContentsOfFile:path];
        }
        info.name = name;
        info.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileModificationDate];

        return info;
    }];
    
    if (block)
        block(1.0);
    
    return result;
}

@end

#pragma mark - ZipFileInfo

@implementation ZipFileInfo

- (instancetype)init
{
    self = [super init];
    _name = @"";
    _date = [NSDate distantPast];
    return self;
}

// load data on-demand
- (NSData*)data {
    
    if (_data != nil)
        return _data;

    if (_uncompressed_size == 0)
        return [[NSData alloc] init];

    if (_file == nil)
        return nil;
    
    NSData* data = [_file readDataOfLength:_compressed_size atOffset:_offset];
    _file = nil;    // we dont need a ref to the file after data is loaded.

    if ([data length] != _compressed_size)
        return ERROR(@"read error (%d != %d)", (int)self.compressed_size, (int)[data length]) ? nil : nil;

    if (self.method == 8)
        data = [data inflated:_uncompressed_size];
    
    if ([data length] != _uncompressed_size)
        return ERROR(@"inflate error (%d != %d)", (int)self.uncompressed_size, (int)[data length]) ? nil : nil;

    if ([data crc32] != _crc32)
        return ERROR(@"crc32 error (%08X != %08X)", (int)self.crc32, [data crc32]) ? nil : nil;
    
    _data = data;
    return _data;
}

-(BOOL)isDirectory
{
    return ([_name hasSuffix:@"/"] || [_name hasSuffix:@"\\"]);
}
-(BOOL)isHidden
{
    return [[_name lastPathComponent] hasPrefix:@"."] || [_name hasPrefix:@"__MACOSX"];
}
@end

#pragma mark - NSFileHandle read/write

@implementation NSFileHandle (NSFileHandle_ReadWrite)

- (uint64_t)lengthOfFile
{
    uint64_t length = 0;
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        [self seekToEndReturningOffset:&length error:nil];
    }
    else {
        @try {
            length = [self seekToEndOfFile];
        } @catch (NSException *exception) {
            return 0;
        }
    }
    return length;
}

- (uint64_t) offsetInFileSafe
{
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        uint64_t offset = 0;
        [self getOffset:&offset error:nil];
        return offset;
    }
    else {
        @try {
            return [self offsetInFile];
        } @catch (NSException *exception) {
            return 0;
        }
    }
}

- (NSData*) readDataOfLength:(size_t)length atOffset:(uint64_t)offset
{
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        [self seekToOffset:offset error:nil];
        return [self readDataUpToLength:length error:nil];
    }
    else {
        @try {
            [self seekToFileOffset:offset];
            return [self readDataOfLength:length];
        } @catch (NSException *exception) {
            return nil;
        }
    }
}

- (BOOL) writeDataSafe:(NSData*)data
{
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        return [self writeData:data error:nil];
    }
    else {
        @try {
            [self writeData:data];
            return TRUE;
        } @catch (NSException *exception) {
            return FALSE;
        }
    }
}
- (BOOL) writeBytes:(const void *)bytes length:(size_t)length
{
    return [self writeDataSafe:[NSData dataWithBytes:bytes length:length]];
}
@end

#pragma mark - NSData compression helpers

@implementation NSData (NSData_Compression)

- (NSData*) inflated:(NSUInteger)expected_length
{
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        return [self decompressedDataUsingAlgorithm:NSDataCompressionAlgorithmZlib error:nil];
    }
    else {
        NSMutableData* data = [[NSMutableData alloc] initWithLength:expected_length];
        if (compression_decode_buffer(data.mutableBytes, [data length], self.bytes, [self length], nil, COMPRESSION_ZLIB) != expected_length)
            return nil;
        return data;
    }
}
- (NSData*) deflated
{
    if (@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)) {
        return [self compressedDataUsingAlgorithm:NSDataCompressionAlgorithmZlib error:nil];
    }
    else {
        NSMutableData* data = [[NSMutableData alloc] initWithLength:[self length]];
        data.length = compression_encode_buffer(data.mutableBytes, [data length], self.bytes, [self length], nil, COMPRESSION_ZLIB);
        return ([data length] != 0) ? data : nil;
    }
}

/// compute CRC32 (Slicing-by-16 algorithm)  from [Stephan Brumme](https://create.stephan-brumme.com/crc32)
uint32_t crc32_16bytes(const void* data, size_t length, uint32_t previousCrc32)
{
    const uint32_t Polynomial = 0xEDB88320; /// zlib's CRC32 polynomial
    static uint32_t Crc32Lookup[16][256];

    if (Crc32Lookup[0][1] == 0)
    {
        for (unsigned int i = 0; i <= 0xFF; i++)
        {
            uint32_t crc = i;
            for (unsigned int j = 0; j < 8; j++)
            crc = (crc >> 1) ^ ((crc & 1) * Polynomial);
            Crc32Lookup[0][i] = crc;
        }
        
        for (unsigned int i = 0; i <= 0xFF; i++) for (unsigned int slice = 1; slice < 16; slice++) {
            Crc32Lookup[slice][i] = (Crc32Lookup[slice - 1][i] >> 8) ^ Crc32Lookup[0][Crc32Lookup[slice - 1][i] & 0xFF];
        }
    }
    
    uint32_t crc = ~previousCrc32; // same as previousCrc32 ^ 0xFFFFFFFF
    const uint32_t* current = (const uint32_t*) data;
    // enabling optimization (at least -O2) automatically unrolls the for-loop
    const size_t Unroll = 1;    // uroll == 1 means dont unroll, unrolling did not seam to make a diff
    const size_t BytesAtOnce = 16 * Unroll;
    while (length >= BytesAtOnce)
    {
        for (size_t unrolling = 0; unrolling < Unroll; unrolling++)
        {
#ifdef __BIG_ENDIAN__
            uint32_t one   = *current++ ^ OSSwapInt32(crc);
            uint32_t two   = *current++;
            uint32_t three = *current++;
            uint32_t four  = *current++;
            crc  = Crc32Lookup[ 0][ four         & 0xFF] ^
                 Crc32Lookup[ 1][(four  >>  8) & 0xFF] ^
                 Crc32Lookup[ 2][(four  >> 16) & 0xFF] ^
                 Crc32Lookup[ 3][(four  >> 24) & 0xFF] ^
                 Crc32Lookup[ 4][ three        & 0xFF] ^
                 Crc32Lookup[ 5][(three >>  8) & 0xFF] ^
                 Crc32Lookup[ 6][(three >> 16) & 0xFF] ^
                 Crc32Lookup[ 7][(three >> 24) & 0xFF] ^
                 Crc32Lookup[ 8][ two          & 0xFF] ^
                 Crc32Lookup[ 9][(two   >>  8) & 0xFF] ^
                 Crc32Lookup[10][(two   >> 16) & 0xFF] ^
                 Crc32Lookup[11][(two   >> 24) & 0xFF] ^
                 Crc32Lookup[12][ one          & 0xFF] ^
                 Crc32Lookup[13][(one   >>  8) & 0xFF] ^
                 Crc32Lookup[14][(one   >> 16) & 0xFF] ^
                 Crc32Lookup[15][(one   >> 24) & 0xFF];
#else
          uint32_t one   = *current++ ^ crc;
          uint32_t two   = *current++;
          uint32_t three = *current++;
          uint32_t four  = *current++;
          crc  = Crc32Lookup[ 0][(four  >> 24) & 0xFF] ^
                 Crc32Lookup[ 1][(four  >> 16) & 0xFF] ^
                 Crc32Lookup[ 2][(four  >>  8) & 0xFF] ^
                 Crc32Lookup[ 3][ four         & 0xFF] ^
                 Crc32Lookup[ 4][(three >> 24) & 0xFF] ^
                 Crc32Lookup[ 5][(three >> 16) & 0xFF] ^
                 Crc32Lookup[ 6][(three >>  8) & 0xFF] ^
                 Crc32Lookup[ 7][ three        & 0xFF] ^
                 Crc32Lookup[ 8][(two   >> 24) & 0xFF] ^
                 Crc32Lookup[ 9][(two   >> 16) & 0xFF] ^
                 Crc32Lookup[10][(two   >>  8) & 0xFF] ^
                 Crc32Lookup[11][ two          & 0xFF] ^
                 Crc32Lookup[12][(one   >> 24) & 0xFF] ^
                 Crc32Lookup[13][(one   >> 16) & 0xFF] ^
                 Crc32Lookup[14][(one   >>  8) & 0xFF] ^
                 Crc32Lookup[15][ one          & 0xFF];
#endif
        }
        length -= BytesAtOnce;
    }
    const uint8_t* currentChar = (const uint8_t*) current;
    // remaining 1 to 63 bytes (standard algorithm)
    while (length-- != 0)
        crc = (crc >> 8) ^ Crc32Lookup[0][(crc & 0xFF) ^ *currentChar++];
    return ~crc; // same as crc ^ 0xFFFFFFFF
}

- (uint32_t) crc32
{
    const uint8_t* bytes = [self bytes];
    NSUInteger length = [self length];
    return crc32_16bytes(bytes, length, 0);
}

@end

#pragma mark - NSDate MSDOS

@implementation NSDate (NSDate_MSDOS)
//
//  The 32 bit date and time format used in the MSDOS and Windows FAT directory entry.
//  Each portion of the time stamp (year, month etc.) is encoded within specific bits of the 32bit time stamp.
//  The epoch for a DOS date is 1980 so this must be added to the date from bits 25-31.
//  This format has a granularity of 2 seconds and the data is stored as follows:
//
//            Year     Month    Day      Hour    Min      Seconds/2
//    Bits    31-25    24-21    20-16    15-11   10-5     4-0
//
+(NSDate*) dateWithDosDateTime:(NSUInteger)datetime
{
    NSDateComponents* components = [[NSDateComponents alloc] init];
    components.year   = ((datetime >> 25) & 0x7F) + 1980;
    components.month  = ((datetime >> 21) & 0x0F);
    components.day    = ((datetime >> 16) & 0x1F);
    components.hour   = ((datetime >> 11) & 0x1F);
    components.minute = ((datetime >>  5) & 0x3F);
    components.second = ((datetime >>  0) & 0x1F) * 2;
    components.timeZone = [NSTimeZone defaultTimeZone];
    return [[NSCalendar currentCalendar] dateFromComponents:components] ?: [NSDate distantPast];
}
-(NSUInteger)dosDateTime
{
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* components = [NSCalendar.currentCalendar components:units fromDate:self];
    return (((components.year - 1980) & 0x7F) << 25) |
                   ((components.month & 0x0F) << 21) |
                     ((components.day & 0x1F) << 16) |
                    ((components.hour & 0x1F) << 11) |
                  ((components.minute & 0x3F) <<  5) |
            (((components.second / 2) & 0x1F) <<  0) ;
}
@end
