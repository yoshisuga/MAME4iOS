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
#import <CommonCrypto/CommonDigest.h>

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

// SAFE access to values in XML files
#define STR(x)  ({id s = x; [s isKindOfClass:[NSString class]] ? (NSString*)(s) : @"";})
#define DICT(x) ({id d = x; [d isKindOfClass:[NSDictionary class]] ? (NSDictionary*)(d) : @{};})
#define LIST(x) ({id a = x; [a isKindOfClass:[NSArray class]] ? (NSArray*)(a) : (a ? @[a] : @[]);})

#define ZIP_FILE_TYPES    @[@"zip", @"7z"]

@interface SoftwareList (Private)

@end

@implementation SoftwareList
{
    NSString* hash_zip;
    NSString* roms_dir;
    NSCache*  software_list_cache;
}

#pragma mark init

- (instancetype)initWithPath:(NSString*)root
{
    self = [super init];
    hash_zip = [root stringByAppendingPathComponent:@"hash.zip"];
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
                list = [getZipFileNames(hash_zip) valueForKeyPath:@"lastPathComponent.stringByDeletingPathExtension.lowercaseString"];
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

// get games for a system
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSDictionary*)system {

    NSString* lists = system.gameSoftware; // this can be a comma separated list of softlist names
    
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

// get name of software list for a romset, this is used at install time.
//
// this is to solve the "pacman problem", there is a pacman.zip for almost every system
// given a zip file we need to find out what software list directory to copy it to, and this
// involves searching *all* the software list XMLs looking for a match. we do some cacheing/etc
// to make this not terribly slow, but we still need to search
//
// we use a cached pre-computed database to find the possible software list names to search
//
- (nullable NSString*)getSoftwareListNameForRomset:(NSString*)path named:(NSString*)name {
    
    if (name.length == 0)
        name = path.lastPathComponent.stringByDeletingPathExtension.lowercaseString;
    
    // get subset of software lists to search
    NSDictionary* soft_list_db = [self getSoftwareListDatabase];
    NSArray* list_names = LIST(soft_list_db[name]);
    if (list_names.count == 0)
        return nil;

    // get SHA1 of all files in this romset
    NSArray* hashes = getZipFileSHA1(path);
    if (hashes.count == 0)
        return nil;

    NSLog(@"SEARCHING SOFTWARE LISTS(%@) FOR: %@", [list_names componentsJoinedByString:@", "], name);

    // figure out if this zip file is a SOFTWARE romset, by looking for it in *all* the installed software lists
    for (NSString* list_name in list_names) @autoreleasepool {
        
        NSLog(@"    SEARCHING LIST(%@) FOR: %@", list_name, name);

        NSDictionary* dict = [self getSoftwareListXML:list_name];

        // walk all software in this list looking for a name match, then if names match check ROMs and DISKs
        for (NSDictionary* software in LIST([dict valueForKeyPath:@"softwarelist.software"])) {
            
            if (![software isKindOfClass:[NSDictionary class]])
                continue;

            // check this software if the name matches
            if ([name isEqualToString:STR(software[kSoftwareListName]).lowercaseString]) {
                NSLog(@"        FOUND IN %@.%@ (checking ROMs)", list_name, STR(software[kSoftwareListName]));

                // now make sure all the roms (and disks) for this software are in this ZIP.
                int rom_count = 0;
                int zip_count = 0;
                for (NSDictionary* part in LIST(software[@"part"])) {
                    
                    // look at all the ROMs and see if they are in the ZIP
                    for (NSDictionary* area in LIST([part valueForKeyPath:@"dataarea"])) {
                        for (NSString* hash in LIST([area valueForKeyPath:@"rom.sha1"])) {
                            if (![hash isKindOfClass:[NSString class]] || hash.length == 0)
                                continue;
                            NSLog(@"            ROM:%@ %@", hash, [hashes containsObject:hash.lowercaseString] ? @"FOUND" : @"**NOT** FOUND");
                            rom_count++;
                            if ([hashes containsObject:hash.lowercaseString])
                                zip_count++;
                        }
                    }
                    
                    // look at all the DISKs and see if they are in the ZIP
                    for (NSDictionary* area in LIST([part valueForKeyPath:@"diskarea"])) {
                        for (NSString* hash in LIST([area valueForKeyPath:@"disk.sha1"])) {
                            if (![hash isKindOfClass:[NSString class]] || hash.length == 0)
                                continue;
                            NSLog(@"           DISK:%@ %@", hash, [hashes containsObject:hash.lowercaseString] ? @"FOUND" : @"**NOT** FOUND");
                            rom_count++;
                            if ([hashes containsObject:hash.lowercaseString])
                                zip_count++;
                        }
                    }
                }
                
                if (rom_count != 0 && rom_count == zip_count) {
                    NSLog(@"FOUND %@ in LIST: %@", name, list_name);
                    return list_name;
                }
            }
        }
    }
    
    NSLog(@"DID NOT FIND %@ in *any* SOFTWARE LIST", name);
    return nil;
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
    NSSet* clones = [NSSet setWithArray:[getZipFileNames(path) valueForKeyPath:@"stringByDeletingLastPathComponent.lowercaseString"]];
    
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

#pragma mark Private methods

// get the names of all files in a ZIP, excluding hidden files and directories.
static NSArray<NSString*>* getZipFileNames(NSString* path) {
    NSMutableArray* files = [[NSMutableArray alloc] init];
    [ZipFile enumerate:path withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        [files addObject:info.name];
    }];
    return [files copy];
}

static NSString* sha1(NSData* data) {
    if (data.length == 0)
        return @"";
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    return [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12],digest[13], digest[14], digest[15],
            digest[16],digest[17], digest[18], digest[19]];
}

// get the SHA1 of all files in a ZIP, excluding hidden files and directories.
// TODO: this does not work for 7z files
static NSArray<NSString*>* getZipFileSHA1(NSString* path) {
    NSMutableArray* hashes = [[NSMutableArray alloc] init];
    [ZipFile enumerate:path withOptions:(ZipFileEnumFiles | ZipFileEnumLoadData) usingBlock:^(ZipFileInfo* info) {
        [hashes addObject:sha1(info.data)];
    }];
    return [hashes copy];
}

// load software list xml file, but check cache first
- (NSDictionary*)getSoftwareListXML:(NSString*)name {
    NSParameterAssert(name.length != 0);
    NSString* key = [name stringByAppendingPathExtension:@"xml"];   // use swlist.xml as key to not conflict with getSoftwareList
    
    @synchronized (self) {
        NSDictionary* dict = [software_list_cache objectForKey:key];
        if (dict == nil) {
            @autoreleasepool {
                dict = [self loadSoftwareListXML:name];
                [software_list_cache setObject:dict forKey:key];
            }
        }
        return dict;
    }
}

// load software list xml file
// NOTE all the software lists are inside `hash.zip` (not as separate files)
- (NSDictionary*)loadSoftwareListXML:(NSString*)name {
    
    __block NSDictionary* dict = nil;
    [ZipFile enumerate:hash_zip withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        
        if (dict != nil)
            return;
        
        if (![info.name.pathExtension.lowercaseString isEqualToString:@"xml"])
            return;
        
        if (![info.name.lastPathComponent.stringByDeletingPathExtension.lowercaseString isEqualToString:name.lowercaseString])
            return;

        if (info.data == nil)
            return;
        
        dict = [XmlFile dictionaryWithData:info.data error:nil];
    }];

    return dict;
}

// load software list, and validate the ROMs (ie filter software list down to only Available software)
- (NSArray*)loadSoftwareList:(NSString*)list_name {
    NSParameterAssert(list_name.length != 0);
    
#if defined(DEBUG) && DebugLog != 0
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
#endif

    // load the XML file, NOTE we dont need to use cached XML because our result gets cached.
    NSDictionary* dict = [self loadSoftwareListXML:list_name];
    
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
    
#if defined(DEBUG) && DebugLog != 0
    NSLog(@"LOADING SOFTWARE LIST: %@ \"%@\" %d items, %0.3fsec", [dict valueForKeyPath:@"softwarelist.name"], [dict valueForKeyPath:@"softwarelist.description"], (int)list.count, [NSDate timeIntervalSinceReferenceDate] - time);
    for (NSDictionary* software in list)
        NSLog(@"    %@, %@, %@, \"%@\"", software[kSoftwareListName], software[kSoftwareListYear], software[kSoftwareListPublisher], software[kSoftwareListDescription]);
#endif
    
    return list;
}

// get database that maps romset name to possible software lists
- (NSDictionary*)getSoftwareListDatabase {
    NSString* key = @"hash.dat";
    
    @synchronized (self) {
        NSDictionary* dict = [software_list_cache objectForKey:key];
        if (dict == nil) {
            @autoreleasepool {
                dict = [self loadSoftwareListDatabase];
                [software_list_cache setObject:dict forKey:key];
            }
        }
        return dict;
    }
}

// load/create software list database
- (NSDictionary*)loadSoftwareListDatabase {
    
    NSString* hash_dat = [hash_zip.stringByDeletingPathExtension stringByAppendingPathExtension:@"dat"];
    
    NSDate* zip_date = [[NSFileManager.defaultManager attributesOfItemAtPath:hash_zip error:nil] fileModificationDate];
    NSDate* dat_date = [[NSFileManager.defaultManager attributesOfItemAtPath:hash_dat error:nil] fileModificationDate] ?: NSDate.distantPast;
    
    // load `HASH.DAT` if it is not older than `HASH.ZIP` otherwise build it.
    if ([zip_date compare:dat_date] != NSOrderedDescending) {
        NSData* data = [NSData dataWithContentsOfFile:hash_dat] ?: [[NSData alloc] init];
        NSDictionary* dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:nil];
        NSParameterAssert([dict isKindOfClass:[NSDictionary class]]);

        if ([dict isKindOfClass:[NSDictionary class]])
            return dict;
    }
    
    NSMutableDictionary* soft_list_db = [[NSMutableDictionary alloc] init];
    
    // walk *all* of the software lists and build up database
    [ZipFile enumerate:hash_zip withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        
        if (![info.name.pathExtension.lowercaseString isEqualToString:@"xml"] || info.data == nil)
            return;

        NSDictionary* dict = [XmlFile dictionaryWithData:info.data error:nil];
        
        NSString* list_name = info.name.lastPathComponent.stringByDeletingPathExtension.lowercaseString;

        // walk all software in this list and add to master db
        for (NSDictionary* software in LIST([dict valueForKeyPath:@"softwarelist.software"])) {

            if (![software isKindOfClass:[NSDictionary class]] || software[kSoftwareListName] == nil)
                continue;
            
            NSString* name = STR(software[kSoftwareListName]).lowercaseString;
            id val = soft_list_db[name];

            if (val == nil)
                soft_list_db[name] = list_name;
            else
                soft_list_db[name] = [LIST(val) arrayByAddingObject:list_name];
        }
    }];
    
    // SAVE the database to `HASH.DAT` for next time.
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:soft_list_db format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSParameterAssert(data != nil);
    [data writeToFile:hash_dat atomically:NO];
    
#if defined(DEBUG) && DebugLog != 0
    for (NSString* key in soft_list_db.allKeys)
        NSLog(@"    %@: %@", key, [LIST(soft_list_db[key]) componentsJoinedByString:@", "]);
    NSLog(@"SoftwareListDatabase: %d items, HASH.DAT size=%d", (int)soft_list_db.allKeys.count, (int)[data length]);
#endif
    
    return soft_list_db;
}

@end
