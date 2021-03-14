//
//  SystemImage.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SystemImage)

#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0)
#define systemImageNamed __systemImageNamed

// a polyfill for [UIImage systemImageNamed:] for pre-iOS13, will use fallback image in app bundle or nil if none
+(nullable UIImage*)__systemImageNamed:(NSString*)name;

#endif

// a helper to create a system time of a specific size and weight
+(nullable UIImage*)systemImageNamed:(NSString*)name withStyle:(UIFontTextStyle)style;
+(nullable UIImage*)systemImageNamed:(NSString*)name withScale:(NSInteger)scale;
+(nullable UIImage*)systemImageNamed:(NSString*)name withPointSize:(CGFloat)pointSize weight:(UIFontWeight)weight;
+(nullable UIImage*)systemImageNamed:(NSString*)name withPointSize:(CGFloat)pointSize;
+(nullable UIImage*)systemImageNamed:(NSString*)name withFont:(UIFont*)font;

// smash together some text + image + text
+ (UIImage*)imageWithText:(NSString*)textLeft image:(UIImage*)image text:(NSString*)textRight font:(UIFont*)font;

// convert text to a UIImaage, replacing any strings of the form ":symbol:" with a systemImage
//      :symbol-name:                - return a UIImage created from [UIImage systemImageNamed] or [UIImage imageNamed]
//      :symbol-name:fallback:       - return symbol as UIImage or fallback text if image not found
//      :symbol-name:text            - return symbol + text
//      :symbol-name:fallback:text   - return symbol or fallback text + text
+ (UIImage*)imageWithString:(NSString*)text withFont:(nullable UIFont*)font;
+ (UIImage*)imageWithString:(NSString*)text;

@end

NS_ASSUME_NONNULL_END

