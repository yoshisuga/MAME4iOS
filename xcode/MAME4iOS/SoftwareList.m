//
//  SoftwareList
//
//  Manage the crazy MAME software list XML files for MAME4iOS
//
//  Created by ToddLa on 4/1/21.
//
#import "SoftwareList.h"
#import "XmlFile.h"
#import "ZipFile.h"
#import "GameInfo.h"

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

#define STR(x)      ((NSString*)([x isKindOfClass:[NSString class]]     ? x : @""))
#define DICT(x) ((NSDictionary*)([x isKindOfClass:[NSDictionary class]] ? x : @{}))
#define LIST(x)      ((NSArray*)([x isKindOfClass:[NSArray class]]      ? x : (x ? @[x] : @[])))

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
    @synchronized (self) {
        NSArray* list = [software_list_cache objectForKey:@"*"];
        if (list == nil) {
            @autoreleasepool {
                list = [NSFileManager.defaultManager contentsOfDirectoryAtPath:hash_dir error:nil];
                list = [list valueForKey:@"stringByDeletingPathExtension"];
                [software_list_cache setObject:list forKey:@"*"];
            }
        }
        return list;
    }
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
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSDictionary*)system {

    NSString* lists = system.gameSoftware;
    
    NSParameterAssert(![lists containsString:@" "]);
    if (lists.length == 0)
        return @[];

    NSMutableArray* games = [[NSMutableArray alloc] init];
    
    for (NSString* list in [lists componentsSeparatedByString:@","]) {
        for (NSDictionary* software in [self getSoftwareList:list]) {
            [games addObject:@{
                kGameInfoSoftwareList:list,
                kGameInfoSystem:      system.gameName,
                kGameInfoDriver:      system.gameDriver,
                kGameInfoName:        STR(software[kSoftwareListName]),
                kGameInfoParent:      STR(software[kSoftwareListParent]),
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
 
    @autoreleasepool {
        if ([ZIP_FILE_TYPES containsObject:path.pathExtension.lowercaseString])
            return [self installZIP:path];

        if ([@[@"xml"] containsObject:path.pathExtension.lowercaseString])
            return [self installXML:path];
    }

    return FALSE;
}

// if this a merged romset, extract clones as empty zip files so they show up as Available
//
//  a merged romset will look like this:
//      rom1
//      rom2
//      clone1/rom1
//      clone1/rom2
//      clone2/rom1
//      clone2/rom2
//
- (BOOL)extractClones:(NSString*)path {
    
    NSLog(@"EXTRACT CLONES: %@", path);
    
    // get directory names of all files in this romset
    NSSet* clones = [NSSet setWithArray:[getZipFiles(path) valueForKeyPath:@"stringByDeletingLastPathComponent.lowercaseString"]];
    
    if (clones.count < 2 || ![clones containsObject:@""]) {
        NSLog(@"....NOT A MERGED ROMSET");
        return FALSE;
    }
    for (NSString* clone in clones) {
        
        if (clone.length == 0 || [clone containsString:@"/"])
            continue;
        
        // create a empty zip with the name of the clone.
        NSString* clone_path = [[path.stringByDeletingLastPathComponent stringByAppendingPathComponent:clone] stringByAppendingPathExtension:path.pathExtension];
        
        if (![NSFileManager.defaultManager fileExistsAtPath:clone_path]) {
            NSLog(@"....CREATING CLONE: %@", clone);
            [ZipFile exportTo:clone_path fromItems:@[] withOptions:ZipFileWriteFiles usingBlock:^ZipFileInfo* (id item) {return nil;}];
        }
    }
    return TRUE;
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

// get the names of all files in a ZIP, excluding hidden files and directories.
// TODO: this does not work for 7z files
static NSArray<NSString*>* getZipFiles(NSString* path) {
    NSMutableArray* files = [[NSMutableArray alloc] init];
    [ZipFile enumerate:path withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        [files addObject:info.name];
    }];
    return [files copy];
}

// install a ZIP file
- (BOOL)installZIP:(NSString*)path {

    // if we dont have any software lists, bail
    NSArray* list_names = [self getSoftwareListNames];
    if (list_names.count == 0)
        return FALSE;
    
    // get names of all files in this romset, if empty zip get out.
    NSArray* files = [getZipFiles(path) valueForKeyPath:@"lastPathComponent.lowercaseString"];
    if (files.count == 0)
        return FALSE;

    NSString* name = path.lastPathComponent.stringByDeletingPathExtension.lowercaseString;
    
    // if the ROM had a name like "foobar 1.zip", "foobar (1).zip" use only the first word as the ROM name.
    // this most likley came when a user downloaded the zip and a foobar.zip already existed, MAME ROMs are <=20 char and no spaces.
    NSArray* words = [name componentsSeparatedByString:@" "];
    if (words.count == 2 && [words.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]].intValue != 0)
        name = words.firstObject;
    
    NSLog(@"SEARCHING SOFTWARE LISTS FOR: %@", name);

    // figure out if this zip file is a SOFTWARE romset, buy looking for it in *all*
    // ...the installed software lists, and if it is copy it to the right subdir of `roms`
    for (NSString* list_name in list_names) @autoreleasepool {
        
        NSLog(@"    SEARCHING LIST(%@) FOR: %@", list_name, name);

        NSDictionary* dict = [self loadSoftwareListXML:list_name cache:YES];

        // walk all software in this list looking for a name match, then if names match check names of ROMs
        for (NSDictionary* software in LIST([dict valueForKeyPath:@"softwarelist.software"])) {
            
            if (![software isKindOfClass:[NSDictionary class]])
                continue;

            // check this software if the name or the parent match
            if ([name isEqualToString:STR(software[kSoftwareListName]).lowercaseString] || [name isEqualToString:STR(software[kSoftwareListParent]).lowercaseString]) {
                NSLog(@"        FOUND IN %@.%@ (checking ROMs)", list_name, STR(software[kSoftwareListName]));

                // now make sure the roms for this software are in this ZIP.
                BOOL found_all_roms = TRUE;
                for (NSDictionary* part in LIST(software[@"part"])) {
                    for (NSDictionary* area in LIST([part valueForKeyPath:@"dataarea"])) {
                        for (NSString* name in LIST([area valueForKeyPath:@"rom.name"])) {
                            NSLog(@"            ROM:\"%@\" %@", name, [files containsObject:name.lowercaseString] ? @"FOUND" : @"**NOT** FOUND");
                            if (![files containsObject:name.lowercaseString])
                                found_all_roms = FALSE;
                        }
                    }
                }
                
                if (found_all_roms) {
                    NSLog(@"FOUND %@ in LIST: %@", name, list_name);
                    NSString* dest_path = [[[roms_dir stringByAppendingPathComponent:list_name] stringByAppendingPathComponent:name] stringByAppendingPathExtension:path.pathExtension];
                    
                    // move romset to roms sub directory and overwrite any other file that is there.
                    [NSFileManager.defaultManager removeItemAtPath:dest_path error:nil];
                    [NSFileManager.defaultManager moveItemAtPath:path toPath:dest_path error:nil];
                    
                    [self extractClones:dest_path];
                    return TRUE;
                }
            }
        }
    }
    
    NSLog(@"DID NOT FIND %@ in *any* SOFTWARE LIST", name);
    return FALSE;
}

// load software list xml file (and maybe cache it)
- (NSDictionary*)loadSoftwareListXML:(NSString*)name cache:(BOOL)cache {
    NSParameterAssert(name.length != 0);
    NSString* path = [[hash_dir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"xml"];
    
    @synchronized (self) {
        NSDictionary* dict = [software_list_cache objectForKey:path];
        if (dict == nil) {
            @autoreleasepool {
                dict = [XmlFile dictionaryWithPath:path error:nil];
                if (cache)
                    [software_list_cache setObject:dict forKey:path];
            }
        }
        return dict;
    }
}

// load software list, and validate the ROMs
- (NSArray*)loadSoftwareList:(NSString*)list_name {
    NSParameterAssert(list_name.length != 0);
    
    // load the XML file
    NSDictionary* dict = [self loadSoftwareListXML:list_name cache:FALSE];
    
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
        
        // TODO: just checkin for zip file may not be enough if the Parent and Child ROMs are merged
        // TODO: maybe we should add all Clones if the Parent romset is present?
        NSString* soft_path = [soft_dir stringByAppendingPathComponent:soft_name];
        for (NSString* ext in ZIP_FILE_TYPES) {
            if ([NSFileManager.defaultManager fileExistsAtPath:[soft_path stringByAppendingPathExtension:ext]])
                return TRUE;
        }

        return FALSE;
    }]];

#if defined(DEBUG) && DebugLog != 0
    if (list.count != 0) {
        NSLog(@"LOADING SOFTWARE LIST: %@ \"%@\"", [dict valueForKeyPath:@"softwarelist.name"], [dict valueForKeyPath:@"softwarelist.description"]);
        for (NSDictionary* software in list)
            NSLog(@"    %@, %@, %@, \"%@\"", software[kSoftwareListName], software[kSoftwareListYear], software[kSoftwareListPublisher], software[kSoftwareListDescription]);
    }
#endif
    
    return list;
}


@end
