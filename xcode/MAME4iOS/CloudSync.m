//
//  CloudSync.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "CloudSync.h"
#import <CloudKit/CloudKit.h>
#import "EmulatorController.h"
#import "Alert.h"

#define DebugLog 1
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

#define kRecordType     @"Data"
#define kData           @"data"

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
            // NOTE CKContainer.defaultContainer will throw a uncatchable exception, dont use it.
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
                NSLog(@"CLOUD STATUS: Unknown");
                _status = CloudSyncStatusUnknown;
                break;
        }

        // if CloudKit is avail, try to read a record to see if anyone is home.
        if (_status == CloudSyncStatusAvailable) {
            _status = CloudSyncStatusUnknown;
            [self query:kRecordType predicate:nil keys:@[] limit:10 handler:^(NSArray* records) {
                if (records == nil) {
                    NSLog(@"CLOUD STATUS: Error");
                    _status = CloudSyncStatusError;
                    // TODO: add a test record
                }
                else if (records.count == 0) {
                    NSLog(@"CLOUD STATUS: EMPTY");
                    _status = CloudSyncStatusEmpty;
                }
                else if (records.count == 1) {
                    NSLog(@"CLOUD STATUS: EMPTY (ONE RECORD)");
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

// MARK: QUERY

+(void)runQuery:(CKQueryOperation*)op
           keys:(NSArray<CKRecordFieldKey>*)desiredKeys
          limit:(NSUInteger)resultsLimit
        records:(NSMutableArray<CKRecord*>*)records
    handler:(void (^)(NSArray<CKRecord*>* records))handler {
    
    records = records ?: [[NSMutableArray alloc] init];
    
    op.desiredKeys = desiredKeys;
    
    if (resultsLimit != 0)
        op.resultsLimit = resultsLimit;
    
    op.recordFetchedBlock = ^(CKRecord* record) {
        [records addObject:record];
    };
    
    op.queryCompletionBlock = ^(CKQueryCursor* cursor, NSError* error) {
        if (error != nil) {
            NSLog(@"CLOUD QUERY ERROR: %@", error);
            handler(nil);
        }
        if (cursor != nil && (resultsLimit == 0 || records.count < resultsLimit)) {
            NSLog(@"CLOUD CURSOR: %@", cursor);
            CKQueryOperation* op = [[CKQueryOperation alloc] initWithCursor:cursor];
            [self runQuery:op keys:desiredKeys limit:resultsLimit records:records handler:handler];
         }
        else {
            handler(records);
        }
    };
    
    [_database addOperation:op];
}

+(void)query:(CKRecordType)recordType
   predicate:(NSPredicate*)predicate
        keys:(NSArray<CKRecordFieldKey>*)desiredKeys
       limit:(NSUInteger)resultsLimit
     handler:(void (^)(NSArray<CKRecord*>* records))handler {
    
    CKQuery* query = [[CKQuery alloc] initWithRecordType:recordType predicate:predicate ?: [NSPredicate predicateWithValue:TRUE]];
    CKQueryOperation* op = [[CKQueryOperation alloc] initWithQuery:query];
    [self runQuery:op keys:desiredKeys limit:resultsLimit records:nil handler:handler];
}

// MARK: IMPORT and EXPORT

// get list of ROMs in the cloud
+(NSArray*)getCloudFiles {
    assert(!NSThread.isMainThread);
    NSMutableArray* records = [[NSMutableArray alloc] init];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self query:kRecordType predicate:nil keys:@[] limit:0 handler:^(NSArray* _records) {
        [records addObjectsFromArray:_records];
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return records;
}

static int inSync = 0;
static UIAlertController *progressAlert = nil;

+(BOOL)startSync:(NSString*)title block:(dispatch_block_t)block {
    assert(NSThread.isMainThread);

    EmulatorController* emuController = (EmulatorController*)UIApplication.sharedApplication.keyWindow.rootViewController;
    
    assert([emuController isKindOfClass:[EmulatorController class]]);
    if (![emuController isKindOfClass:[EmulatorController class]])
        return FALSE;
    if (inSync != 0)
        return FALSE;
    inSync = 1;
    
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

+(void)stopSync:(NSError*)error {
    assert(inSync != 0);
    if (inSync == 0)
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            NSLog(@"STOP SYNC ERROR: %@", error);
        }
        if (inSync == -1) {
            NSLog(@"STOP SYNC CANCEL");
        }
        [progressAlert setProgress:1.0];
        [progressAlert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        inSync = 0;
        progressAlert = nil;
    });
}

+(void)stopSync {
    [self stopSync:nil];
}

// MARK: IMPORT

+(void)import:(NSArray*)files index:(NSUInteger)index {
    
    if (index >= files.count || [self cancelSync])
        return [self stopSync];
    
    NSString* file = [files objectAtIndex:index];
    
    if ([file isEqualToString:@"*"])
        return [self export:files index:(index+1)];
    
    [self updateSync:((double)index / files.count) text:file];
    
    NSTimeInterval time = NSDate.timeIntervalSinceReferenceDate;
    [_database fetchRecordWithID:[[CKRecordID alloc] initWithRecordName:file] completionHandler:^(CKRecord* record, NSError* error) {
        NSLog(@"FETCH TOOK: %f", NSDate.timeIntervalSinceReferenceDate - time);
        
        if (error != nil) {
            NSLog(@"FETCH ERROR: %@", error);
            return [self stopSync:error];
        }

        NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
        NSString* path = [rootPath stringByAppendingPathComponent:file];
        CKAsset* asset = record[kData];
        
        if (![asset isKindOfClass:[CKAsset class]] || asset.fileURL == nil) {
            error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
            NSLog(@"FETCH ERROR: %@", error);
            return [self stopSync:error];
        }

        if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
            assert(![path.pathExtension.uppercaseString isEqualToString:@"ZIP"]);
            [NSFileManager.defaultManager removeItemAtPath:path error:&error];
        }

        [NSFileManager.defaultManager copyItemAtPath:asset.fileURL.path toPath:path error:&error];
        if (error != nil) {
            NSLog(@"COPY ERROR: %@", error);
            return [self stopSync:error];
        }
        [self import:files index:(index+1)];
    }];
}

+(NSArray*)getImportFiles:(NSArray*)cloud {
    NSMutableArray* files = [[NSMutableArray alloc] init];
    NSArray* roms = [EmulatorController getROMS];   // local ROMs and files
    
    for (CKRecord* record in cloud) {
        assert([record isKindOfClass:[CKRecord class]]);
        // TODO: compare dates??
        NSString* rom = record.recordID.recordName;
        if (![roms containsObject:rom])
            [files addObject:rom];
    }
    return files;
}

+(void)import {
    NSLog(@"CLOUD IMPORT");
    [self startSync:@"iCloud Import" block:^{
        
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [self getImportFiles:cloud];
        
        [self import:files index:0];
    }];
}

// MARK: EXPORT

+(void)export:(NSArray*)files index:(NSUInteger)index {
    
    if (index >= files.count || [self cancelSync])
        return [self stopSync];
    
    NSString* file = [files objectAtIndex:index];

    if ([file isEqualToString:@"*"])
        return [self import:files index:(index+1)];

    [self updateSync:((double)index / files.count) text:file];
    
    NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
    NSString* path = [rootPath stringByAppendingPathComponent:file];
    assert([NSFileManager.defaultManager fileExistsAtPath:path]);

    CKRecord* record = [[CKRecord alloc] initWithRecordType:kRecordType recordID:[[CKRecordID alloc] initWithRecordName:file]];
    record[kData] = [[CKAsset alloc] initWithFileURL:[NSURL fileURLWithPath:path]];
    
    NSTimeInterval time = NSDate.timeIntervalSinceReferenceDate;
    [_database saveRecord:record completionHandler:^(CKRecord* record, NSError* error) {
        NSLog(@"SAVE RECORD TOOK: %f", NSDate.timeIntervalSinceReferenceDate - time);

        if (error != nil) {
            NSLog(@"SAVE RECORD ERROR: %@", error);
            [self stopSync:error];
        }
        else {
            [self export:files index:index+1];
        }
    }];
}

+(NSArray*)getExportFiles:(NSArray*)cloud {
    NSMutableArray* files = [[EmulatorController getROMS] mutableCopy];

    for (CKRecord* record in cloud) {
        assert([record isKindOfClass:[CKRecord class]]);
        NSString* file = record.recordID.recordName;
        // TODO: compare dates??
        if ([files containsObject:file])
            [files removeObject:file];
    }

    return files;
}

+(void)export {
    NSLog(@"CLOUD EXPORT");
    [self startSync:@"iCloud Export" block:^{
        
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [self getExportFiles:cloud];
        
        [self export:files index:0];
    }];
}

// MARK: SYNC

// currently sync is just a export then import
+(void)sync {
    NSLog(@"CLOUD SYNC");
    [self startSync:@"iCloud Sync" block:^{
        NSArray* cloud = [self getCloudFiles];
        NSArray* files = [self getExportFiles:cloud];
        files = [files arrayByAddingObject:@"*"];
        files = [files arrayByAddingObjectsFromArray:[self getImportFiles:cloud]];
        
        [self export:files index:0];
    }];
}

@end
