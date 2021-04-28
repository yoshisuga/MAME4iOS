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

// return list of installed softlists
- (NSArray<NSString*>*)getListNames {
    return @[];
}

// get full softlist data
- (NSArray<NSDictionary*>*)getList:(NSString*)name {
    return @[];
}

// get installed software list
- (NSArray<NSDictionary*>*)getInstalledList:(NSString*)name {
    return @[];
}

// get games for a system
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSString*)system from:(NSString*)list {
    return @[];
}

// install a XML or ZIP file
- (BOOL)installFile:(NSString*)file {
    return FALSE;
}

// discard any cached data, forcing a re-load from disk.
- (void)flush {
    
}

#pragma mark Private methods


@end
