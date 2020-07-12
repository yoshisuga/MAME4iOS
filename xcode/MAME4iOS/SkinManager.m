//
//  SkinManager.m
//  MAME4iOS
//
//  Created by Todd Laney on 7/11/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "SkinManager.h"
#import "ZipFile.h"
#import "Globals.h"

@implementation SkinManager {
    NSString* _skin_name;
    NSString* _skin_path;
    NSCache* _image_cache;
}

static NSArray* g_skin_list;

//
// return the list of valid Skins
//
+ (NSArray<NSString*>*)getSkinNames {
    
    if (g_skin_list != nil)
        return g_skin_list;
    
    NSMutableArray* skins = [[NSMutableArray alloc] init];

    // add in the Default skin always.
    [skins addObject:kSkinNameDefault];
    
    // get built-in skins
    NSString* path = [NSString stringWithUTF8String:get_resource_path("skins")];
    NSArray* files = [[NSFileManager.defaultManager enumeratorAtPath:path] allObjects];
    
    // add any custom skins
    path = [NSString stringWithUTF8String:get_documents_path("skins")];
    files = [files arrayByAddingObjectsFromArray:[[NSFileManager.defaultManager enumeratorAtPath:path] allObjects]];
    
    for (NSString* file in files) {
        if ([file.pathExtension.uppercaseString isEqualToString:@"ZIP"])
            [skins addObject:file.lastPathComponent.stringByDeletingPathExtension];
    }
    
    g_skin_list = skins;
    return skins;
}

- (instancetype)init {
    self = [super init];
    _skin_name = kSkinNameDefault;
    return self;
}

- (void)setCurrentSkin:(NSString*)name {
    
    if (name == nil || name.length == 0)
        name = kSkinNameDefault;
    
    if ([name isEqualToString:_skin_name])
        return;
    
    NSLog(@"LOADING SKIN: %@", name);
    
    _skin_name = kSkinNameDefault;
    _skin_path = nil;
    _image_cache = nil;

    // look for the Skin first in the user directory, then as a resource, else fail to default.
    NSString* path = [NSString stringWithFormat:@"%s/%@.zip", get_documents_path("skins"), name];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:path])
        path = [NSString stringWithFormat:@"%s/%@.zip", get_resource_path("skins"), name];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        NSLog(@"SKIN FILE NOT FOUND: %@", path);
        return;
    }
    
    _skin_name = name;
    _skin_path = path;
}
- (void)update {
    g_skin_list = nil;
    _image_cache = nil;
}

- (nullable UIImage *)loadImage:(NSString *)name {
    
    if (_image_cache == nil)
        _image_cache = [[NSCache alloc] init];
    
    UIImage* image = [_image_cache objectForKey:name];
    
    if ([image isKindOfClass:[UIImage class]])
        return image;
    if (image != nil)
        return nil;
    
    NSLog(@"SKIN IMAGE LOAD: %@", name);
    
    // cache miss, look for the image...
    // 1. in the skin file
    if (_skin_path != nil) {
        __block NSData* data = nil;
        NSString* uname = name.stringByDeletingPathExtension.uppercaseString;
        [ZipFile enumerate:_skin_path withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
            NSString* name = info.name.lastPathComponent.stringByDeletingPathExtension.uppercaseString;
            NSString* ext = info.name.pathExtension.uppercaseString;
            if (!([ext isEqualToString:@"PNG"] || [ext isEqualToString:@"JPG"]) || data != nil)
                return;
            if ([name isEqualToString:uname])
                data = info.data;
        }];
        if (data != nil)
            image = [UIImage imageWithData:data];
    }

    // 2. as a resource (in SKIN_1)
    if (image == nil) {
        NSString *path = [NSString stringWithUTF8String:get_resource_path("SKIN_1")];
        image = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:name]];
    }

    // 1. as a resource
    if (image == nil) {
        NSString *path = [NSString stringWithUTF8String:get_resource_path("")];
        image = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:name]];
    }
    
    if (image == nil) {
        NSLog(@"SKIN IMAGE NOT FOUND: %@", name);
    }

    [_image_cache setObject:(image ?: [NSNull null]) forKey:name];
    return image;
}

- (void)exportToURL:(NSURL*)url {
    
}


@end
