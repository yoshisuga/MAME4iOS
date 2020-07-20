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
    UIUserInterfaceIdiom idiom = UIDevice.currentDevice.userInterfaceIdiom;
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    CGSize windowSize = UIApplication.sharedApplication.keyWindow.bounds.size;
    #pragma clang diagnostic pop
    CGFloat maxLength = MAX(screenSize.width, screenSize.height);

    assert(idiom != 5);     // 5 is UIUserInterfaceIdiomMac
    assert(idiom != UIUserInterfaceIdiomUnspecified);
    assert(idiom == UIUserInterfaceIdiomPad || idiom == UIUserInterfaceIdiomPhone);
    
    if ( idiom == UIUserInterfaceIdiomPad && !CGSizeEqualToSize(windowSize, CGSizeZero) && !CGSizeEqualToSize(screenSize, windowSize)) {
        // we are on an iPad in SlideOver or SplitScreen mode. pretend to be a generic iPhone or iPad based on aspect.

        CGFloat aspect = MAX(windowSize.width, windowSize.height) / MIN(windowSize.width, windowSize.height);

        if (aspect >= 1.5)
            return IPHONE_GENERIC;
        else
            return IPAD_GENERIC;
    }
    else if ( idiom == UIUserInterfaceIdiomPhone ) {
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
            return IPHONE_GENERIC;
        }
    } else if ( idiom == UIUserInterfaceIdiomPad ) {
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
            return IPAD_GENERIC;
        }
    } else {
        assert(FALSE);
        return IPAD_GENERIC;
    }
}

@end
