//
//  ZipFile.h
//
//  Created by Todd Laney on 2/12/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, ZipFileEnumOptions) {
    ZipFileEnumFiles        = 0,
    ZipFileEnumDirectories  = (1 << 0),
    ZipFileEnumHidden       = (1 << 1),
    ZipFileEnumLoadData     = (1 << 8),
    ZipFileEnumAll          = (ZipFileEnumFiles + ZipFileEnumDirectories + ZipFileEnumHidden),
};

typedef NS_OPTIONS(NSUInteger, ZipFileWriteOptions) {
    ZipFileWriteFiles         = 0,
    ZipFileWriteDirectories   = (1 << 0),
    ZipFileWriteHidden        = (1 << 1),
    ZipFileWriteAtomic        = (1 << 8),
    ZipFileWriteZip64         = (1 << 9),
    ZipFileWriteDirectoryName = (1 << 10),
    ZipFileWriteNoCompress    = (1 << 11),
    ZipFileWriteAll           = (ZipFileWriteFiles + ZipFileWriteDirectories + ZipFileWriteHidden),
};


NS_ASSUME_NONNULL_BEGIN

@interface ZipFileInfo : NSObject
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSDate* date;
@property(nonatomic, strong, nullable) NSData* data;
@property(nonatomic, assign) NSUInteger method;
@property(nonatomic, assign) NSUInteger uncompressed_size;
@property(nonatomic, assign) NSUInteger compressed_size;
@property(nonatomic, assign) uint32_t crc32;
@property(nonatomic, assign) uint64_t offset;
@property(nonatomic, assign) BOOL cancel;
-(BOOL)isDirectory;
-(BOOL)isHidden;
@end

@interface ZipFile : NSObject

// enumerate all files in a ZipFile, and if requested also load the data.
+ (BOOL)enumerate:(NSString*)path withOptions:(ZipFileEnumOptions)options usingBlock:(nullable void (^)(ZipFileInfo* info))block;

// create a ZipFile from any user supplied data
+ (BOOL)exportTo:(NSString*)path fromItems:(NSArray*)items withOptions:(ZipFileWriteOptions)options usingBlock:(ZipFileInfo* (^)(id item))loadHandler;

// create a ZipFile from files in a directory.
+ (BOOL)exportTo:(NSString*)path fromDirectory:(NSString*)root withFiles:(nullable NSArray<NSString*>*)files withOptions:(ZipFileWriteOptions)options progressBlock:(nullable BOOL (^)(double progress))block;

@end

NS_ASSUME_NONNULL_END
