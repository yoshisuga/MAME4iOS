//
//  DeviceScreenResolver.h
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 10/4/18.
//  Copyright © 2018 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DeviceScreenType) {
    IPHONE_4_OR_LESS,
    IPHONE_5,
    IPHONE_6_7_8,
    IPHONE_6_7_8_PLUS,
    IPHONE_X_XS,
    IPHONE_XR_XS_MAX,
    IPHONE_GENERIC,
    IPAD,
    IPAD_PRO_10_5,
    IPAD_PRO_11,
    IPAD_PRO_12_9,
    IPAD_GEN_7,
    IPAD_GENERIC,
};

@interface DeviceScreenResolver : NSObject
+(DeviceScreenType) resolve;
@end

NS_ASSUME_NONNULL_END
