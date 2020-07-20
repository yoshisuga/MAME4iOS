//
//  ColorSpace.m
//
//  Created by Todd Laney on 6/30/20.
//  Copyright © 2020 Wombat. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <simd/SIMD.h>
#import "ColorSpace.h"

// COLOR MATCH a CGColor
simd_float4 ColorMatchCGColor(CGColorSpaceRef destColorSpace, CGColorRef sourceColor) {
    CGColorRef destColor = CGColorCreateCopyByMatchingToColorSpace(destColorSpace, kCGRenderingIntentDefault, sourceColor, NULL);
    const CGFloat* c = CGColorGetComponents(destColor);
    simd_float4 color = simd_make_float4(c[0], c[1], c[2], c[3]);
    CGColorRelease(destColor);
    return color;
}
// COLOR MATCH a UIColor
simd_float4 ColorMatchUIColor(CGColorSpaceRef destColorSpace, UIColor* color) {
    return ColorMatchCGColor(destColorSpace, color.CGColor);
}
// COLOR MATCH a SIMD Color
simd_float4 ColorMatchColor(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, simd_float4 color) {
    CGFloat rgba[] = {color.r,color.g,color.b,color.a};
    CGColorRef sourceSolor = CGColorCreate(sourceColorSpace, rgba);
    return ColorMatchCGColor(destColorSpace, sourceSolor);
}
// COLOR MATCH a RGB Color
simd_float4 ColorMatchRGB(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, CGFloat r, CGFloat g, CGFloat b) {
    return ColorMatchColor(destColorSpace, sourceColorSpace, simd_make_float4(r, g, b, 1));
}
// COLOR MATCH a RGBA Color
simd_float4 ColorMatchRGBA(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return ColorMatchColor(destColorSpace, sourceColorSpace, simd_make_float4(r, g, b, a));
}

simd_float4 ColorMatch(CFStringRef destColorSpace, CFStringRef sourceColorSpace, simd_float4 color) {
    return ColorMatchColor(ColorSpaceWithName(destColorSpace), ColorSpaceWithName(sourceColorSpace), color);
}


CGColorSpaceRef ColorSpaceWithName(CFStringRef colorSpaceName) {
    return ColorSpaceFromString((__bridge NSString *)colorSpaceName);
}

// you can specify a colorSpace in two ways, with a system name or with parameters.
// these strings are of the form <colorSpace name OR colorSpace parameters>
CGColorSpaceRef ColorSpaceFromString(NSString* string) {
    
    static NSMutableDictionary* g_color_space;
    g_color_space = g_color_space ?: [[NSMutableDictionary alloc] init];
    CGColorSpaceRef colorSpace = (CGColorSpaceRef)[g_color_space[string ?: @""] pointerValue];
    
    if (colorSpace != NULL) {
        CGColorSpaceRetain(colorSpace);
        return colorSpace;
    }

    NSArray* values = [string componentsSeparatedByString:@","];
    assert(values.count == 1 || values.count == 3 || values.count == 6 || values.count == 9 || values.count == 18);

    if ([string length] == 0 || [string isEqualToString:@"Default"] || [string isEqualToString:@"DeviceRGB"]) {
        // Default or None
        colorSpace = nil;
    }
    else if (values.count < 3) {
        // named colorSpace
        CFStringRef name = (__bridge CFStringRef)[values.firstObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        colorSpace = CGColorSpaceCreateWithName(name);
    }
    else {
        // calibrated color space <white point>, <black point>, <gamma>, <matrix>
        CGFloat whitePoint[] = {0.0,0.0,0.0};
        CGFloat blackPoint[] = {0.0,0.0,0.0};
        CGFloat gamma[] = {1.0,1.0,1.0};
        CGFloat matrix[] = {1.0,0.0,0.0, 0.0,1.0,0.0, 0.0,0.0,1.0};
        
        for (int i=0; i<3; i++)
            whitePoint[i] = [values[0+i] doubleValue];
        
        if (values.count >= 6) {
            for (int i=0; i<3; i++)
                blackPoint[i] = [values[3+i] doubleValue];
        }
        if (values.count >= 9) {
            for (int i=0; i<3; i++)
                gamma[i] = [values[6+i] doubleValue];
        }
        if (values.count >= 18) {
            for (int i=0; i<9; i++)
                matrix[i] = [values[9+i] doubleValue];
        }

        colorSpace = CGColorSpaceCreateCalibratedRGB(whitePoint, blackPoint, gamma, matrix);
    }
    
    colorSpace = colorSpace ?: CGColorSpaceCreateDeviceRGB();
    g_color_space[string ?: @""] = [NSValue valueWithPointer:colorSpace];
    CGColorSpaceRetain(colorSpace);
    return colorSpace;
}
