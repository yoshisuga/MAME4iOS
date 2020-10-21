//
//  CloudSync.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//
// TODO: need to handle iCloud retry errors
//       https://developer.apple.com/documentation/cloudkit/ckerrorretryafterkey
//
// Files are stored in the CloudKit private database in the `MameFile` recordType (aka table)
//
//      MameFile schema
//      +-----------+---------+
//      |recordID   |String   |     system recordID, must match name
//      |createdAt  |Date     |     system creationDate
//      |modifiedAt |Date     |     system modificationDate
//      +-----------+---------+
//      |name       |String   |     name of the ROM or file, ie "roms/pacman.zip"
//      |data       |Asset    |     CKAsset (aka BLOB) holding the file contents
//      +-----------+---------+
//
//      **NOTE** the reason recordID == name, instead of just recordID and no name, is that CloudKit
//      just-in-time-schema will automaticly add QUERYABLE, SORTABLE, and INDEXABLE to name for us
//      but not for recordID. This way the code will run without *needing* a visit to the Dashboard.
//

#import "CloudSync.h"
#import <CloudKit/CloudKit.h>
#import "EmulatorController.h"
#import "Alert.h"

#define DebugLog 1
#if DebugLog == 0 || DEBUG == 0
#define NSLog(...) (void)0
#endif

// Schema
#define kRecordType     @"MameFile"
#define kRecordName     @"name"         // recordID.recordName *must* be equal to kRecordName
#define kRecordData     @"data"

// name of an initial record we create for just-in-time-schema
#define kTestRecordName @"Wombat.test"

@implementation CloudSync

static CloudSyncStatus _status;
static CKContainer*    _container;
static CKDatabase*     _database;

// MARK: LOAD

+(void)load {
    [self updateCloudStatus];
}

// MARK: STATUS

+(CloudSyncStatus)status {
    return _status;
}

+(void)updateCloudStatus {
    
    if (_container == nil) {
        assert([NSBundle.mainBundle.bundleIdentifier componentsSeparatedByString:@"."].count == 3);
        NSString* identifier = [NSString stringWithFormat:@"iCloud.%@", NSBundle.mainBundle.bundleIdentifier];
        @try {
            // **NOTE** CKContainer.defaultContainer will throw a uncatchable exception, dont use it.
            //_container = CKContainer.defaultContainer;
            _container = [CKContainer containerWithIdentifier:identifier];
        }
        @catch (id exception) {
            NSLog(@"CLOUD STATUS: %@", exception);
        }
        if (_container == nil) {
            NSLog(@"CLOUD STATUS: NO ENTITLEMENT");
            _status = CloudSyncStatusNotEntitled;
            return;
        }
        _database = _container.privateCloudDatabase;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateCloudStatus) name:CKAccountChangedNotification object:nil];
    }
    
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError* error) {
        
        if (error != nil) {
            NSLog(@"CLOUD STATUS: %@", error);
            [self handleError:error];
        }
        
        switch (accountStatus) {
            case CKAccountStatusAvailable:
                NSLog(@"CLOUD STATUS: Available");
                _status = CloudSyncStatusAvailable;
                break;
            case CKAccountStatusRestricted:
                NSLog(@"CLOUD STATUS: Restricted");
                _status = CloudSyncStatusRestricted;
                break;
            case CKAccountStatusNoAccount:
                NSLog(@"CLOUD STATUS: NoAccount");
                _status = CloudSyncStatusNoAccount;
                break;
            default: // CKAccountStatusCouldNotDetermine
                NSLog(@"CLOUD STATUS: CouldNotDetermine");
                _status = CloudSyncStatusError;
                break;
        }

        // if CloudKit is avail, try to read a record to see if anyone is home.
        if (_status == CloudSyncStatusAvailable) {
            _status = CloudSyncStatusUnknown;
            [self query:kRecordType predicate:[NSPredicate predicateWithFormat:@"%K != ''", kRecordName] sort:nil keys:@[] limit:2 handler:^(NSArray* records, NSError* error) {
                if (error != nil) {
                    NSLog(@"CLOUD STATUS ERROR: %@", error);
                    _status = CloudSyncStatusError;

                    // if the type does not exist, go create it
                    if ([error.domain isEqualToString:CKErrorDomain] && error.code == CKErrorUnknownItem)
                        [self createTestRecord];
                }
                else if (records.count <= 1) {
                    NSLog(@"CLOUD STATUS: EMPTY");
                    _status = CloudSyncStatusEmpty;
                }
                else {
                    NSLog(@"CLOUD STATUS: NOT EMPTY");
                    _status = CloudSyncStatusAvailable;
                }
            }];
        }
    }];
}

// Create a initial CKRecord so just-in-time-schema kicks in.
// https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/CreatingaSchemabySavingRecords/CreatingaSchemabySavingRecords.html
//
+ (void)createTestRecord {
    static int create_flag = 0;
    NSLog(@"CLOUD STATUS: CREATE TEST RECORD");
    
    // only try this once....
    if (create_flag++ != 0)
        return;
    
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:kTestRecordName];
    [NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:nil];
    
    // make a test record with empty data
    CKRecord* record = [[CKRecord alloc] initWithRecordType:kRecordType recordID:[[CKRecordID alloc] initWithRecordName:kTestRecordName]];
    record[kRecordName] = kTestRecordName;
    record[kRecordData] = [[CKAsset alloc] initWithFileURL:[NSURL fileURLWithPath:path]];

    [_database saveRecord:record completionHandler:^(CKRecord* record, NSError* error) {
        if (error != nil)
            [self handleError:error];
        else
            [self updateCloudStatus];
    }];
}

// MARK: QUERY

+(void)runQuery:(CKQueryOperation*)op
           keys:(NSArray<CKRecordFieldKey>*)desiredKeys
          limit:(NSUInteger)resultsLimit
        records:(NSMutableArray<CKRecord*>*)records
    handler:(void (^)(NSArray<CKRecord*>* records, NSError* error))handler {
    
    records = records ?: [[NSMutableArray alloc] init];
    
    op.qualityOfService = NSQualityOfServiceUserInitiated;
    op.desiredKeys = desiredKeys;
    
    if (resultsLimit != 0)
        op.resultsLimit = resultsLimit;
    
    op.recordFetchedBlock = ^(CKRecord* record) {
        [records addObject:record];
    };
    
    op.queryCompletionBlock = ^(CKQueryCursor* cursor, NSError* error) {
        if (error != nil) {
            NSLog(@"CLOUD QUERY ERROR: %@", error);
            // TODO: handle retry
            [self handleError:error];
            handler(nil, error);
        }
        else if (cursor != nil && (resultsLimit == 0 || records.count < resultsLimit)) {
            NSLog(@"CLOUD CURSOR: %@", cursor);
            CKQueryOperation* op = [[CKQueryOperation alloc] initWithCursor:cursor];
            [self runQuery:op keys:desiredKeys limit:resultsLimit records:records handler:handler];
        }
        else {
            handler(records, nil);
        }
    };
    
    [_database addOperation:op];
}

+(void)query:(CKRecordType)recordType
   predicate:(NSPredicate*)predicate
        sort:(NSSortDescriptor*)sortDescriptor
        keys:(NSArray<CKRecordFieldKey>*)desiredKeys
       limit:(NSUInteger)resultsLimit
     handler:(void (^)(NSArray<CKRecord*>* records, NSError* error))handler {
    
    CKQuery* query = [[CKQuery alloc] initWithRecordType:recordType predicate:predicate ?: [NSPredicate predicateWithValue:TRUE]];
    if (sortDescriptor != nil)
        query.sortDescriptors = @[sortDescriptor];
    CKQueryOperation* op = [[CKQueryOperation alloc] initWithQuery:query];
    [self runQuery:op keys:desiredKeys limit:resultsLimit records:nil handler:handler];
}

// MARK: SYNC UI

static int inSync = 0;
static UIAlertController *progressAlert = nil;

+(BOOL)startSync:(NSString*)title block:(dispatch_block_t)block {
    assert(NSThread.isMainThread);
    assert(_container != nil && _database != nil);
    assert(inSync == 0);
    if (inSync != 0)
        return FALSE;
    inSync = 1;

    EmulatorController* emuController = EmulatorController.sharedInstance;

    progressAlert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [progressAlert setProgress:0.0 text:@""];
    [progressAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        inSync = -1;
    }]];
    [emuController.topViewController presentViewController:progressAlert animated:YES completion:nil];
    
    if (block != nil)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
    
    return TRUE;
}

+(BOOL)cancelSync {
    return inSync == -1;
}

+(void)updateSync:(double)progress text:(NSString*)text {
    [progressAlert setProgress:progress text:text];
}

+(void)stopSync {
    assert(inSync != 0);
    dispatch_async(dispatch_get_main_queue(), ^{
        EmulatorController* emuController = EmulatorController.sharedInstance;
        
        if (inSync == -1) {
            NSLog(@"STOP SYNC CANCEL");
            // reload the MAME menu, now
            [emuController reload];
        }
        else {
            [progressAlert setProgress:1.0];
            [progressAlert.presentingViewController dismissViewControllerAnimated:YES completion:^{
                // reload the MAME menu, after the alert is down
                [emuController reload];
            }];
        }
        inSync = 0;
        progressAlert = nil;
    });
}

// show error to the user, then call stopSync
+(void)stopSync:(NSError*)error {
    if (error == nil || inSync == -1)
        return [self stopSync];

    NSLog(@"STOP SYNC ERROR: %@", error);

    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO: dont show raw error details to the user in all cases, error.localizedDescription can be ugly
        // TODO: ...for example might want to show a custom error when we are out of local disk space
        [progressAlert showAlertWithTitle:@"iCloud Sync Error" message:error.localizedDescription buttons:@[@"Ok"] handler:^(NSUInteger button) {
            [self stopSync];
        }];
    });
}

// MARK: ERROR HANDLING

+ (void)handleError:(NSError*)error error:(dispatch_block_t)error_block retry:(dispatch_block_t)retry_block {
    assert(error != nil);
    NSLog(@"ERROR: %@", error);
    // TODO: handle a retry error
    if (retry_block != nil && /*should retry*/FALSE)
        retry_block();
    else if (error_block != nil)
        error_block();
}

+ (void)handleError:(NSError*)error {
    return [self handleError:error error:nil retry:nil];
}
+ (void)handleError:(NSError*)error retry:(dispatch_block_t)retry_block {
    return [self handleError:error error:nil retry:retry_block];
}
+ (void)handleSyncError:(NSError*)error retry:(dispatch_block_t)retry_block {
    return [self handleError:error error:^{[self stopSync:error];} retry:retry_block];
}
+ (void)handleSyncError:(NSError*)error {
    return [self handleError:error error:^{[self stopSync:error];} retry:nil];
}

// MARK: IMPORT and EXPORT

// get list of ROMs in the cloud
+(NSArray*)getCloudFiles {
    assert(!NSThread.isMainThread);
    NSMutableArray* records = [[NSMutableArray alloc] init];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    // we use "name != ''" instead of TRUEPREDICATE because TRUEPREDICATE requires recordName to be initialized in the Dashboard as QUERYABLE, we want to not require the Dashboard to run.
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K != ''", kRecordName];
    [self query:kRecordType predicate:predicate sort:nil keys:@[] limit:0 handler:^(NSArray* _records, NSError* error) {
        if (error != nil)
            [self handleError:error];
        [records addObjectsFromArray:_records ?: @[]];
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // sort records by modifed date, so we get the most recently updated files first
    // in case the device runs out of space the most recent ROMs will get copied first.
    return [records sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:FALSE]]];
}

// compare local file on device to file in iCloud.
//
// if no file exists on device ==> NSOrderedAscending
//
// if the file is a ZIP file it is considered `equal` because we dont want to download
// a large ROM multiple times, but we do want to re-copy high scores, settigns, game states.
//
//      NSOrderedAscending.  The file on device is older than the cloud.
//      NSOrderedDescending. The file on device is newer than the cloud.
//      NSOrderedSame.       The files are equal.
//
+(NSComparisonResult)compareCloudFile:(CKRecord*)record {
    NSString* file = record.recordID.recordName;
    NSString* path = [NSString stringWithUTF8String:get_documents_path(file.UTF8String)];
    
    // ignore test record
    if ([file isEqualToString:kTestRecordName])
        return NSOrderedDescending;
    
    // no file on device, cloud is greater
    if (![NSFileManager.defaultManager fileExistsAtPath:path])
        return NSOrderedSame;
    
    // dont re-copy ZIP files.
    // TODO: should this only apply to the ROMs directory?
    if ([file.pathExtension.uppercaseString isEqualToString:@"ZIP"])
        return NSOrderedSame;
    
    NSDate* date = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil].fileModificationDate;
    if (date == nil || record.modificationDate == nil)
        return NSOrderedSame;
    
    return [date compare:record.modificationDate];
}

// MARK: IMPORT

+(void)import {
    NSLog(@"CLOUD IMPORT");
    [self startSync:@"iCloud Import" block:^{
        
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [self getImportFiles:cloud];
        
        [self import:files index:0];
    }];
}

+(void)import:(NSArray*)files index:(NSUInteger)index {
    
    if (index >= files.count || [self cancelSync])
        return [self stopSync];
    
    NSString* file = [files objectAtIndex:index];
    
    if ([file isEqualToString:@"*"])
        return [self export:files index:(index+1)];
    
    [self updateSync:((double)index / files.count) text:file];
    
    [_database fetchRecordWithID:[[CKRecordID alloc] initWithRecordName:file] completionHandler:^(CKRecord* record, NSError* error) {
        
        if (error != nil) {
            [self handleSyncError:error retry:^{
                [self import:files index:index];
            }];
            return;
        }

        NSString* path = [NSString stringWithUTF8String:get_documents_path(file.UTF8String)];
        CKAsset* asset = record[kRecordData];
        
        if (![asset isKindOfClass:[CKAsset class]] || asset.fileURL == nil) {
            error = [NSError errorWithDomain:CKErrorDomain code:CKErrorAssetFileNotFound userInfo:nil];
            return [self handleSyncError:error];
        }

        // remove any local file and overwrite
        if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
        }

        [NSFileManager.defaultManager copyItemAtPath:asset.fileURL.path toPath:path error:&error];
        if (error != nil) {
            error = nil;
            // error copying file, create directory and try again
            [NSFileManager.defaultManager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:&error];
            if (error == nil)
                [NSFileManager.defaultManager copyItemAtPath:asset.fileURL.path toPath:path error:&error];
            if (error != nil) {
                return [self handleSyncError:error];
            }
        }
        
        // set the local file modification date to match the server.
        NSDate* date = record.modificationDate;
        if (date != nil)
            [NSFileManager.defaultManager setAttributes:@{NSFileModificationDate:date} ofItemAtPath:path error:nil];
        
        [self import:files index:(index+1)];
    }];
}

+(NSArray*)getImportFiles:(NSArray*)cloud {
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    for (CKRecord* record in cloud) {
        if ([self compareCloudFile:record] == NSOrderedAscending)
            [files addObject:record.recordID.recordName];
    }
    return files;
}

// MARK: EXPORT

+(void)export {
    NSLog(@"CLOUD EXPORT");
    
    [self startSync:@"iCloud Export" block:^{
        
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [self getExportFiles:cloud];
        
        [self export:files index:0];
    }];
}

+(void)export:(NSArray*)files index:(NSUInteger)index {
    
    if (_status == CloudSyncStatusEmpty && index != 0)
        _status = CloudSyncStatusAvailable;

    if (index >= files.count || [self cancelSync])
        return [self stopSync];
    
    NSString* file = [files objectAtIndex:index];

    if ([file isEqualToString:@"*"])
        return [self import:files index:(index+1)];

    [self updateSync:((double)index / files.count) text:file];
    
    NSString* path = [NSString stringWithUTF8String:get_documents_path(file.UTF8String)];
    assert([NSFileManager.defaultManager fileExistsAtPath:path]);

    // make new record with file data, recordID.recordName *must* be equal to kRecordName
    CKRecord* record = [[CKRecord alloc] initWithRecordType:kRecordType recordID:[[CKRecordID alloc] initWithRecordName:file]];
    record[kRecordName] = file;
    record[kRecordData] = [[CKAsset alloc] initWithFileURL:[NSURL fileURLWithPath:path]];

    [self saveRecord:record completionHandler:^(CKRecord* record, NSError* error) {

        if (error != nil) {
            [self handleSyncError:error retry:^{
                [self export:files index:index];
            }];
            return;
        }
        
        // set the local file modification date to match the server.
        NSDate* date = record.modificationDate;
        if (date != nil)
            [NSFileManager.defaultManager setAttributes:@{NSFileModificationDate:date} ofItemAtPath:path error:nil];
        
        [self export:files index:index+1];
    }];
}

+(NSArray*)getExportFiles:(NSArray*)cloud {
    NSMutableArray* files = [[EmulatorController getROMS] mutableCopy];

    for (CKRecord* record in cloud) {
        if ([self compareCloudFile:record] != NSOrderedDescending)
            [files removeObject:record.recordID.recordName];
    }

    return files;
}

// MARK: SAVE RECORD

// a version of saveRecord that will overwrite the copy on the server.
+ (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord* record, NSError* error))completionHandler {
    CKModifyRecordsOperation* op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
    op.savePolicy = CKRecordSaveAllKeys;
    op.modifyRecordsCompletionBlock = ^(NSArray* saved, NSArray* deleted, NSError* error) {
        completionHandler(saved.firstObject, error);
    };
    [_database addOperation:op];
}

// MARK: SYNC

// sync is just a export and import at the same time.
+(void)sync {
    NSLog(@"CLOUD SYNC");
    [self startSync:@"iCloud Sync" block:^{
        NSArray* cloud = [self getCloudFiles];
        
        // build a list with <export files> * <import files>
        NSArray* files = [self getExportFiles:cloud];
        files = [files arrayByAddingObject:@"*"];
        files = [files arrayByAddingObjectsFromArray:[self getImportFiles:cloud]];
        
        [self export:files index:0];
    }];
}

// MARK: DELETE

// "I say we take off and nuke the entire site from orbit. It's the only way to be sure."
+(void)delete {
    NSLog(@"CLOUD DELETE");
    [self startSync:@"iCloud Erase" block:^{
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [cloud valueForKeyPath:@"@unionOfObjects.recordID.recordName"];
        [self delete:files index:0];
    }];
}

+(void)delete:(NSArray*)files index:(NSUInteger)index {
    
    if (_status == CloudSyncStatusAvailable && index == files.count)
        _status = CloudSyncStatusEmpty;

    if (index >= files.count || [self cancelSync])
        return [self stopSync];
    
    NSString* file = [files objectAtIndex:index];

    [self updateSync:((double)index / files.count) text:file];
    
    [_database deleteRecordWithID:[[CKRecordID alloc] initWithRecordName:file] completionHandler:^(CKRecordID* recordID, NSError* error) {
        
        if (error != nil) {
            [self handleSyncError:error retry:^{
                [self delete:files index:index];
            }];
            return;
        }
        
        [self delete:files index:index+1];
    }];
}

@end
