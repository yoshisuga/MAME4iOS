//
//  CloudSync.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CloudSyncStatus) {
    CloudSyncStatusUnknown,     // we have not checked yet
    CloudSyncStatusNoAccount,   // user does not have iCloud account
    CloudSyncStatusNotEntitled, // no entitlement
    CloudSyncStatusRestricted,  // unnable to connect to CloudKit
    CloudSyncStatusError,       // unnable to connect to CloudKit
    CloudSyncStatusEmpty,       // no data is in the Cloud
    CloudSyncStatusAvailable,   // all good
};

NS_ASSUME_NONNULL_BEGIN

@interface CloudSync : NSObject

-(instancetype)init NS_UNAVAILABLE;

@property(class,nonatomic,readonly) CloudSyncStatus status;

+(void)import;
+(void)export;
+(void)sync;
+(void)delete;

@end

NS_ASSUME_NONNULL_END
