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
#import "Globals.h" // for getDocumentPath()
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

- (instancetype)init
{
    return [self initWithPath:getDocumentPath(@"")];
}

#pragma mark Public methods

// singleton, uses the document root
+ (instancetype)sharedInstance {
    NSParameterAssert(NSThread.isMainThread);
    static SoftwareList* g_shared;
    if (g_shared == nil)
        g_shared = [[SoftwareList alloc] init];
    return g_shared;
}

// get software list names
- (NSArray*)getSoftwareListNames {
    @synchronized (self) {
        NSArray* list = [software_list_cache objectForKey:@"*"];
        if (list == nil) {
            @autoreleasepool {
                list = [getZipFileNames(hash_zip) valueForKeyPath:@"lastPathComponent.stringByDeletingPathExtension.lowercaseString"];
                [software_list_cache setObject:(list ?: @[]) forKey:@"*"];
            }
        }
        return list; 
    }
}

// get software list description
- (NSString*)getSoftwareListDescription:(NSString*)name {
    return [[self getSoftwareList:name].firstObject valueForKey:kSoftwareListDescription];
}

// get software list, from cache, or load and validate the ROMs
- (NSArray*)getSoftwareList:(NSString*)name {
    NSParameterAssert(name.length != 0 && ![name containsString:@" "] && ![name containsString:@","]);
    @synchronized (self) {
        NSArray* list = [software_list_cache objectForKey:name];
        if (list == nil) {
            @autoreleasepool {
                list = [self loadSoftwareList:name];
                [software_list_cache setObject:(list ?: @[]) forKey:name];
            }
        }
        return list;
    }
}

// get games for a system
- (NSArray<GameInfo*>*)getGamesForSystem:(GameInfo*)system {

    NSString* lists = system.gameSoftwareMedia; // this can be a comma separated list of softlist names and media
    
    NSParameterAssert(![lists containsString:@" "]);
    if (lists.length == 0)
        return @[];
    
    // get a filter keyword
    //
    // NOTE in a perfect world we would get this from the MAME core, but libmame does not currently pass it to us.
    // .....so we figure it out from the description of the system, we only support NTSC and PAL, these are the most used.
    //
    //          Atari 2600 (PAL)
    //          Atari 2600 (NTSC)
    //          Sega CD with 32X (USA, NTSC)
    //          Dreamcast (Japan, NTSC)
    //
    NSString* filter = nil;
    NSString* desc = system.gameDescription;
    if ([desc hasSuffix:@")"] && [desc containsString:@" ("]) {
        desc = [desc componentsSeparatedByString:@" ("].lastObject;

        // TODO: this is not perfect we only look for "PAL" or "NTSC" in the description
        // TODO: other filters are NTSC-U, NTSC-J, NTSC-K, and other non-NTSC/PAL related
        if ([desc containsString:@"NTSC"])
            filter = @"NTSC";
        
        if ([desc containsString:@"PAL"])
            filter = @"PAL";
    }

    NSMutableArray* games = [[NSMutableArray alloc] init];
    
    for (NSString* list_name in [lists componentsSeparatedByString:@","]) {

        // if this is not a plain softlist name, get out quick.
        if ([list_name containsString:@":"])
            continue;;

        for (NSDictionary* software in [self getSoftwareList:list_name]) {
            
            // first entry will have only a description, and we want to skip that
            if (![software isKindOfClass:[NSDictionary class]] || software[kSoftwareListName] == nil)
                continue;
            
            // check for NTSC and PAL compatibility
            //     <sharedfeat name="compatibility" value="NTSC"/>
            //     <sharedfeat name="compatibility" value="PAL"/>
            //     <sharedfeat name="compatibility" value="NTSC,PAL"/>
            //     <sharedfeat name="compatibility" value="NTSC-J,NTSC-K,NTSC-U"/>
            if (filter != nil && [STR([software valueForKeyPath:@"sharedfeat.name"]) isEqualToString:@"compatibility"]) {
                NSString* value = STR([software valueForKeyPath:@"sharedfeat.value"]);
                // skip this software if the filter keyword is not in compatibility list
                if (value.length != 0 && ![value containsString:filter])
                    continue;
            }
            
            // check for TMSS incompatibility (only megadriv.xml)
            //      <sharedfeat name="incompatibility" value="TMSS"/>
            if ([STR([software valueForKeyPath:@"sharedfeat.name"]) isEqualToString:@"incompatibility"]) {
                NSString* value = STR([software valueForKeyPath:@"sharedfeat.value"]);
                if (value.length != 0 && [system.gameDescription containsString:value])
                    continue;
            }
            
            [games addObject:[[GameInfo alloc] initWithDictionary:@{
                kGameInfoSoftwareList:list_name,
                kGameInfoSystem:      system.gameName,
                kGameInfoDriver:      system.gameDriver,
                kGameInfoName:        STR(software[kSoftwareListName]),
                kGameInfoParent:      STR(software[kSoftwareListParent]),
                kGameInfoDescription: STR(software[kSoftwareListDescription]),
                kGameInfoYear:        STR(software[kSoftwareListYear]),
                kGameInfoManufacturer:STR(software[kSoftwareListPublisher]),
             }]];
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
    
    GameInfo* info = [self searchSoftwareList:name name:name files:getZipFileHashes(path)];
    if (info == nil)
        return nil;
    
    return info.gameSoftwareList;
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
    
    NSLog(@"EXTRACT CLONES: %@", path.lastPathComponent);
    
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

// a standalone rom file just got installed, see if we cant find a match in the software lists
- (BOOL)installSoftware:(NSString*)path {
    
    NSData* data = [NSData dataWithContentsOfFile:path];

    if (data == nil)
        return FALSE;
    
    NSString* hash = sha1(data);
    GameInfo* game = [self searchSoftwareList:[hash substringToIndex:8] name:nil files:[NSSet setWithObject:hash]];
    
    if (game != nil)
    {
        NSLog(@"installSoftware:%@, found: %@ in %@:%@ ", path.lastPathComponent, info.gameDescription, info.gameSoftwareList, info.gameName);
        
        path = [path stringByAppendingPathExtension:@"json"];
        data = [NSJSONSerialization dataWithJSONObject:game.gameDictionary options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:path atomically:NO];
    }
    else
    {
        NSLog(@"installSoftware:%@ NOT found", path.lastPathComponent);
    }
    
    return game != nil;
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
static NSSet<NSString*>* getZipFileHashes(NSString* path) {
    NSMutableSet* hashes = [[NSMutableSet alloc] init];
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
                [software_list_cache setObject:(dict ?: @{}) forKey:key];
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
    NSMutableArray* list = [LIST([dict valueForKeyPath:@"softwarelist.software"]) mutableCopy];
    NSString* soft_dir = [roms_dir stringByAppendingPathComponent:list_name];
    
    // filter list (validate romsets exist)
    [list filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* software, NSDictionary* bindings) {
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
    
    // add the description of the software list itself as the first item.
    NSString* description = STR([dict valueForKeyPath:@"softwarelist.description"]);
    [list insertObject:@{kSoftwareListDescription:description} atIndex:0];
    
#if defined(DEBUG) && DebugLog != 0
    NSLog(@"LOADING SOFTWARE LIST: %@ \"%@\" %d items, %0.3fsec", [dict valueForKeyPath:@"softwarelist.name"], [dict valueForKeyPath:@"softwarelist.description"], (int)list.count, [NSDate timeIntervalSinceReferenceDate] - time);
    for (NSDictionary* software in list)
        NSLog(@"    %@, %@, %@, \"%@\"", software[kSoftwareListName], software[kSoftwareListYear], software[kSoftwareListPublisher], software[kSoftwareListDescription]);
#endif
    
    return [list copy];
}

// get database that maps romset name to possible software lists
- (NSDictionary*)getSoftwareListDatabase {
    NSString* key = @"hash.dat";
    
    @synchronized (self) {
        NSDictionary* dict = [software_list_cache objectForKey:key];
        if (dict == nil) {
            @autoreleasepool {
                dict = [self loadSoftwareListDatabase];
                [software_list_cache setObject:(dict ?: @{}) forKey:key];
            }
        }
        return dict;
    }
}

#define HASH_DB_VERSION 42
#define HASH_DB_VERSION_KEY @"hash_db_version"

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

        if ([dict isKindOfClass:[NSDictionary class]] && [dict[HASH_DB_VERSION_KEY] isEqual:@(HASH_DB_VERSION)])
            return dict;
    }
    
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
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
            
            // add name of software
            NSString* name = STR(software[kSoftwareListName]).lowercaseString;
            dict_add_list(soft_list_db, name, list_name);
            
            // add any software that uses a *single* file by hash
            NSSet* files = getSoftwareHashes(software);
            if (files.count == 1)
            {
                NSString* hash = [files.anyObject substringToIndex:8];
                dict_add_list(soft_list_db, hash, list_name);
            }
        }
    }];
    
    // SAVE the database to `HASH.DAT` for next time.
    soft_list_db[HASH_DB_VERSION_KEY] = @(HASH_DB_VERSION);
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:soft_list_db format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSParameterAssert(data != nil);
    [data writeToFile:hash_dat atomically:NO];
    
    time = [NSDate timeIntervalSinceReferenceDate] - time;
#if defined(DEBUG) && DebugLog != 0
//    for (NSString* key in soft_list_db.allKeys)
//        NSLog(@"    %@: %@", key, [LIST(soft_list_db[key]) componentsJoinedByString:@", "]);
    NSLog(@"SoftwareListDatabase: %d items, HASH.DAT size=%d, took %0.3fsec", (int)soft_list_db.allKeys.count, (int)[data length], time);
#endif
    
    return soft_list_db;
}

static void dict_add_list(NSMutableDictionary* dict, NSString* key, NSString* value) {
    id val = dict[key];

    if (val == nil) {
        dict[key] = value;
    }
    else {
        val = LIST(val);
        if (![val containsObject:value])
            dict[key] = [val arrayByAddingObject:value];
    }
}

// get all the hashes of all the files used by this software
static NSSet<NSString*>* getSoftwareHashes(NSDictionary* software)
{
    NSMutableSet* hashes = [[NSMutableSet alloc] init];
    
    for (NSDictionary* part in LIST(software[@"part"])) {
        
        // get all the ROMs
        for (NSDictionary* area in LIST([part valueForKeyPath:@"dataarea"])) {
            for (NSString* hash in LIST([area valueForKeyPath:@"rom.sha1"])) {
                if ([hash isKindOfClass:[NSString class]] && hash.length != 0)
                    [hashes addObject:hash];
            }
        }
        
        // get all the DISKs
        for (NSDictionary* area in LIST([part valueForKeyPath:@"diskarea"])) {
            for (NSString* hash in LIST([area valueForKeyPath:@"disk.sha1"])) {
                if ([hash isKindOfClass:[NSString class]] && hash.length != 0)
                    [hashes addObject:hash];
            }
        }
    }
    return [hashes copy];
}

// search software lists looking for software with a set of files (passed as hashes)
// the first match is returned
//
// FYI not *all* software lists are searched, only the ones in HASH.DAT under the passed key
// if name != nil then all software in a given list will be tested, else only ones matching name
//
- (nullable GameInfo*)searchSoftwareList:(NSString*)search_key name:(nullable NSString*)name files:(NSSet<NSString*>*)files {

    if (search_key == nil || files.count == 0)
        return nil;
    
    // get subset of software lists to search
    NSDictionary* soft_list_db = [self getSoftwareListDatabase];
    NSArray* list_names = LIST(soft_list_db[search_key]);
    if (list_names.count == 0)
        return nil;

    NSLog(@"SEARCHING SOFTWARE LISTS(%@) FOR: %@", [list_names componentsJoinedByString:@", "], name ?: search_key);

    for (NSString* list_name in list_names) @autoreleasepool {
        
        NSLog(@"    SEARCHING LIST(%@) FOR: %@", list_name, name ?: search_key);

        NSDictionary* dict = [self getSoftwareListXML:list_name];

        // walk all software in this list looking for match
        for (NSDictionary* software in LIST([dict valueForKeyPath:@"softwarelist.software"])) {
            
            if (![software isKindOfClass:[NSDictionary class]])
                continue;
            
            NSString* soft_name = STR(software[kSoftwareListName]).lowercaseString;
            
            // check this software only if the name matches
            if (name.length != 0 && ![name isEqualToString:soft_name])
                continue;
            
            NSSet* soft_files = getSoftwareHashes(software);
            
            if ([soft_files isSubsetOfSet:files]) {
                NSLog(@"    FOUND %@ in LIST: %@:%@", name ?: search_key, list_name, soft_name);
                return [[GameInfo alloc] initWithDictionary:@{
                    kGameInfoSoftwareList:list_name,
                    kGameInfoName:        STR(software[kSoftwareListName]),
                    kGameInfoParent:      STR(software[kSoftwareListParent]),
                    kGameInfoDescription: STR(software[kSoftwareListDescription]),
                    kGameInfoYear:        STR(software[kSoftwareListYear]),
                    kGameInfoManufacturer:STR(software[kSoftwareListPublisher]),
                 }];
            }
        }
    }
    
    NSLog(@"DID NOT FIND %@ in *any* SOFTWARE LIST", name ?: search_key);
    return nil;
}

@end
