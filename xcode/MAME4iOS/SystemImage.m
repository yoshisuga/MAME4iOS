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

+(nullable UIImage*)systemImageNamed:(NSString*)name withStyle:(UIFontTextStyle)style
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [[self systemImageNamed:name] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:style]];
    else
        return [self systemImageNamed:name];
}

+(nullable UIImage*)systemImageNamed:(NSString*)name withScale:(NSInteger)scale
{
    if (@available(iOS 13.0, tvOS 13.0, *))
        return [[self systemImageNamed:name] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithScale:(UIImageSymbolScale)scale]];
    else
        return [self systemImageNamed:name];
}

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

// convert text to a UIImaage, replacing any strings of the form ":symbol:" with a systemImage
//      :symbol-name:                - return a UIImage created from [UIImage systemImageNamed] or [UIImage imageNamed]
//      :symbol-name:fallback:       - return symbol as UIImage or fallback text if image not found
//      :symbol-name:text            - return symbol + text
//      :symbol-name:fallback:text   - return symbol or fallback text + text
+ (UIImage*)imageWithString:(NSString*)text withFont:(UIFont*)_font {

    UIImage* image;
    UIFont* font = _font ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    // handle :symbol-name: or :symbol-name:fallback:
    NSArray* arr = [(NSString*)text componentsSeparatedByString:@":"];
    if (arr.count > 2) {
        text = arr.lastObject;

        if (@available(iOS 13.0, tvOS 13.0, *))
            image = [[UIImage systemImageNamed:arr[1]] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithFont:font]];

        // use fallback text if image not found.
        if (image == nil && arr.count == 4)
            text = [arr[2] stringByAppendingString:text];
    }
    
    // if we have both text and an image, combine image + text
    if (image == nil || text.length > 0) {
        CGFloat spacing = 4.0;
        NSDictionary* attributes = @{NSFontAttributeName:font};
        
        CGSize textSize = [text boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
        CGSize size = CGSizeMake(ceil(textSize.width), ceil(textSize.height));

        if (image != nil) {
            size.width += image.size.width + spacing;
            size.height = MAX(size.height, image.size.height);
        }
        
        image = [[[UIGraphicsImageRenderer alloc] initWithSize:size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
            CGPoint point = CGPointZero;
            
            if (image != nil) {
                // TODO: align to baseline?
                [image drawAtPoint:CGPointMake(point.x, (size.height - image.size.height)/2)];
                point.x += image.size.width + spacing;
            }

            [text drawAtPoint:CGPointMake(point.x, (size.height - textSize.height)/2) withAttributes:attributes];
        }];
    }

    return image;
}

+ (UIImage*)imageWithString:(NSString*)text {
    return [self imageWithString:text withFont:nil];
}


@end


