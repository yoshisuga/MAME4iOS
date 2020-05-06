/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */
#import "CGScreenView.h"
#import "Globals.h"

//static
unsigned short img_buffer [2880 * 2160]; // match max driver res?

@interface CGScreenLayer : CALayer
@end

@implementation CGScreenLayer {
    CGContextRef _bitmapContext;
    CGColorSpaceRef _colorSpace;
}

+ (id) defaultActionForKey:(NSString *)key
{
    return nil;
}

-(void)setColorSpace:(CGColorSpaceRef)colorSpace {
    CGColorSpaceRetain(colorSpace);
    CGColorSpaceRelease(_colorSpace);
    _colorSpace = colorSpace;
}

- (void)display {
    
    if (_bitmapContext == nil)
    {
        if (_colorSpace == nil)
            _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _bitmapContext = CGBitmapContextCreate(img_buffer,myosd_video_width,myosd_video_height,5,myosd_video_width*2,
                                               _colorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast*/);
        if (_bitmapContext == nil) {
            _colorSpace = CGColorSpaceCreateDeviceRGB();
            _bitmapContext = CGBitmapContextCreate(img_buffer,myosd_video_width,myosd_video_height,5,myosd_video_width*2,
                                                   _colorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast*/);
        }
        NSAssert(_bitmapContext != nil, @"ack!");
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(_bitmapContext);
    self.contents = (__bridge id)cgImage;
    CGImageRelease(cgImage);
}

- (void)dealloc {
    CGContextRelease(_bitmapContext);
    _bitmapContext = nil;

    CGColorSpaceRelease(_colorSpace);
    _colorSpace = nil;
}
@end

@implementation CGScreenView {
    NSDictionary* _options;
}

+ (Class) layerClass
{
    return [CGScreenLayer class];
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])!=nil) {
        
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
#if TARGET_OS_IOS
        self.multipleTouchEnabled = NO;
#endif
        self.userInteractionEnabled = NO;
	}
    
	return self;
}
- (id)initWithFrame:(CGRect)frame options:(NSDictionary*)options {
    self = [self initWithFrame:frame];
    _options = options;
    return self;
}
- (void)didMoveToWindow {
    
    if (self.window == nil)
        return;

    // set a custom color space
    if(_options[kScreenViewColorSpace] != nil)
    {
        CGColorSpaceRef colorSpace = [[self class] createColorSpaceFromString:_options[kScreenViewColorSpace]];
        [(CGScreenLayer*)self.layer setColorSpace:colorSpace];
        CGColorSpaceRelease(colorSpace);
    }

    // enable filtering
    NSString* filter = _options[kScreenViewFilter];
    
    if ([filter isEqualToString:kScreenViewFilterTrilinear])
    {
        [self.layer setMagnificationFilter:kCAFilterTrilinear];
        [self.layer setMinificationFilter:kCAFilterTrilinear];
    }
    else if ([filter isEqualToString:kScreenViewFilterLinear])
    {
        [self.layer setMagnificationFilter:kCAFilterLinear];
        [self.layer setMinificationFilter:kCAFilterLinear];
    }
    else
    {
        [self.layer setMagnificationFilter:kCAFilterNearest];
        [self.layer setMinificationFilter:kCAFilterNearest];
    }
}
- (void)drawRect:(CGRect)rect
{
    //printf("Draw rect\n");
    // UIView uses the existence of -drawRect: to determine if should allow its CALayer
    // to be invalidated, which would then lead to the layer creating a backing store and
    // -drawLayer:inContext: being called.
    // By implementing an empty -drawRect: method, we allow UIKit to continue to implement
    // this logic, while doing our real drawing work inside of -drawLayer:inContext:
}

// you can specify a colorSpace in two ways, with a system name or with parameters.
// these strings are of the form <Friendly Name> : <colorSpace name OR colorSpace parameters>
+ (CGColorSpaceRef)createColorSpaceFromString:(NSString*)string {
    
    if ([string containsString:@":"])
        string = [string componentsSeparatedByString:@":"].lastObject;

    string = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    
    if ([string length] == 0)
        return CGColorSpaceCreateDeviceRGB();
    
    NSArray* values = [string componentsSeparatedByString:@","];
    NSAssert(values.count == 1 || values.count == 3 || values.count == 6 || values.count == 9 || values.count == 18, @"bad colorspace string");
    
    // named colorSpace
    if (values.count < 3) {
        CFStringRef name = (__bridge CFStringRef)[values.firstObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        return CGColorSpaceCreateWithName(name) ?: CGColorSpaceCreateDeviceRGB();
    }
    
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

    return CGColorSpaceCreateCalibratedRGB(whitePoint, blackPoint, gamma, matrix);
}

@end
