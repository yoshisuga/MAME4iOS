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
#define ERROR(...)  FALSE
#endif

@interface NSFileHandle (NSFileHandle_Read)
- (uint16_t) read2;
- (uint32_t) read4;
- (uint64_t) read8;
- (void) skip:(NSInteger)skip;
@end

@interface NSData (NSData_Compression)
- (NSData*) inflated:(NSUInteger)length;
- (uint32_t) crc32;
@end

@interface ZipFileInfo ()
- (BOOL)loadDataFromFile:(NSFileHandle*)file;
@end

@implementation ZipFile

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
    
    //  seek to the end and look for the EOCD
    [file seekToFileOffset:[file seekToEndOfFile] - 512];
    NSData* data = [file readDataToEndOfFile];
    uint8_t eocd_sig[] = {0x50, 0x4b, 0x05, 0x06};
    NSRange r = [data rangeOfData:[NSData dataWithBytes:&eocd_sig length:4] options:0 range:NSMakeRange(0, [data length])];

    if (r.location == NSNotFound)
        return ERROR(@"bad zip file (cant find central directory)");

    [file seekToFileOffset:[file seekToEndOfFile] - [data length] + r.location - 20];
    
    // see if we have a ZIP64 EOCD header
    if ([file read4] == 0x07064b50)
    {
        // zip64 end of central dir locator
        // signature                4 bytes  (0x07064b50)
        // disk number of EOCD      4 bytes
        // offset to EOCD64         8 bytes
        // total number of disks    4 bytes

        if ([file read4] != 0)
            return ERROR(@"unsupported zip file (cant handle multifile)");

        [file seekToFileOffset:[file read8]];
        
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
        if ([file read4] != 0x06064b50)
            return ERROR(@"bad zip file (cant find central directory)");
        [file skip:20];         // size + versions + disk numbers
        num_files = [file read8];
        if ([file read8] != num_files)
            return ERROR(@"unsupported zip file (cant handle multifile)");
        [file skip:8];          // size
        [file seekToFileOffset:[file read8]];
    }
    else
    {
        [file skip:16];

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
        if ([file read4] != 0x06054b50)
            return ERROR(@"bad zip file (cant find central directory)");

        [file skip:4];
        num_files = [file read2];
        if ([file read2] != num_files)
            return ERROR(@"unsupported zip file (cant handle multifile)");
        
        [file skip:4];      // size of central directory
        [file seekToFileOffset:[file read4]];
    }

    if (num_files == 0)
        return TRUE;
    
    if (block == nil)
        return TRUE;
    
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
        if ([file read4] != 0x02014b50)
            return ERROR(@"bad zip file (cant find central directory)");
        [file skip:6];   // versions, bit flag
        uint16_t compression = [file read2];
        if (!(compression == 0 || compression == 8))
            return ERROR(@"unsupported zip file (bad compression)");
        uint32_t datetime = [file read4];
        uint32_t crc32 = [file read4];
        uint64_t compressed_size = [file read4];
        uint64_t uncompressed_size = [file read4];
        uint16_t name_len = [file read2];
        uint16_t extra_len = [file read2];
        uint16_t comment_len = [file read2];
        [file skip:8];  // disk_num, internal_attr, external_attr
        uint64_t local_offset = [file read4];
        uint64_t next_entry = [file offsetInFile] + name_len + extra_len + comment_len;
        NSData* name = [file readDataOfLength:name_len];
        
        // get ZIP64 offset and size
        while (extra_len > 0)
        {
            uint16_t tag = [file read2];
            uint16_t size = [file read2];
            uint64_t next = [file offsetInFile] + size;
            if (tag == 0x0001)
            {
                if (compressed_size == 0xFFFFFFFF)
                    compressed_size = [file read8];
                if (uncompressed_size == 0xFFFFFFFF)
                    uncompressed_size = [file read8];
                if (local_offset == 0xFFFFFFFF)
                    local_offset = [file read8];
            }
            [file seekToFileOffset:next];
            extra_len -= (size + 4);
        }
        
        // if the name is valid UTF8 use that, else assume [dosLatinUS](https://en.wikipedia.org/wiki/Code_page_437)
        info.name = [[NSString alloc] initWithData:name encoding:NSUTF8StringEncoding] ?:
                    [[NSString alloc] initWithData:name encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatinUS)];
        
        info.uncompressed_size = uncompressed_size;
        info.compressed_size = compressed_size;
        info.crc32 = crc32;
        info.method = compression;

        //
        //  The 32 bit date and time format used in the MSDOS and Windows FAT directory entry.
        //  Each portion of the time stamp (year, month etc.) is encoded within specific bits of the 32bit time stamp.
        //  The epoch for a DOS date is 1980 so this must be added to the date from bits 25-31.
        //  This format has a granularity of 2 seconds and the data is stored as follows:
        //
        //            Year     Month    Day      Hour    Min      Seconds/2
        //    Bits    31-25    24-21    20-16    15-11    10-5    4-0
        //
        NSDateComponents* components = [[NSDateComponents alloc] init];
        components.year   = ((datetime >> 25) & 0x7F) + 1980;
        components.month  = ((datetime >> 21) & 0x0F);
        components.day    = ((datetime >> 16) & 0x1F);
        components.hour   = ((datetime >> 11) & 0x1F);
        components.minute = ((datetime >>  5) & 0x3F);
        components.second = ((datetime >>  0) & 0x1F) * 2;
        components.timeZone = [NSTimeZone defaultTimeZone];
        
        info.date = [[NSCalendar currentCalendar] dateFromComponents:components] ?: [NSDate distantPast];
        
        // seek to the local file header and find location of the data
        [file seekToFileOffset:local_offset];
        
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
        if ([file read4] != 0x04034b50)
            return ERROR(@"bad zip file (cant find local file header)");
        [file skip:22];    // verion, flags, compression. datetime, crc32, compressed size, uncompressed size
        name_len = [file read2];
        extra_len = [file read2];
        info.offset = [file offsetInFile] + name_len + extra_len;
        
        // if the caller wants the data, go get it!
        if (options & ZipFileEnumLoadData)
        {
            if (![info loadDataFromFile:file])
                return FALSE;
        }

        [file seekToFileOffset:next_entry];
        
        if (!(options & ZipFileEnumDirectories) && info.isDirectory)
            continue;
        
        if (!(options & ZipFileEnumHidden) && info.isHidden)
            continue;
        
        block(info);
    }
    
    return TRUE;
}}

// destructivly enumerate all the files in a zip archive, this is used to unzip a large zip file "in place" saving disk space. when this call returns the zip file is gone.
+ (BOOL)destructiveEnumerate:(NSString*)path withOptions:(ZipFileEnumOptions)options usingBlock:(void (^)(ZipFileInfo* info))block;
{ @autoreleasepool {
    NSMutableArray* all_info = [[NSMutableArray alloc] init];
    
    BOOL result = [self enumerate:path withOptions:(options & ~ZipFileEnumLoadData) usingBlock:^(ZipFileInfo* info) {
        [all_info addObject:info];
    }];
    
    if (!result)
        return FALSE;

    for (ZipFileInfo* info in all_info) @autoreleasepool {
        if (info.isDirectory)
            block(info);
    }

    // sort info by offset in file
    [all_info sortUsingComparator:^NSComparisonResult(ZipFileInfo* lhs, ZipFileInfo* rhs) {
        return (lhs.offset == rhs.offset) ? NSOrderedSame : ((lhs.offset < rhs.offset) ? NSOrderedAscending : NSOrderedDescending);
    }];
    
    NSFileHandle* file = [NSFileHandle fileHandleForUpdatingAtPath:path];
    
    if (file == nil)
        return ERROR(@"cant open for writing");
    
    // walk the files backward, so we can truncate the file from the top down
    for (ZipFileInfo* info in [all_info reverseObjectEnumerator]) @autoreleasepool {
        if (info.isDirectory)
            continue;
        result = [info loadDataFromFile:file];
        if (!result)
            break;
        [file truncateFileAtOffset:info.offset];
        block(info);
        info.data = nil;
    }
    
    // close the file before trying to delete it.
    file = nil;
    
    NSError* error = nil;
    result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];

    if (!result)
        return ERROR(@"removeItemAtPath ERROR: %@", error);
    
    return result;
}}

@end

#pragma mark - ZipFileInfo

@implementation ZipFileInfo

- (BOOL)loadDataFromFile:(NSFileHandle*)file
{
    [file seekToFileOffset:self.offset];
    NSData* data = [file readDataOfLength:self.compressed_size];
    self.data = nil;

    if ([data length] != self.compressed_size)
        return ERROR(@"read error (%d != %d)", (int)self.compressed_size, (int)[data length]);

    if (self.method == 8)
        data = [data inflated:self.uncompressed_size];
    
    if ([data length] != self.uncompressed_size)
        return ERROR(@"inflate error (%d != %d)", (int)self.uncompressed_size, (int)[data length]);

    if ([data crc32] != self.crc32)
        return ERROR(@"crc32 error (%08X != %08X)", (int)self.crc32, [data crc32]);
    
    self.data = data;
    return TRUE;
}

-(BOOL)isDirectory
{
    return ([self.name hasSuffix:@"/"] || [self.name hasSuffix:@"\\"]);
}
-(BOOL)isHidden
{
    return [[self.name lastPathComponent] hasPrefix:@"."] || [self.name hasPrefix:@"__MACOSX"];
}
@end

#pragma mark - NSFileHandle read word, dword, qword

@implementation NSFileHandle (NSFileHandle_Read)

- (uint16_t) read2
{
    NSData* data = [self readDataOfLength:2];
    
    if ([data length] != 2)
        return 0xFFFF;
        
    const uint8_t* b = (const uint8_t*)data.bytes;
    return ((uint32_t)b[0] << 0) + ((uint32_t)b[1] << 8);
}
                                          
- (uint32_t) read4
{
    NSData* data = [self readDataOfLength:4];
    
    if ([data length] != 4)
        return 0xFFFFFFFF;
        
    const uint8_t* b = (const uint8_t*)data.bytes;
    return ((uint32_t)b[0] << 0) + ((uint32_t)b[1] << 8) + ((uint32_t)b[2] << 16) + ((uint32_t)b[3] << 24);
}

- (uint64_t) read8
{
    return (uint64_t)[self read4] + ((uint64_t)[self read4] << 32);
}

- (void) skip:(NSInteger)skip
{
    [self seekToFileOffset:[self offsetInFile] + skip];
}

@end

#pragma mark - NSData compression helpers

@implementation NSData (NSData_Compression)

- (NSData*) inflated:(NSUInteger)length
{
    NSMutableData* data = [[NSMutableData alloc] initWithLength:length];
    NSMutableData* temp = [[NSMutableData alloc] initWithLength:compression_decode_scratch_buffer_size(COMPRESSION_ZLIB)];

    length = compression_decode_buffer(data.mutableBytes, [data length], self.bytes, [self length], temp.mutableBytes, COMPRESSION_ZLIB);
    
    if (length != [data length])
        return nil;
    
    return data;
}
// from [gist](https://gist.github.com/antfarm/695fa78e0730b67eb094c77d53942216)
- (uint32_t) crc32
{
    static uint32_t table[256];
    
    if (table[0] == 0)
    {
        for (int i=0; i<256; i++)
        {
            uint32_t c = i;
            for (int j=0; j<8; j++)
                c = (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1));
            table[i] = c;
        }
    }
    
    const uint8_t* bytes = [self bytes];
    NSUInteger length = [self length];
    
    uint32_t crc = ~0;
    while (length-- != 0)
        crc = (crc >> 8) ^ table[(crc ^ *bytes++) & 0xFF];
    
    return ~crc;
}
@end



