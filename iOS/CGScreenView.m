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
#import "myosd.h"

@interface CGScreenLayer : CALayer
@end

@implementation CGScreenLayer {
    CGContextRef _bitmapContext[2];
    CGColorSpaceRef _colorSpace;
}

+ (id) defaultActionForKey:(NSString *)key
{
    return nil;
}

-(void)setColorSpace:(CGColorSpaceRef)colorSpace {
    if (colorSpace == _colorSpace)
        return;
    
    CGColorSpaceRetain(colorSpace);
    CGColorSpaceRelease(_colorSpace);
    _colorSpace = colorSpace;
    
    CGContextRelease(_bitmapContext[0]);
    _bitmapContext[0] = nil;

    CGContextRelease(_bitmapContext[1]);
    _bitmapContext[1] = nil;
}

- (void)setup {

    if (_colorSpace == nil)
        _colorSpace = CGColorSpaceCreateDeviceRGB();
    
    for (int i=0; i<2; i++) {
        
        CGContextRelease(_bitmapContext[i]);
        _bitmapContext[i] = CGBitmapContextCreate(myosd_screen + i * (MYOSD_BUFFER_WIDTH * MYOSD_BUFFER_HEIGHT),
                                                  myosd_video_width,myosd_video_height,5,myosd_video_width*2,
                                                  _colorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast*/);
        
        // this might have failed because of a unsuported colorspace, try one more time with DeviceRGB
        if (_bitmapContext[i] == nil) {
            CGColorSpaceRelease(_colorSpace);
            _colorSpace = CGColorSpaceCreateDeviceRGB();
            _bitmapContext[i] = CGBitmapContextCreate(myosd_screen + i * (MYOSD_BUFFER_WIDTH * MYOSD_BUFFER_HEIGHT),
                                                      myosd_video_width,myosd_video_height,5,myosd_video_width*2,
                                                      _colorSpace,kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast*/);
        }
        NSAssert(_bitmapContext != nil, @"ack!");
    }
}

- (void)display {

    if (_bitmapContext[0] == nil || CGBitmapContextGetWidth(_bitmapContext[0]) != myosd_video_width || CGBitmapContextGetHeight(_bitmapContext[0]) != myosd_video_height)
        [self setup];
    
    CGContextRef bitmapContext = (myosd_prev_screen == myosd_screen) ? _bitmapContext[0] :  _bitmapContext[1];

    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    self.contents = (__bridge id)cgImage;
    CGImageRelease(cgImage);
}

- (void)dealloc {
    CGContextRelease(_bitmapContext[0]);
    _bitmapContext[0] = nil;
    
    CGContextRelease(_bitmapContext[1]);
    _bitmapContext[1] = nil;
    
    CGColorSpaceRelease(_colorSpace);
    _colorSpace = nil;
}
@end

@implementation CGScreenView {
    NSDictionary* _options;

    #define MAX_MAME_SCREENS 4
    struct {
        CGRect bounds;      // location in buffer of screen.
        CGSize size;        // original size in pixels of screen.
    }   _mame_screen_info[MAX_MAME_SCREENS];
    int _mame_screen_count;
    
    NSTimeInterval _startRenderTime;
    NSTimeInterval _lastDisplayTime;
}

+ (Class) layerClass
{
    return [CGScreenLayer class];
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])!=nil) {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
	}
    
	return self;
}
- (void)setOptions:(NSDictionary *)options {
    _options = options;
    
    // set a custom color space
    NSString* color_space = _options[kScreenViewColorSpace];

    if (color_space != nil)
    {
        CGColorSpaceRef colorSpace = [[self class] createColorSpaceFromString:color_space];
        [(CGScreenLayer*)self.layer setColorSpace:colorSpace];
        CGColorSpaceRelease(colorSpace);
    }

    // enable filtering
    if ([_options[kScreenViewFilter] isEqualToString:kScreenViewFilterLinear])
        self.layer.minificationFilter = self.layer.magnificationFilter = kCAFilterLinear;
    else
        self.layer.minificationFilter = self.layer.magnificationFilter = kCAFilterNearest;

    // tell layoutSubviews to update the overlay effect.
    _mame_screen_count = 0;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // reset the frame count each time we resize
    _frameCount = 0;
    
    // remove any previous overlays
    while (self.subviews.count > 0)
        [self.subviews.firstObject removeFromSuperview];

    // create overlay to handle effect
    NSString* effect = _options[kScreenViewEffect];
    
    if ([effect length] != 0 && ![effect isEqualToString:kScreenViewEffectNone]) {
        for (int i=0; i<_mame_screen_count; i++) {
            
            CGRect source_rect = CGRectMake(0, 0, myosd_video_width, myosd_video_height);
            CGRect screen_rect = _mame_screen_info[i].bounds;
            CGSize screen_size = _mame_screen_info[i].size;
            
            [self buildEffectOverlay: [effect componentsSeparatedByString:@","]
                            dst_rect:self.bounds src_rect:source_rect screen_rect:screen_rect screen_pixel_size:screen_size];
        }
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

// frame and render statistics
@synthesize frameCount=_frameCount, frameRate=_frameRate, frameRateAverage=_frameRateAverage, renderTime=_renderTime, renderTimeAverage=_renderTimeAverage;

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    
    if (_startRenderTime == 0)
        return;
    
    NSTimeInterval now = CACurrentMediaTime();
    
    // set the frameRate and total frameTime
    if (_frameCount == 0) {
        _frameRateAverage = 0;
        _renderTimeAverage = 0;
    }
    
    if (_lastDisplayTime != 0 && (now - _lastDisplayTime) < 0.250) {
        NSTimeInterval frameRate = 1.0 / (now - _lastDisplayTime);
        _frameRate = frameRate;
        if (_frameRateAverage != 0)
            _frameRateAverage = ((_frameRateAverage * _frameCount) + frameRate) / (_frameCount+1);
        else
            _frameRateAverage = frameRate;
    }
    _lastDisplayTime = now;

    // set the renderRate and total renderTime
    if (_startRenderTime != 0) {
        NSTimeInterval renderTime = (now - _startRenderTime);
        _renderTime = renderTime;
        if (_renderTimeAverage != 0)
            _renderTimeAverage = ((_renderTimeAverage * _frameCount) + renderTime) / (_frameCount+1);
        else
            _renderTimeAverage = renderTime;
    }
    _startRenderTime = 0;
    
    _frameCount += 1;
}

// return 1 if you handled the draw, 0 for a software render
// NOTE this is called on MAME background thread, dont do anything stupid.
//
// all we do in the CoreGraphics case is find the location of all the SCREENs
// so we can put effect overlays on top of only them.
//
- (int)drawScreen:(void*)prim_list {
    
    _startRenderTime = CACurrentMediaTime();

    int screen_count = 0;
    
    // walk the primitive list and find the location and size of the screen(s) in the buffer.
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        if (prim->type == RENDER_PRIMITIVE_QUAD && prim->screentex && prim->texture_base != NULL) {

            if (screen_count == sizeof(_mame_screen_info)/sizeof(_mame_screen_info[0]))
                break;

            _mame_screen_info[screen_count].bounds.origin.x = floor(prim->bounds_x0);
            _mame_screen_info[screen_count].bounds.origin.y = floor(prim->bounds_y0);
            _mame_screen_info[screen_count].bounds.size.width = floor(prim->bounds_x1) - floor(prim->bounds_x0);
            _mame_screen_info[screen_count].bounds.size.height = floor(prim->bounds_y1) - floor(prim->bounds_y0);

            if (prim->texorient & ORIENTATION_SWAP_XY)
                _mame_screen_info[screen_count].size = CGSizeMake(prim->texture_height, prim->texture_width);
            else
                _mame_screen_info[screen_count].size = CGSizeMake(prim->texture_width, prim->texture_height);

            screen_count++;
        }
    }
    
    if (_mame_screen_count != screen_count) {
        [self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
    }
    _mame_screen_count = screen_count;

    // always return 0 saying we want a software render
    return 0;
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
    
    CGFloat scale = self.window.screen.scale;

    // map the screen rect into the destination
    dst_rect.origin.x += floor((screen_rect.origin.x - src_rect.origin.x) * dst_rect.size.width / src_rect.size.width * scale) / scale;
    dst_rect.origin.y += floor((screen_rect.origin.y - src_rect.origin.y) * dst_rect.size.height / src_rect.size.height * scale) / scale;
    dst_rect.size.width  = ceil(screen_rect.size.width  * dst_rect.size.width / src_rect.size.width * scale) / scale;
    dst_rect.size.height = ceil(screen_rect.size.height * dst_rect.size.height / src_rect.size.height * scale) / scale;

    CGSize dst_pixel_size; // calculate the size of an output pixel in the destination
    dst_pixel_size.width  = ceil(dst_rect.size.width  * scale / screen_pixel_size.width)  / scale;
    dst_pixel_size.height = ceil(dst_rect.size.height * scale / screen_pixel_size.height) / scale;

    CGSize image_size; // make a image large enough to hold all rounded up pixels
    image_size.width  = dst_pixel_size.width  * screen_pixel_size.width;
    image_size.height = dst_pixel_size.height * screen_pixel_size.height;

    __block BOOL show = FALSE;
    UIImage* image = [[[UIGraphicsImageRenderer alloc] initWithSize:image_size] imageWithActions:^(UIGraphicsImageRendererContext* context) {
        for (NSString* effect in effects) {
            UIImage* tile_image = [UIImage imageNamed:[effect stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
        
            // tile image must be @1x, and the height of a single pixel, and a integer number of pixels wide: 1:1, 2:1, 3:1 etc...
            NSParameterAssert(tile_image != nil);
            NSParameterAssert(tile_image.scale == 1.0);
            NSParameterAssert(tile_image.size.width / tile_image.size.height == floor(tile_image.size.width / tile_image.size.height));
            
            // ignore a 1x1 filter, it will just be a solid color!
            if ((dst_pixel_size.height * scale) == 1.0 && tile_image.size.width == tile_image.size.height)
                return;
            
            if (tile_image != nil) {
                CGRect tile_rect = CGRectMake(0, 0, dst_pixel_size.width * tile_image.size.width / tile_image.size.height, dst_pixel_size.height);
                CGContextDrawTiledImage(context.CGContext, tile_rect, tile_image.CGImage);
                show = TRUE;
            }
        }
    }];
    
    // make image view with image, image will be scaled down, but will keep perfect alignment with source pixels.
    if (show) {
        UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = dst_rect;
        [self addSubview:imageView];
    }
}


// you can specify a colorSpace in two ways, with a system name or with parameters.
// these strings are of the form <colorSpace name OR colorSpace parameters>
+ (CGColorSpaceRef)createColorSpaceFromString:(NSString*)string {
    
    static CGColorSpaceRef g_colorspace;
    static NSString* g_colorspace_string;
    
    if ([g_colorspace_string isEqualToString:string]) {
        CGColorSpaceRetain(g_colorspace);
        return g_colorspace;
    }
    
    NSArray* values = [string componentsSeparatedByString:@","];
    NSAssert(values.count == 1 || values.count == 3 || values.count == 6 || values.count == 9 || values.count == 18, @"bad colorspace string");

    CGColorSpaceRef colorSpace;

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
    CGColorSpaceRelease(g_colorspace);
    g_colorspace = colorSpace;
    g_colorspace_string = string;

    CGColorSpaceRetain(g_colorspace);
    return g_colorspace;
}

// DEBUG code to NSLog() the render data, hit key CMD+D or OPTION+D to dump once.
#ifdef DEBUG
static BOOL g_render_dump = 0;

+ (void)drawScreenDebugDump {
    g_render_dump = 1;
}

// NOTE this is called on MAME background thread, dont do anything stupid.
+ (void)drawScreenDebug:(void*)prim_list {

    static char* texture_format_name[] = {"UNDEFINED", "PAL16", "PALA16", "555", "RGB", "ARGB", "YUV16"};
    static char* blend_mode_name[] = {"NONE", "ALPHA", "MUL", "ADD"};
    
    if (g_render_dump == 0)
        return;
    g_render_dump = 0;
    
    NSLog(@"Draw Screen: %dx%d", myosd_video_width, myosd_video_height);
    
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        
        assert(prim->type == RENDER_PRIMITIVE_LINE || prim->type == RENDER_PRIMITIVE_QUAD);
        assert(prim->blendmode <= BLENDMODE_ADD);
        assert(prim->texformat <= TEXFORMAT_YUY16);
        assert(prim->unused == 0);

        int blend = prim->blendmode;
        int fmt = prim->texformat;
        int aa = prim->antialias;
        int screen = prim->screentex;
        int orient = prim->texorient;
        int wrap = prim->texwrap;

        if (prim->type == RENDER_PRIMITIVE_LINE) {
            NSLog(@"    LINE (%.0f,%.0f) -> (%.0f,%.0f) (%0.2f,%0.2f,%0.2f,%0.2f) %f %s%s",
                  prim->bounds_x0, prim->bounds_y0, prim->bounds_x1, prim->bounds_y1,
                  prim->color_r, prim->color_g, prim->color_b, prim->color_a,
                  prim->width, blend_mode_name[blend], aa ? " AA" : "");
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD && prim->texture_base == NULL) {
            NSLog(@"    QUAD [%.0f,%.0f,%.0f,%.0f] (%0.2f,%0.2f,%0.2f,%0.2f) %s%s",
                  prim->bounds_x0, prim->bounds_y0, prim->bounds_x1 - prim->bounds_x0, prim->bounds_y1 - prim->bounds_y0,
                  prim->color_r, prim->color_g, prim->color_b, prim->color_a,
                  blend_mode_name[blend], aa ? " AA" : "");
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD) {
            NSLog(@"    TEXQ [%.0f,%.0f,%.0f,%.0f] [(%.0f,%.0f),(%.0f,%.0f),(%.0f,%.0f),(%.0f,%.0f)] %s %dx%d (%lX:%d) %s%s%s%s%s%s%s%s",
                  prim->bounds_x0, prim->bounds_y0, prim->bounds_x1 - prim->bounds_x0, prim->bounds_y1 - prim->bounds_y0,
                  prim->texcoords[0].u, prim->texcoords[0].v,
                  prim->texcoords[1].u, prim->texcoords[1].v,
                  prim->texcoords[2].u, prim->texcoords[2].v,
                  prim->texcoords[3].u, prim->texcoords[3].v,
                  blend_mode_name[blend],
                  prim->texture_width, prim->texture_height, (intptr_t)prim->texture_base, prim->texture_seqid,
                  texture_format_name[fmt],
                  prim->texture_palette ? " PALLETE" : "",
                  aa ? " AA" : "",
                  screen ? " SCREEN" : "", wrap ? " WRAP" : "",
                  (orient & ORIENTATION_FLIP_X) ? " FLIPX" : "",
                  (orient & ORIENTATION_FLIP_Y) ? " FLIPY" : "",
                  (orient & ORIENTATION_SWAP_XY) ? " SWAPXY" : ""
                  );
        }
    }
}
#endif

@end


