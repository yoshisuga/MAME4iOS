//
//  SoftwareList
//
//  Manage the crazy MAME software list XML files for MAME4iOS
//
//  Created by ToddLa on 4/1/21.
//
#import "SoftwareList.h"
#import "XmlFile.h"
#import "GameInfo.h"

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

@interface SoftwareList (Private)

@end

@implementation SoftwareList
{
    NSString* hash_dir;
    NSString* roms_dir;
}

#pragma mark init

- (instancetype)initWithPath:(NSString*)root
{
    self = [super init];
    hash_dir = [root stringByAppendingPathComponent:@"hash"];
    roms_dir = [root stringByAppendingPathComponent:@"roms"];
    return self;
}

#pragma mark Public methods

// get full software list
- (NSArray<NSDictionary*>*)getList:(NSString*)name {
    return @[];
}

// get installed software list
- (NSArray<NSDictionary*>*)getInstalledList:(NSString*)name {
    return @[];
}

// get games for a system
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSString*)system fromList:(NSString*)list {
// add some *fake* data for testing....
#ifdef DEBUG
    if ([list isEqualToString:@"a2600"]) {
        return @[
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"pitfall",
                kGameInfoDescription: @"Pitfall! - Pitfall Harry's Jungle Adventure",
                kGameInfoYear:        @"1982",
                kGameInfoManufacturer:@"Activision",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"ET",
                kGameInfoDescription: @"E.T. - The Extra-Terrestrial",
                kGameInfoYear:        @"1982",
                kGameInfoManufacturer:@"Atari",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"ADVENTP",
                kGameInfoDescription: @"Adventure +",
                kGameInfoYear:        @"2003",
                kGameInfoManufacturer:@"Homebrew",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"COMBAT",
                kGameInfoDescription: @"Combat - Tank-Plus",
                kGameInfoYear:        @"1977",
                kGameInfoManufacturer:@"Atari",
            },
        ];
    }
    if ([list isEqualToString:@"n64"]) {
        return @[
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"007GOLDNU",
                kGameInfoDescription: @"007 - GoldenEye (USA)",
                kGameInfoYear:        @"1997",
                kGameInfoManufacturer:@"Nintendo",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"MARIOKRTJ1",
                kGameInfoDescription: @"Mario Kart 64 (Japan)",
                kGameInfoYear:        @"1996",
                kGameInfoManufacturer:@"Nintendo",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"ZELDAOOTMQD",
                kGameInfoDescription: @"The Legend of Zelda - Ocarina of Time - Master Quest (USA, Debug Edition, Ripped from GC)",
                kGameInfoYear:        @"2003",
                kGameInfoManufacturer:@"Nintendo",
            },
            @{
                kGameInfoSystem:      system,
                kGameInfoName:        @"MADDN2K2",
                kGameInfoDescription: @"Madden NFL 2002 (USA)",
                kGameInfoYear:        @"2001",
                kGameInfoManufacturer:@"Electronic Arts",
            },
        ];
    }

#endif
    return @[];
}

// install a XML or ZIP file
- (BOOL)installFile:(NSString*)file {
    
    if ([file.pathExtension.uppercaseString isEqualToString:@"ZIP"] || [file.pathExtension.uppercaseString isEqualToString:@"7Z"])
        return [self installZIP:file];

    if ([file.pathExtension.uppercaseString isEqualToString:@"XML"])
        return [self installXML:file];

    return FALSE;
}

// discard any cached data, forcing a re-load from disk.
- (void)flush:(BOOL)all {

}

#pragma mark Private methods

// install a XML file
- (BOOL)installXML:(NSString*)file {
    return FALSE;
}

// install a ZIP file
- (BOOL)installZIP:(NSString*)file {
    return FALSE;
}

@end
