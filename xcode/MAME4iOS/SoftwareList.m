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

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

#define STR(x)  ([x isKindOfClass:[NSString class]] ? x : @"")
#define DICT(x) ([x isKindOfClass:[NSDictionary class]] ? x : @{})
#define LIST(x) ([x isKindOfClass:[NSArray class]]  ? x : (x ? @[x] : @[]))

#define ZIP_FILE_TYPES    @[@"zip", @"7z"]

@interface SoftwareList (Private)

@end

@implementation SoftwareList
{
    NSString* hash_dir;
    NSString* roms_dir;
    NSCache*  software_list_cache;
}

#pragma mark init

- (instancetype)initWithPath:(NSString*)root
{
    self = [super init];
    hash_dir = [root stringByAppendingPathComponent:@"hash"];
    roms_dir = [root stringByAppendingPathComponent:@"roms"];
    software_list_cache = [[NSCache alloc] init];
    return self;
}

#pragma mark Public methods

// get software list names
- (NSArray*)getSoftwareListNames {
    NSArray* files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:hash_dir error:nil];
    return [files valueForKey:@"stringByDeletingPathExtension"];
}

// get software list, from cache, or load and validate the ROMs
- (NSArray*)getSoftwareList:(NSString*)name {
    NSParameterAssert(name.length != 0 && ![name containsString:@" "] && ![name containsString:@","]);
    @synchronized (self) {
        NSArray* list = [software_list_cache objectForKey:name];
        if (list == nil) {
            @autoreleasepool {
                list = [self loadSoftwareList:name];
                [software_list_cache setObject:list forKey:name];
            }
        }
        return list;
    }
}

// get games for a system list can be a comma separated list of softlist names
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSString*)system fromList:(NSString*)lists {
    NSParameterAssert(![lists containsString:@" "]);
    
    if (lists.length == 0)
        return @[];

    NSMutableArray* games = [[NSMutableArray alloc] init];
    
    for (NSString* list in [lists componentsSeparatedByString:@","]) {
        for (NSDictionary* software in [self getSoftwareList:list]) {
            [games addObject:@{
                //kGameInfoType:        kGameInfoTypeCART,  // TODO: get the right software type?
                kGameInfoSoftwareList:list,
                kGameInfoSystem:      system,
                kGameInfoName:        STR(software[kSoftwareListName]),
                kGameInfoDescription: STR(software[kSoftwareListDescription]),
                kGameInfoYear:        STR(software[kSoftwareListYear]),
                kGameInfoManufacturer:STR(software[kSoftwareListPublisher]),
            }];
        }
    }

    return games;
}

// install a XML or ZIP file
- (BOOL)installFile:(NSString*)path {
    [self reload];
    
    if ([ZIP_FILE_TYPES containsObject:path.pathExtension.lowercaseString])
        return [self installZIP:path];

    if ([@[@"xml"] containsObject:path.pathExtension.lowercaseString]) @autoreleasepool {
        return [self installXML:path];
    }

    return FALSE;
}

// discard any cached data, forcing a re-load from disk. (called after moveROMs does an import)
- (void)reload {
    @synchronized (self) {
        [software_list_cache removeAllObjects];
    }
}

// delete all software
- (void)reset {
    for (NSString* name in [self getSoftwareListNames])  {
        NSString* roms_path = [roms_dir stringByAppendingPathComponent:name];
        [NSFileManager.defaultManager removeItemAtPath:roms_path error:nil];
        NSString* titles_path = [roms_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"../titles/%@", name]];
        [NSFileManager.defaultManager removeItemAtPath:titles_path error:nil];
    }
    [NSFileManager.defaultManager removeItemAtPath:hash_dir error:nil];
    [NSFileManager.defaultManager createDirectoryAtPath:hash_dir withIntermediateDirectories:NO attributes:nil error:nil];
    [self reload];
}

#pragma mark Private methods

// install a XML file
- (BOOL)installXML:(NSString*)path {
    
    // load the XML file
    NSDictionary* dict = [XmlFile dictionaryWithPath:path error:nil];

    NSString* name = STR([dict valueForKeyPath:@"softwarelist.name"]);
    NSString* desc = STR([dict valueForKeyPath:@"softwarelist.description"]);
    NSArray*  list = LIST([dict valueForKeyPath:@"softwarelist.software"]);

    if (name.length == 0 || desc.length == 0 || list.count == 0) {
        NSLog(@"INVALID SOFTWARE LIST: %@", path);
        return nil;
    }
    
    NSLog(@"INSTALL SOFTWARE LIST: %@ \"%@\" (%d items)", name, desc, (int)list.count);
    
    NSString* hash_path = [[hash_dir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"xml"];
    NSString* roms_path = [roms_dir stringByAppendingPathComponent:name];

    // move software list xml to the `hash` directory (overwrite file)
    [NSFileManager.defaultManager removeItemAtPath:hash_path error:nil];
    [NSFileManager.defaultManager moveItemAtPath:path toPath:hash_path error:nil];
    
    // create (if needed) directory to hold software ROMs
    [NSFileManager.defaultManager createDirectoryAtPath:roms_path withIntermediateDirectories:NO attributes:nil error:nil];
    
    return TRUE;
}

// install a ZIP file
- (BOOL)installZIP:(NSString*)path {
    
    // figure out if this zip file is a SOFTWARE romset, buy looking for it in *all*
    // ...the installed software lists, and if it is copy it to the right subdir of `roms`
    
    // The smart import code in `moveROMs` is pretty good at importing software ROMs and putting
    // them in the correct `roms` sub-folder. assuming a software list has been imported.
    // ...so we dont need to do anything special here, maybe later to get the last 10%
    
    return FALSE;
}

// load software list, and validate the ROMs
- (NSArray*)loadSoftwareList:(NSString*)list_name {
    NSParameterAssert(list_name.length != 0);
    
    NSString* path = [[hash_dir stringByAppendingPathComponent:list_name] stringByAppendingPathExtension:@"xml"];

    // load the XML file
    NSDictionary* dict = [XmlFile dictionaryWithPath:path error:nil];
    
    // get all the software in the list
    NSArray* list = LIST([dict valueForKeyPath:@"softwarelist.software"]);
    NSString* soft_dir = [roms_dir stringByAppendingPathComponent:list_name];
    
    // filter list (validate romsets exist)
    list = [list filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* software, NSDictionary* bindings) {
        if (![software isKindOfClass:[NSDictionary class]])
            return FALSE;

        NSString* soft_name = STR(software[kSoftwareListName]);
        
        if (soft_name.length == 0)
            return FALSE;
        
        NSString* soft_path = [soft_dir stringByAppendingPathComponent:soft_name];
        for (NSString* ext in ZIP_FILE_TYPES) {
            if ([NSFileManager.defaultManager fileExistsAtPath:[soft_path stringByAppendingPathExtension:ext]])
                return TRUE;
        }

        return FALSE;
    }]];

#if DebugLog != 0
    if (list.count != 0) {
        NSLog(@"LOADING SOFTWARE LIST: %@ \"%@\"", [dict valueForKeyPath:@"softwarelist.name"], [dict valueForKeyPath:@"softwarelist.description"]);
        for (NSDictionary* software in list)
            NSLog(@"    %@, %@, %@, \"%@\"", software[kSoftwareListName], software[kSoftwareListYear], software[kSoftwareListPublisher], software[kSoftwareListDescription]);
    }
#endif
    
#ifdef DEBUG
    if (list.count == 0 && [list_name isEqualToString:@"a2600"]) {
        list = @[
            @{
                kSoftwareListName:        @"pitfall",
                kSoftwareListDescription: @"Pitfall! - Pitfall Harry's Jungle Adventure",
                kSoftwareListYear:        @"1982",
                kSoftwareListPublisher:   @"Activision",
            },
            @{
                kSoftwareListName:        @"ET",
                kSoftwareListDescription: @"E.T. - The Extra-Terrestrial",
                kSoftwareListYear:        @"1982",
                kSoftwareListPublisher:   @"Atari",
            },
            @{
                kSoftwareListName:        @"ADVENTP",
                kSoftwareListDescription: @"Adventure +",
                kSoftwareListYear:        @"2003",
                kSoftwareListPublisher:   @"Homebrew",
            },
            @{
                kSoftwareListName:        @"COMBAT",
                kSoftwareListDescription: @"Combat - Tank-Plus",
                kSoftwareListYear:        @"1977",
                kSoftwareListPublisher:   @"Atari",
            },
        ];
    }
    if (list.count == 0 && [list_name isEqualToString:@"n64"]) {
        list = @[
            @{
                kSoftwareListName:        @"007GOLDNU",
                kSoftwareListDescription: @"007 - GoldenEye (USA)",
                kSoftwareListYear:        @"1997",
                kSoftwareListPublisher:   @"Nintendo",
            },
            @{
                kSoftwareListName:        @"MARIOKRTJ1",
                kSoftwareListDescription: @"Mario Kart 64 (Japan)",
                kSoftwareListYear:        @"1996",
                kSoftwareListPublisher:   @"Nintendo",
            },
            @{
                kSoftwareListName:        @"ZELDAOOTMQD",
                kSoftwareListDescription: @"The Legend of Zelda - Ocarina of Time - Master Quest (USA, Debug Edition, Ripped from GC)",
                kSoftwareListYear:        @"2003",
                kSoftwareListPublisher:   @"Nintendo",
            },
            @{
                kSoftwareListName:        @"MADDN2K2",
                kSoftwareListDescription: @"Madden NFL 2002 (USA)",
                kSoftwareListYear:        @"2001",
                kSoftwareListPublisher:   @"Electronic Arts",
            },
        ];
    }
#endif
    
    return list;
}


@end
