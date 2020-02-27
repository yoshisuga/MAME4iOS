//
//  SystemImage.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "SystemImage.h"

#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0)

#undef systemImageNamed

@implementation UIImage (SystemImage)

// a polyfill for [UIImage systemImageNamed:] for pre-iOS13, will use fallback image in app bundle or nil if none
+(UIImage*)__systemImageNamed:(NSString*)name
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [self systemImageNamed:name];
    else
        return [self imageNamed:name];
}

@end

#endif


