//
//  SystemImage.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "SystemImage.h"

@implementation UIImage (SystemImage)

#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0)
#undef systemImageNamed

// a polyfill for [UIImage systemImageNamed:] for pre-iOS13, will use fallback image in app bundle or nil if none
+(UIImage*)__systemImageNamed:(NSString*)name
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [self systemImageNamed:name];
    else
        return [self imageNamed:name];
}

#define systemImageNamed __systemImageNamed
#endif

// a helpers to create a system image of a specific size and weight or based on a font
+(nullable UIImage*)systemImageNamed:(NSString*)name withPointSize:(CGFloat)pointSize weight:(UIFontWeight)weight
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [[self systemImageNamed:name] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pointSize weight:UIImageSymbolWeightForFontWeight(weight)]];
    else
        return [self systemImageNamed:name];
}

+(nullable UIImage*)systemImageNamed:(NSString*)name withPointSize:(CGFloat)pointSize
{
    return [self systemImageNamed:name withPointSize:pointSize weight:UIFontWeightRegular];
}

+(nullable UIImage*)systemImageNamed:(NSString*)name withFont:(UIFont*)font
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [[self systemImageNamed:name] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithFont:font]];
    else
        return [self systemImageNamed:name];
}


@end


