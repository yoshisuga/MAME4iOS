//
//  CloudSync.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CloudSyncStatus) {
    CloudSyncStatusUnknown,
    CloudSyncStatusFailed,
    CloudSyncStatusEmpty,
    CloudSyncStatusOk,
};

NS_ASSUME_NONNULL_BEGIN

@interface CloudSync : NSObject

@property(class,nonatomic,readonly) CloudSyncStatus status;

+(void)import;
+(void)export;
+(void)sync;

@end

NS_ASSUME_NONNULL_END
