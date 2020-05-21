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
#import <Metal/Metal.h>
#import "CGScreenView.h"        // for colorspace helper.
#import "MetalScreenView.h"
#import "myosd.h"

@implementation MetalScreenView {
    NSDictionary* _options;
    CALayerContentsFilter _filter;
}

// frame and render statistics
@synthesize frameCount=_frameCount, frameTime=_frameTime, renderTime=_renderTime, frameRate=_frameRate, renderRate=_renderRate;

// CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
+ (Class) layerClass
{
    return [CAMetalLayer class];
}
#pragma clang diagnostic pop
+ (BOOL)isSupported {
    static BOOL isMetalSupported;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isMetalSupported = MTLCreateSystemDefaultDevice() != nil;
    });
    return isMetalSupported;
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
        CGColorSpaceRef colorSpace = [CGScreenView createColorSpaceFromString:color_space];
        [(id)self.layer setColorspace:colorSpace];
        CGColorSpaceRelease(colorSpace);
    }

    // enable filtering
    NSString* filter = _options[kScreenViewFilter];
    
    if ([filter isEqualToString:kScreenViewFilterTrilinear])
        _filter = kCAFilterTrilinear;
    else if ([filter isEqualToString:kScreenViewFilterLinear])
        _filter = kCAFilterLinear;
    else
        _filter = kCAFilterNearest;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
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

// return 1 if you handled the draw, 0 for a software render
// NOTE this is called on MAME background thread, dont do anything stupid.
- (int)drawScreen:(void*)prim_list {
    
#ifdef DEBUG
    [self drawScreenDebug:prim_list];
#endif

    // walk the primitive list and render
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        if (prim->type == RENDER_PRIMITIVE_QUAD && prim->screentex && prim->texture_base != NULL) {
        }
    }
    
    // always return 1 saying we handled the draw.
    return 1;
}

#ifdef DEBUG
//
// CODE COVERAGE - this is where we track what types of primitives MAME has given us.
//                 run the app in the debugger, and if you stop in this function, you
//                 have seen a primitive or texture format that needs verified, verify
//                 that the game runs and looks right, then check off that things worked
//
// LINES
//      [ ] width <= 1.0
//      [ ] width  > 1.0
//      [ ] blend mode NONE
//      [ ] blend mode ALPHA
//      [ ] blend mode MULTIPLY
//      [ ] blend mode ADD
//      [ ] antialias
//
// QUADS
//      [ ] blend mode NONE
//      [ ] blend mode ALPHA
//      [ ] blend mode MULTIPLY
//      [ ] blend mode ADD
//
// TEXTURED QUADS
//      [ ] blend mode NONE
//      [ ] blend mode ALPHA
//      [ ] blend mode MULTIPLY
//      [ ] blend mode ADD
//      [ ] rotate 0
//      [ ] rotate 90
//      [ ] rotate 180
//      [ ] rotate 270
//      [ ] texture WRAP
//      [ ] texture CLAMP
//
// TEXTURE FORMATS
//      [ ] PALETTE16
//      [ ] PALETTEA16
//      [ ] RGB15
//      [ ] RGB32
//      [ ] ARGB32
//      [ ] YUY16
//      [ ] RGB15 with PALETTE
//      [ ] RGB32 with PALETTE
//      [ ] ARGB32 with PALETTE
//      [ ] YUY16 with PALETTE
//
- (void)drawScreenDebug:(void*)prim_list {
    
    return;

    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        
        assert(prim->type == RENDER_PRIMITIVE_LINE || prim->type == RENDER_PRIMITIVE_QUAD);
        assert(prim->blendmode <= BLENDMODE_ADD);
        assert(prim->texformat <= TEXFORMAT_YUY16);
        assert(prim->texture_base == NULL || prim->texformat != TEXFORMAT_UNDEFINED);
        assert(prim->unused == 0);

        float width = prim->width;
        int blend = prim->blendmode;
        int fmt = prim->texformat;
        int aa = prim->antialias;
        int orient = prim->texorient;
        int wrap = prim->texwrap;

        if (prim->type == RENDER_PRIMITIVE_LINE) {
            if (width <= 1.0)
                assert(FALSE);
            if (width  > 1.0)
                assert(FALSE);
            if (blend == BLENDMODE_NONE)
                assert(FALSE);
            if (blend == BLENDMODE_ALPHA)
                assert(FALSE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(FALSE);
            if (aa)
                assert(FALSE);
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD && prim->texture_base == NULL) {
            if (blend == BLENDMODE_NONE)
                assert(FALSE);
            if (blend == BLENDMODE_ALPHA)
                assert(FALSE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(FALSE);
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD) {
            if (blend == BLENDMODE_NONE)
                assert(FALSE);
            if (blend == BLENDMODE_ALPHA)
                assert(FALSE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(FALSE);
            
            if (orient == ORIENTATION_ROT0)
                assert(FALSE);
            if (orient == ORIENTATION_ROT90)
                assert(FALSE);
            if (orient == ORIENTATION_ROT180)
                assert(FALSE);
            if (orient == ORIENTATION_ROT270)
                assert(FALSE);
            
            if (wrap == 0)
                assert(FALSE);
            if (wrap == 1)
                assert(FALSE);

            if (fmt == TEXFORMAT_RGB15 && prim->texture_palette == NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_RGB32 && prim->texture_palette == NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_ARGB32 && prim->texture_palette == NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_YUY16 && prim->texture_palette == NULL)
                assert(FALSE);

            if (fmt == TEXFORMAT_PALETTE16 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_PALETTEA16 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_RGB15 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_RGB32 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_ARGB32 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_YUY16 && prim->texture_palette != NULL)
                assert(FALSE);
        }
    }
}
#endif

@end


