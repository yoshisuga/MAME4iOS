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
-(NSString*)gameCategory
{
    return self[kGameInfoCategory] ?: @"";
}
- (BOOL)gameIsFake
{
    return [@[kGameInfoNameMameMenu, kGameInfoNameSettings] containsObject:self[kGameInfoName]];
}
-(NSString*)gameTitle
{
    return [(self[kGameInfoDescription] ?: self[kGameInfoName] ?: @"") componentsSeparatedByString:@" ("].firstObject;
}
-(NSURL*)gameImageURL
{
    if (self.gameSystem.length != 0)
    {
        /// MESS style title url
        /// http://adb.arcadeitalia.net/media/mess.current/titles/a2600/adventur.png
        
        NSString* base = @"http://adb.arcadeitalia.net/media/mess.current/titles";
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@.png", base, self.gameSystem, self.gameName]];
    }
    else
    {
        /// libretro title url
        /// https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles/pacman.png
        
        NSString* name = self.gameDescription;
        NSString* base = @"https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles";
        
        /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
        /// The following characters in titles must be replaced with _ in the corresponding filename: &*/:`<>?\|
        for (NSString* str in @[@"&", @"*", @"/", @":", @"`", @"<", @">", @"?", @"\\", @"|"])
            name = [name stringByReplacingOccurrencesOfString:str withString:@"_"];
        
        name = [name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.png", base, name]];
    }
}
-(NSURL*)gameLocalImageURL
{
    NSString* name = self[kGameInfoName];
    
    if (name == nil)
        return nil;
    
    if (self.gameIsFake)
        return [[NSBundle mainBundle] URLForResource:name withExtension:@"png"];
    
#if TARGET_OS_IOS
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#elif TARGET_OS_TV
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/titles/%@.png", path, name] isDirectory:NO];
}
-(NSURL*)gamePlayURL
{
    if (self.gameSystem.length != 0)
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@/%@", self.gameSystem, self.gameName]];
    else
        return [NSURL URLWithString:[NSString stringWithFormat:@"mame4ios://%@", self.gameName]];
}
@end
