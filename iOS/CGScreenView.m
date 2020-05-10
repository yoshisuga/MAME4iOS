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

#ifdef XDEBUG
#define TEST_WIDTH 64
#define TEST_HEIGHT 64

#define TEST_SRC_X 4
#define TEST_SRC_Y 4
#define TEST_SRC_W 56
#define TEST_SRC_H 56

#define TEST_SRC_PIXEL_W 28
#define TEST_SRC_PIXEL_H 28
#endif

- (void)display {
    
    if (_bitmapContext == nil)
    {
        if (_colorSpace == nil)
            _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _bitmapContext = CGBitmapContextCreate(img_buffer,
#ifdef TEST_WIDTH
                                               TEST_WIDTH, TEST_HEIGHT,
#else
                                               myosd_video_width,myosd_video_height,
#endif
                                               5,myosd_video_width*2,
                                               _colorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast*/);
        if (_bitmapContext == nil) {
            CGColorSpaceRelease(_colorSpace);
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
    NSString* color_space = _options[kScreenViewColorSpace];

    if (color_space != nil)
    {
        CGColorSpaceRef colorSpace = [[self class] createColorSpaceFromString:color_space];
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
    
    // remove any previous overlays
    while (self.subviews.count > 0)
        [self.subviews.firstObject removeFromSuperview];

    // create overlay to handle effect
    NSString* effect = _options[kScreenViewEffect];
    
    if ([effect length] != 0 && ![effect isEqualToString:kScreenViewEffectNone]) {
        CGRect source_rect = CGRectMake(0, 0, myosd_video_width, myosd_video_height);

        CGRect screen_rect = CGRectMake(0, 0, myosd_video_width, myosd_video_height);
        if (_options[kScreenViewEffectScreenRect] != nil)
            screen_rect = [_options[kScreenViewEffectScreenRect] CGRectValue];

        CGSize screen_size = screen_rect.size;
        if (_options[kScreenViewEffectScreenSize] != nil)
            screen_size = [_options[kScreenViewEffectScreenSize] CGSizeValue];
        
#ifdef TEST_WIDTH
        source_rect = CGRectMake(0, 0, TEST_WIDTH, TEST_HEIGHT);
        screen_rect = CGRectMake(TEST_SRC_X, TEST_SRC_Y, TEST_SRC_W, TEST_SRC_H);
        screen_size = screen_rect.size;
#endif

        [self buildEffectOverlay: [effect componentsSeparatedByString:@","]
                        dst_rect:self.bounds src_rect:source_rect screen_rect:screen_rect screen_pixel_size:screen_size];
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
// these strings are of the form <colorSpace name OR colorSpace parameters>
+ (CGColorSpaceRef)createColorSpaceFromString:(NSString*)string {
    
    if ([string length] == 0 || [string isEqualToString:@"Default"] || [string isEqualToString:@"DeviceRGB"])
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


//
//  buildEffectOverlay
//
//  effects     - overlay image(s) to tile
//  dst_rect    - destination rect in our UIView, should be bounds
//  src_rect    - source rect, size of the entire backing bitmap
//  screen_rect - rect inside source to apply effect
//  screen_pixel_size - size in original pixels of screen_rect.
//
- (void)buildEffectOverlay:(NSArray<NSString*>*)effects dst_rect:(CGRect)dst_rect src_rect:(CGRect)src_rect screen_rect:(CGRect)screen_rect screen_pixel_size:(CGSize)screen_pixel_size {

    // map the screen rect into the destination
    dst_rect.origin.x += floor((screen_rect.origin.x - src_rect.origin.x) * dst_rect.size.width / src_rect.size.width);
    dst_rect.origin.y += floor((screen_rect.origin.y - src_rect.origin.y) * dst_rect.size.height / src_rect.size.height);
    dst_rect.size.width  = ceil(screen_rect.size.width  * dst_rect.size.width / src_rect.size.width);
    dst_rect.size.height = ceil(screen_rect.size.height * dst_rect.size.height / src_rect.size.height);

    CGSize dst_pixel_size; // calculate the size of an output pixel in the destination, rounded up
    dst_pixel_size.width  = ceil(dst_rect.size.width / screen_pixel_size.width);
    dst_pixel_size.height = ceil(dst_rect.size.height / screen_pixel_size.height);
    
    CGSize image_size; // make a image large enough to hold all rounded up pixels
    image_size.width  = dst_pixel_size.width  * screen_pixel_size.width;
    image_size.height = dst_pixel_size.height * screen_pixel_size.height;
    
    UIImage* image = [[[UIGraphicsImageRenderer alloc] initWithSize:image_size] imageWithActions:^(UIGraphicsImageRendererContext* context) {
        for (NSString* effect in effects) {
            UIImage* tile_image = [UIImage imageNamed:[effect stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
        
            // tile image must be @1x, and the height of a single pixel, and a integer number of pixels wide: 1:1, 2:1, 3:1 etc...
            NSParameterAssert(tile_image != nil);
            NSParameterAssert(tile_image.scale == 1.0);
            NSParameterAssert(tile_image.size.width / tile_image.size.height == floor(tile_image.size.width / tile_image.size.height));
            
            if (tile_image != nil) {
                CGRect tile_rect = CGRectMake(0, 0, dst_pixel_size.width * tile_image.size.width / tile_image.size.height, dst_pixel_size.height);
                CGContextDrawTiledImage(context.CGContext, tile_rect, tile_image.CGImage);
            }
        }
    }];
    
    // make image view with image, image will be scaled down, but will keep perfect alignment with source pixels.
    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = dst_rect;
    [self addSubview:imageView];
}

@end
