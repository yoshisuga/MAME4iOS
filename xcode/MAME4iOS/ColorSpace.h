//
//  ColorSpace.h
//
//  Created by Todd Laney on 6/30/20.
//  Copyright © 2020 Wombat. All rights reserved.
//

#ifndef ColorSpace_h
#define ColorSpace_h

// you can specify a colorSpace in two ways, with a system name or with parameters.
// these strings are of the form <colorSpace name OR colorSpace parameters>
CGColorSpaceRef ColorSpaceWithName(CFStringRef colorSpaceName);
CGColorSpaceRef ColorSpaceFromString(NSString* string);

// COLOR MATCH a CGColor
simd_float4 ColorMatchCGColor(CGColorSpaceRef destColorSpace, CGColorRef sourceColor);
// COLOR MATCH a UIColor
simd_float4 ColorMatchUIColor(CGColorSpaceRef destColorSpace, UIColor* color);
// COLOR MATCH a SIMD Color
simd_float4 ColorMatchColor(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, simd_float4 color);
simd_float4 ColorMatchRGB(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, CGFloat r, CGFloat g, CGFloat b);
simd_float4 ColorMatchRGBA(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, CGFloat r, CGFloat g, CGFloat b, CGFloat a);
simd_float4 ColorMatch(CFStringRef destColorSpace, CFStringRef sourceColorSpace, simd_float4 color);

#endif /* ColorSpace_h */
