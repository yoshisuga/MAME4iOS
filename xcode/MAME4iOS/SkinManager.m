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

#define DebugLog 1
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

@implementation SkinManager {
    NSString* _skin_name;
    NSString* _skin_path;
    NSDictionary* _skin_info;
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
    _skin_info = nil;
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

    // load skin.json if present.
    NSData* data = [self loadData:@"skin.json"];
    if (data != nil) {
        NSDictionary* info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([info isKindOfClass:[NSDictionary class]])
            _skin_info = info;
    }
}

- (void)update {
    g_skin_list = nil;
    _image_cache = nil;
}

- (nullable NSData *)loadData:(NSString *)name {
    NSString* uname = name.uppercaseString;
    __block NSData* data = nil;
    [ZipFile enumerate:_skin_path withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        if ([info.name.uppercaseString isEqualToString:uname])
            data = info.data;
        else if ([info.name.lastPathComponent.uppercaseString isEqualToString:uname])
            data = info.data;
        else if ([info.name.lastPathComponent.stringByDeletingPathExtension.uppercaseString isEqualToString:uname])
            data = info.data;
    }];
    return data;
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
        NSData* data = [self loadData:name];
        if (data != nil)
            image = [UIImage imageWithData:data];
    }

    // 2. as a resource (in SKIN_1)
    if (image == nil)
        image = [UIImage imageNamed:[NSString stringWithFormat:@"SKIN_1/%@", name]];

    // 3. as a resource
    if (image == nil)
        image = [UIImage imageNamed:name];
    
    if (image == nil)
        NSLog(@"SKIN IMAGE NOT FOUND: %@", name);

    [_image_cache setObject:(image ?: [NSNull null]) forKey:name];
    return image;
}

#pragma mark skin export template

// all possible files in a Skin, used to export a template
+ (NSArray<NSString*>*)getSkinFiles {

    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    // get built-in images
    NSString* path = [NSString stringWithUTF8String:get_resource_path("SKIN_1")];
    for (NSString* file in [NSFileManager.defaultManager enumeratorAtPath:path]) {
        if ([file.pathExtension.uppercaseString isEqualToString:@"PNG"])
            [files addObject:file];
    }
    
    // add other images/etc
    [files addObjectsFromArray:@[
            @"skin.json", @"README.md",
            @"border", @"background",
            @"stick-U", @"stick-D", @"stick-L", @"stick-R",
            @"stick-UL", @"stick-DL", @"stick-DR", @"stick-UR",
    ]];
    
    return files;
}

- (NSDictionary*)getSkinInfo {
    return _skin_info ?: @{@"skin":@{@"version":@(1)}};
}

- (BOOL)exportTo:(NSString*)path progressBlock:(nullable BOOL (NS_NOESCAPE ^)(double progress))block {
    NSArray* files = [SkinManager getSkinFiles];
    
    NSLog(@"SKIN EXPORT: %@\n%@", path, files);

    return [ZipFile exportTo:path fromItems:files withOptions:ZipFileWriteFiles usingBlock:^ZipFileInfo * (NSString* name) {
        
        if (block) {
            BOOL cancel = block((double)[files indexOfObject:name] / [files count]);
            if (cancel)
                return nil;
        }
        
        if (name.pathExtension.length == 0)
            name = [name stringByAppendingPathExtension:@"png"];
        
        NSData* data = nil;
        
        if ([name isEqualToString:@"skin.json"])
            data = [NSJSONSerialization dataWithJSONObject:[self getSkinInfo] options:NSJSONWritingPrettyPrinted error:nil];
        else if ([name isEqualToString:@"README.md"])
            data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:[NSString stringWithFormat:@"skins/%@", name] ofType:nil]];
        else
            data = UIImagePNGRepresentation([self loadImage:name]);
        
        if (data != nil)
            NSLog(@"    FILE: %@ (%d bytes)", name, (int)[data length]);
        else
            NSLog(@"    FILE: %@ ** SKIPPED **", name);
        
        ZipFileInfo* info = [[ZipFileInfo alloc] init];
        info.name = data ? name : nil;      // name==nil => skip file
        info.data = data;
        info.date = [NSDate date];
        return info;
    }];
}


@end
