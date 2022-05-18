//
//  GameInfo.m
//  MAME4iOS
//
//  Created by ToddLa on 4/5/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

#import "GameInfo.h"

@implementation GameInfo
{
    NSDictionary<NSString*, NSString*>* dict;
}

// create from a NSDictionary
- (instancetype)initWithDictionary:(NSDictionary<NSString*,NSString*>*)info
{
    self = [super init];
    dict = info;
    return self;
}

// convert to a NSDictionary
-(NSDictionary<NSString*,NSString*>*) gameDictionary
{
    return dict;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (other == nil)
        return NO;
    if (![other isKindOfClass:[GameInfo class]])
        return NO;
    
    return [dict isEqualToDictionary:[(GameInfo*)other gameDictionary]];
}

- (NSUInteger)hash
{
    return dict.hash;
}

-(NSString*)gameType
{
    return dict[kGameInfoType] ?: kGameInfoTypeArcade;
}
-(NSString*)gameSystem
{
    return dict[kGameInfoSystem] ?: @"";
}
-(NSString*)gameSoftwareMedia
{
    return dict[kGameInfoSoftwareMedia] ?: @"";
}
-(NSString*)gameSoftwareList
{
    return dict[kGameInfoSoftwareList] ?: @"";
}
-(NSString*)gameName
{
    return dict[kGameInfoName] ?: @"";
}
-(NSString*)gameParent
{
    return dict[kGameInfoParent] ?: @"";
}
-(NSString*)gameYear
{
    return dict[kGameInfoYear] ?: @"";
}
-(NSString*)gameDescription
{
    return dict[kGameInfoDescription] ?: @"";
}
-(NSString*)gameManufacturer
{
    return dict[kGameInfoManufacturer] ?: @"";
}
-(NSString*)gameDriver
{
    return dict[kGameInfoDriver] ?: @"";
}
-(NSString*)gameScreen
{
    return dict[kGameInfoScreen] ?: kGameInfoScreenHorizontal;
}
-(NSString*)gameCategory
{
    return dict[kGameInfoCategory] ?: @"";
}
- (BOOL)gameIsMame
{
    return [self.gameName isEqualToString:kGameInfoNameMameMenu];
}
- (NSString*)gameFile
{
    return dict[kGameInfoFile] ?: @"";
}
- (NSString*)gameMediaType
{
    return dict[kGameInfoMediaType] ?: @"";
}
- (NSString*)gameCustomCmdline
{
    return dict[kGameInfoCustomCmdline] ?: @"";
}
- (BOOL)gameIsSnapshot
{
    return [self.gameType isEqualToString:kGameInfoTypeSnapshot];
}
- (BOOL)gameIsSoftware
{
    return [self.gameType isEqualToString:kGameInfoTypeSoftware];
}
- (BOOL)gameIsConsole
{
    return [self.gameType isEqualToString:kGameInfoTypeConsole];
}
- (BOOL)gameIsClone
{
    return self.gameParent.length > 1;  // parent can be "0"
}
-(NSString*)gameTitle
{
    NSString* title = dict[kGameInfoDescription] ?: dict[kGameInfoName] ?: @"";
    title = [title componentsSeparatedByString:@" ("].firstObject;
    title = [title componentsSeparatedByString:@" ["].firstObject;
    return title;
}

// MARK: Image URL

-(NSArray<NSURL*>*)gameImageURLs
{
    NSParameterAssert(self.gameName.length != 0);
    NSParameterAssert(![self.gameName containsString:@" "]);
    NSParameterAssert(![self.gameSystem containsString:@" "]);
    
    if (self.gameIsMame || self.gameIsSnapshot) {
        return @[];
    }
    else if (self.gameSoftwareList.length != 0)
    {
        /// MESS style title url
        /// http://adb.arcadeitalia.net/media/mess.current/titles/a2600/adventur.png
        /// http://adb.arcadeitalia.net/media/mess.current/ingames/a2600/pitfall.png
        
        NSString* base = @"http://adb.arcadeitalia.net/media/mess.current";
        NSString* list = self.gameSoftwareList;
        NSString* name = self.gameName.lowercaseString;
        
        name = [name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        
        return @[
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/covers/%@/%@.png", base, list, name]],
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/titles/%@/%@.png", base, list, name]],
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/ingames/%@/%@.png", base, list, name]],
        ];
    }
    else if (self.gameIsConsole)
    {
        /// MESS style title url
        /// http://adb.arcadeitalia.net/media/mame.current/cabinets/n64.png
        /// http://adb.arcadeitalia.net/media/mame.current/titles/n64.png
        
        NSString* base = @"http://adb.arcadeitalia.net/media/mame.current";
        NSString* name = self.gameName.lowercaseString;
        
        name = [name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        
        return @[
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/cabinets/%@.png", base, name]],
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/titles/%@.png", base, name]],
        ];
   }
   else if (self.gameIsSoftware) {
        // NOTE if software has an icon, it will have a software list name, and will get handled above
        return @[];
   }
   else
   {
        NSParameterAssert(self.gameDescription.length != 0);

        /// libretro title url
        /// https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles/pacman.png
        
        NSString* name = self.gameDescription;
        NSString* base = @"https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles";
        
        /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
        /// The following characters in titles must be replaced with _ in the corresponding filename: &*/:`<>?\|
        for (NSString* str in @[@"&", @"*", @"/", @":", @"`", @"<", @">", @"?", @"\\", @"|"])
            name = [name stringByReplacingOccurrencesOfString:str withString:@"_"];
        
        name = [name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        
        NSURL* libretro_url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.png", base, name]];
        
        /// MAME title url
        /// http://adb.arcadeitalia.net/media/mame.current/titles/n64.png
        
        base = @"http://adb.arcadeitalia.net/media/mame.current/titles";
        name = self.gameName.lowercaseString;
        NSURL* arcadeitalia_url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.png", base, name]];

        return @[libretro_url, arcadeitalia_url];
    }
}
-(NSURL*)gameLocalImageURL
{
    NSString* name = self.gameName;
    
    if (name.length == 0)
        return nil;
    
    if (self.gameIsMame)
        return [[NSBundle mainBundle] URLForResource:name withExtension:@"png"];
    
#if TARGET_OS_IOS
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#elif TARGET_OS_TV
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    
    if (self.gameIsSnapshot)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, self.gameFile] isDirectory:NO];
    else if (self.gameIsSoftware)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.png", path, self.gameFile] isDirectory:NO];
    else if (self.gameSoftwareList.length != 0)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/titles/%@/%@.png", path, self.gameSoftwareList, name] isDirectory:NO];
    else
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/titles/%@.png", path, name] isDirectory:NO];
}

// MARK: Play URL

-(NSURL*)gamePlayURL
{
    if (self.gameIsSoftware)
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@/%@:%@", self.gameSystem, self.gameMediaType, self.gameFile]];
    else if (self.gameSystem.length != 0)
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@/%@", self.gameSystem, self.gameName]];
    else
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@", self.gameName]];
}
// create from a URL
// handle our own scheme mame4ios://game OR mame4ios://system/game OR mame4ios://system/type:file
- (instancetype)initWithURL:(NSURL*)url
{
    if (![url.scheme isEqualToString:@"mame4ios"] || [url.host length] == 0 || [url.query length] != 0)
        return nil;

    NSDictionary* dict;
    
    NSString* path = url.path;
    if ([path hasPrefix:@"/"])
        path = [path substringFromIndex:1];
    
    NSArray* arr = [path componentsSeparatedByString:@":"];
    
    if (arr.count == 2)
        dict = @{kGameInfoSystem:url.host, kGameInfoMediaType:arr.firstObject, kGameInfoFile:arr.lastObject};
    else if ([path length] != 0)
        dict = @{kGameInfoSystem:url.host, kGameInfoName:path};
    else
        dict = @{kGameInfoName:url.host};
    
    return [self initWithDictionary:dict];
}

// MARK: Metadata

// get the sidecar file used to store custom metadata/info
-(NSString*) gameMetadataFile
{
#if TARGET_OS_IOS
    NSString *root = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#elif TARGET_OS_TV
    NSString *root = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    if (self.gameFile.length != 0)
        return [NSString stringWithFormat:@"%@/%@.json", root, self.gameFile];
    else if (self.gameSoftwareList.length != 0)
        return [NSString stringWithFormat:@"%@/roms/%@/%@.json", root, self.gameSoftwareList, self.gameName];
    else
        return [NSString stringWithFormat:@"%@/roms/%@.json", root, self.gameName];
}
// load any on-disk metadata json
-(NSDictionary*) gameMetadata
{
    NSString* path = self.gameMetadataFile;
    if (path.length == 0)
        return nil;
    
    NSData* data = [NSData dataWithContentsOfFile:path];
    if (data == nil)
        return nil;
    
    NSDictionary* info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![info isKindOfClass:[NSDictionary class]])
        return nil;
    
    return info;
}
// modify custom metadata key, and save to sidecar, return modified game
-(void)gameSetValue:(NSString*)value forKey:(NSString*)key
{
    if ([value isEqualToString:(dict[key] ?: @"")])
        return;
    
    if (self.gameMetadataFile.length != 0)
    {
        NSMutableDictionary* info = [(self.gameMetadata ?: @{}) mutableCopy];
        [info setValue:value forKey:key];
        NSData* data = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:self.gameMetadataFile atomically:NO];
    }

    NSMutableDictionary* mdict = [dict mutableCopy];
    [mdict setValue:value forKey:key];
    dict = [mdict copy];
}
// load and merge any on-disk metadata for this game
-(void)gameLoadMetadata
{
    NSDictionary* info = self.gameMetadata;
    if (info.count == 0)
        return;
    NSMutableDictionary* mdict = [dict mutableCopy];
    [mdict addEntriesFromDictionary:info];
    dict = [mdict copy];
}

@end
