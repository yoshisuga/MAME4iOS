//
//  CloudSync.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/18/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "CloudSync.h"
#import <CloudKit/CloudKit.h>

@implementation CloudSync

static CloudSyncStatus _status;

+(CloudSyncStatus)status {
    return _status;
}

+(void)updateCloudStatus {
    
}

+(void)load {
    [self updateCloudStatus];
}

-(instancetype)init {
    NSParameterAssert(FALSE);
    return nil;
}

+(void)import {
    
}
+(void)export {
    
}
+(void)sync {
    
}

@end
