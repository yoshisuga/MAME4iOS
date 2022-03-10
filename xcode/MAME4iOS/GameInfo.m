//
//  GameInfo.m
//  MAME4iOS
//
//  Created by ToddLa on 4/5/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

#import "GameInfo.h"

@implementation NSDictionary (GameInfo)

-(NSString*)gameType
{
    return self[kGameInfoType] ?: kGameInfoTypeArcade;
}
-(NSString*)gameSystem
{
    return self[kGameInfoSystem] ?: @"";
}
-(NSString*)gameSoftwareMedia
{
    return self[kGameInfoSoftwareMedia] ?: @"";
}
-(NSString*)gameSoftwareList
{
    return self[kGameInfoSoftwareList] ?: self[kGameInfoSystem] ?: @"";
}
-(NSString*)gameName
{
    return self[kGameInfoName] ?: @"";
}
-(NSString*)gameParent
{
    return self[kGameInfoParent] ?: @"";
}
-(NSString*)gameYear
{
    return self[kGameInfoYear] ?: @"";
}
-(NSString*)gameDescription
{
    return self[kGameInfoDescription] ?: @"";
}
-(NSString*)gameManufacturer
{
    return self[kGameInfoManufacturer] ?: @"";
}
-(NSString*)gameDriver
{
    return self[kGameInfoDriver] ?: @"";
}
-(NSString*)gameScreen
{
    return self[kGameInfoScreen] ?: kGameInfoScreenHorizontal;
}
-(NSString*)gameCategory
{
    return self[kGameInfoCategory] ?: @"";
}
- (BOOL)gameIsFake
{
    return [@[kGameInfoNameMameMenu, kGameInfoNameSettings] containsObject:self[kGameInfoName]];
}
- (BOOL)gameIsMame
{
    return [self.gameName isEqualToString:kGameInfoNameMameMenu];
}
- (NSString*)gameFile
{
    return self[kGameInfoFile] ?: @"";
}
- (NSString*)gameMediaType
{
    return self[kGameInfoMediaType] ?: @"";
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
    NSString* title = self[kGameInfoDescription] ?: self[kGameInfoName] ?: @"";
    title = [title componentsSeparatedByString:@" ("].firstObject;
    title = [title componentsSeparatedByString:@" ["].firstObject;
    return title;
}
-(NSArray<NSURL*>*)gameImageURLs
{
    NSParameterAssert(self.gameName.length != 0);
    NSParameterAssert(![self.gameName containsString:@" "]);
    NSParameterAssert(![self.gameSystem containsString:@" "]);
    
    if (self.gameIsFake || self.gameIsSnapshot) {
        return @[self.gameLocalImageURL];
    }
    else if (self.gameSoftwareList.length != 0)
    {
        /// MESS style title url
        /// http://adb.arcadeitalia.net/media/mess.current/titles/a2600/adventur.png
        /// http://adb.arcadeitalia.net/media/mess.current/ingames/a2600/pitfall.png
        
        NSString* base = @"http://adb.arcadeitalia.net/media/mess.current";
        NSString* list = self.gameSoftwareList;
        NSString* name = self.gameName.lowercaseString;
        
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
    
    if (self.gameIsFake)
        return [[NSBundle mainBundle] URLForResource:name withExtension:@"png"];
    
#if TARGET_OS_IOS
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#elif TARGET_OS_TV
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    
    if (self.gameIsSnapshot)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, self.gameFile] isDirectory:NO];
    else if (self.gameSoftwareList.length != 0)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/titles/%@/%@.png", path, self.gameSoftwareList, name] isDirectory:NO];
    else if (self.gameIsSoftware)
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.png", path, self.gameFile.stringByDeletingPathExtension] isDirectory:NO];
    else
        return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/titles/%@.png", path, name] isDirectory:NO];
}
-(NSURL*)gamePlayURL
{
    if (self.gameIsSoftware)
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@/%@:%@", self.gameSystem, self.gameMediaType, self.gameFile]];
    else if (self.gameSystem.length != 0)
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@/%@", self.gameSystem, self.gameName]];
    else
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@", self.gameName]];
}
@end
