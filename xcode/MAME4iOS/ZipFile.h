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
-(BOOL)isDirectory;
-(BOOL)isHidden;
@end

@interface ZipFile : NSObject

// enumerate all files in a ZipFile, and if requested also load the data.
+ (BOOL)enumerate:(NSString*)path withOptions:(ZipFileEnumOptions)options usingBlock:(nullable void (^)(ZipFileInfo* info))block;

// destructivly enumerate all the files in a zip archive, this is used to unzip a large zip file "in place" saving disk space. when this call returns the zip file is gone.
+ (BOOL)destructiveEnumerate:(NSString*)path withOptions:(ZipFileEnumOptions)options usingBlock:(void (^)(ZipFileInfo* info))block;

@end

NS_ASSUME_NONNULL_END
