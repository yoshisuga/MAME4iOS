//
//  DeviceScreenResolver.m
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 10/4/18.
//  Copyright © 2018 Seleuco. All rights reserved.
//

#import "DeviceScreenResolver.h"

@implementation DeviceScreenResolver

+(DeviceScreenType) resolve {
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGFloat maxLength = fmaxf(width, height);
    if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ) {
        if ( maxLength < 568.0f ) {
            return IPHONE_4_OR_LESS;
        } else if ( maxLength == 568.0f ) {
            return IPHONE_5;
        } else if ( maxLength == 667.0f ) {
            return IPHONE_6_7_8;
        } else if ( maxLength == 736.0f ) {
            return IPHONE_6_7_8_PLUS;
        } else if ( maxLength == 812.0f ) {
            return IPHONE_X_XS;
        } else if ( maxLength == 896.0f ) {
            return IPHONE_XR_XS_MAX;
        } else {
            return IPHONE_XR_XS_MAX;
        }
    } else if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
        if ( maxLength <= 1024.0f ) {
            return IPAD;
        } else if ( maxLength == 1080.0f ) {
            return IPAD_GEN_7;
        } else if ( maxLength == 1112.0f ) {
            return IPAD_PRO_10_5;
        } else if ( maxLength == 1194.0f ) {
            return IPAD_PRO_11;
        } else if ( maxLength == 1366.0f ) {
            return IPAD_PRO_12_9;
        } else {
            return IPAD_PRO_12_9;
        }
    } else {
        return IPHONE_XR_XS_MAX;
    }
}

@end
