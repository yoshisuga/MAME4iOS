//
//  CloudSync.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "CloudSync.h"
#import <CloudKit/CloudKit.h>

#define DebugLog 1
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

#define kFileRecordType     @"File"
#define kFileName           @"name"
#define kFileData           @"data"

@implementation CloudSync

static CloudSyncStatus _status;
static CKContainer*    _container;
static CKDatabase*     _database;

// MARK: LOAD

+(void)load {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateCloudStatus) name:CKAccountChangedNotification object:nil];
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
            NSLog(@"CLOUD STATUS: NO ENTITLEMENT: %@", exception);
            _status = CloudSyncStatusNotEntitled;
            return;
        }
    }
    
    [_container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError* error) {
        
        if (error != nil) {
            NSLog(@"CLOUD STATUS: %@", error);
        }
        
        switch (accountStatus) {
            case CKAccountStatusAvailable:
                //NSLog(@"CLOUD STATUS: Available");
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
            _database = CKContainer.defaultContainer.privateCloudDatabase;
            _status = CloudSyncStatusEmpty;
            
            NSPredicate* pred = [NSPredicate predicateWithValue:TRUE];
            CKQuery* query = [[CKQuery alloc] initWithRecordType:kFileRecordType predicate:pred];
            query.sortDescriptors = @[];
            
            CKQueryOperation* op = [[CKQueryOperation alloc] initWithQuery:query];
            op.resultsLimit = 1; // CKQueryOperationMaximumResults
            
            op.recordFetchedBlock = ^(CKRecord* record) {
                NSLog(@"CLOUD RECORD: %@", record);
                _status = CloudSyncStatusAvailable;
            };
            
            op.queryCompletionBlock = ^(CKQueryCursor* cursor, NSError* error) {
                if (error != nil) {
                    NSLog(@"CLOUD: ERROR(%@)", error);
                    _status = CloudSyncStatusError;
                }
                else {
                    if (_status == CloudSyncStatusEmpty)
                        NSLog(@"CLOUD STATUS: Empty");
                    else
                        NSLog(@"CLOUD STATUS: Available");
                }
            };
            
            [_database addOperation:op];
        }
    }];
}

// MARK: IMPORT and EXPORT

+(void)import {
}

+(void)export {
}

// currently sync is just a export and import
+(void)sync {
    [self import];
    [self export];
}

@end
