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

static void texture_load(void* data, id<MTLTexture> texture) {
    myosd_render_primitive* prim = (myosd_render_primitive*)data;
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    
    switch (prim->texformat) {
        case TEXFORMAT_RGB15:
        {
            assert(FALSE);
            if (prim->texture_palette != NULL) {
                assert(FALSE);
            }
            else {
                assert(FALSE);
                [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:prim->texture_base bytesPerRow:prim->texture_rowpixels*2];
            }
            break;
        }
        case TEXFORMAT_RGB32:
        case TEXFORMAT_ARGB32:
        {
            if (prim->texture_palette != NULL) {
                assert(FALSE);
            }
            else {
                [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:prim->texture_base bytesPerRow:prim->texture_rowpixels*4];
            }
            break;
        }
        case TEXFORMAT_PALETTE16:
        case TEXFORMAT_PALETTEA16:
        {
            uint16_t* src = prim->texture_base;
            uint32_t* dst = (uint32_t*)myosd_screen;
            const uint32_t* pal = prim->texture_palette;
            for (NSUInteger y=0; y<height; y++) {
                for (NSUInteger x=0; x<width; x++) {
                    *dst++ = pal[*src++];
                }
                src += prim->texture_rowpixels - width;
            }
            [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:myosd_screen bytesPerRow:width*4];
            break;
        }
        case TEXFORMAT_YUY16:
        {
            assert(FALSE);
            uint16_t* src = prim->texture_base;
            uint32_t* dst = (uint32_t*)myosd_screen;
            for (NSUInteger y=0; y<height; y++) {
                for (NSUInteger x=0; x<width; x++) {
                    *dst = 0xDEADBEEF;
                }
                src += prim->texture_rowpixels - width;
            }
            [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:myosd_screen bytesPerRow:width*4];
            break;
        }
        default:
            assert(FALSE);
            break;
    }
}

// return 1 if you handled the draw, 0 for a software render
// NOTE this is called on MAME background thread, dont do anything stupid.
- (int)drawScreen:(void*)prim_list {
    static Shader shader_map[] = {ShaderCopy, ShaderAlpha, ShaderMultiply, ShaderAdd};
    static Shader shader_tex_map[]  = {ShaderTexture, ShaderTextureAlpha, ShaderTextureMultiply, ShaderTextureAdd};

#ifdef DEBUG
    [self drawScreenDebug:prim_list];
#endif

    if (![self drawBegin]) {
        NSLog(@"drawBegin *FAIL* dropping frame on the floor.");
        return 1;
    }
    
    [self setViewRect:CGRectMake(0, 0, myosd_video_width, myosd_video_height)];
    
    // walk the primitive list and render
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        
        VertexColor color = VertexColor(prim->color_r, prim->color_g, prim->color_b, prim->color_a);
        CGRect rect = CGRectMake(prim->bounds_x0, prim->bounds_y0, prim->bounds_x1 - prim->bounds_x0 + 1, prim->bounds_y1 - prim->bounds_y0 + 1);
        
        if (prim->type == RENDER_PRIMITIVE_QUAD && prim->texture_base != NULL) {
            
            // set the texture
            [self setTexture:0 texture:prim->texture_base hash:prim->texture_seqid
                       width:prim->texture_width height:prim->texture_height
                      format:(prim->texformat == TEXFORMAT_RGB15 ? MTLPixelFormatBGR5A1Unorm : MTLPixelFormatBGRA8Unorm)
                texture_load:texture_load texture_load_data:prim];
            
            // set the shader
            if (prim->screentex) {
                // render of the game screen.
                // [self setShader:ShaderTexture];
                // TODO: when the orientation is 90 or 270 we should flip the texture_height for the shader!!
                [self setShaderVariables:@{
                    @"target-width" :@(prim->bounds_x1 - prim->bounds_x0 + 1),
                    @"rarget-height":@(prim->bounds_y1 - prim->bounds_y0 + 1),
                    @"screen-width" :@(prim->texture_width),
                    @"screen-height":@(prim->texture_height),
                }];
                [self setShader:@"mame_screen_crt, frame-count, screen-width, screen-height, target-width, target-height"];
                //[self setShader:@"mame_screen_crt, frame-count, screen-width, screen-height, render-target-width, render-target-height"];
            }
            else {
                // render of non-game artwork.
                [self setShader:shader_tex_map[prim->blendmode]];
            }
            
            if (prim->texwrap)
                [self setTextureAddressMode:MTLSamplerAddressModeRepeat];
            else
                [self setTextureAddressMode:MTLSamplerAddressModeClampToEdge];

            // draw a quad in the correct orientation
            UIImageOrientation orientation = UIImageOrientationUp;
            if (prim->texorient == ORIENTATION_ROT90)
                orientation = UIImageOrientationRight;
            else if (prim->texorient == ORIENTATION_ROT180)
                orientation = UIImageOrientationDown;
            else if (prim->texorient == ORIENTATION_ROT270)
                orientation = UIImageOrientationLeft;

            [self drawRect:rect color:color orientation:orientation];
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD) {
            // solid color quad.
            [self setShader:shader_map[prim->blendmode]];
            [self drawRect:rect color:color];
        }
        else if (prim->type == RENDER_PRIMITIVE_LINE && prim->width <= 1) {
            // single pixel line.
            [self setShader:shader_map[prim->blendmode]];
            // TODO: make antialias lines work!
            if (prim->antialias)
                [self drawLine:rect.origin to:CGPointMake(prim->bounds_x1, prim->bounds_y1) color:color];
            else
                [self drawLine:rect.origin to:CGPointMake(prim->bounds_x1, prim->bounds_y1) color:color];
        }
        else if (prim->type == RENDER_PRIMITIVE_LINE) {
            // wide line.
            [self setShader:shader_map[prim->blendmode]];
            // TODO: make antialias lines work!
            if (prim->antialias)
                [self drawLine:rect.origin to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:prim->width color:color];
            else
                [self drawLine:rect.origin to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:prim->width color:color];
        }
        else {
            NSLog(@"Unknown RENDER_PRIMITIVE!");
            assert(FALSE);  // bad primitive
        }
    }
    
    [self drawEnd];
    
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
//      [X] width <= 1.0                MAME menu
//      [X] width  > 1.0                dkong artwork
//      [ ] antialias <= 1.0
//      [X] antialias  > 1.0            asteroid
//      [ ] blend mode NONE
//      [X] blend mode ALPHA            MAME menu
//      [ ] blend mode MULTIPLY
//      [X] blend mode ADD              asteroid
//
// QUADS
//      [X] blend mode NONE             MAME menu
//      [X] blend mode ALPHA            MAME menu
//      [ ] blend mode MULTIPLY
//      [X] blend mode ADD              dkong artwork
//
// TEXTURED QUADS
//      [X] blend mode NONE
//      [X] blend mode ALPHA            MAME menu (text)
//      [ ] blend mode MULTIPLY
//      [ ] blend mode ADD
//      [X] rotate 0                    MAME menu (text)
//      [X] rotate 90                   pacman
//      [ ] rotate 180
//      [ ] rotate 270
//      [X] texture WRAP                MAME menu
//      [X] texture CLAMP               MAME menu
//
// TEXTURE FORMATS
//      [X] PALETTE16                   pacman
//      [ ] PALETTEA16
//      [ ] RGB15
//      [ ] RGB32
//      [X] ARGB32                      MAME menu (text)
//      [ ] YUY16
//      [ ] RGB15 with PALETTE
//      [ ] RGB32 with PALETTE
//      [ ] ARGB32 with PALETTE
//      [ ] YUY16 with PALETTE
//
- (void)drawScreenDebug:(void*)prim_list {
    
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
            if (width <= 1.0 && !aa)
                assert(TRUE);
            if (width  > 1.0 && !aa)
                assert(TRUE);
            if (width <= 1.0 && aa)
                assert(FALSE);
            if (width  > 1.0 && aa)
                assert(TRUE);
            if (blend == BLENDMODE_NONE)
                assert(FALSE);
            if (blend == BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(TRUE);
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD && prim->texture_base == NULL) {
            if (blend == BLENDMODE_NONE)
                assert(TRUE);
            if (blend == BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(FALSE);
        }
        else if (prim->type == RENDER_PRIMITIVE_QUAD) {
            if (blend == BLENDMODE_NONE)
                assert(TRUE);
            if (blend == BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == BLENDMODE_ADD)
                assert(TRUE);
            
            if (orient == ORIENTATION_ROT0)
                assert(TRUE);
            if (orient == ORIENTATION_ROT90)
                assert(TRUE);
            if (orient == ORIENTATION_ROT180)
                assert(FALSE);
            if (orient == ORIENTATION_ROT270)
                assert(FALSE);
            
            if (wrap == 0)
                assert(TRUE);
            if (wrap == 1)
                assert(TRUE);

            if (fmt == TEXFORMAT_RGB15 && prim->texture_palette == NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_RGB32 && prim->texture_palette == NULL)
                assert(FALSE);
            if (fmt == TEXFORMAT_ARGB32 && prim->texture_palette == NULL)
                assert(TRUE);
            if (fmt == TEXFORMAT_YUY16 && prim->texture_palette == NULL)
                assert(FALSE);

            if (fmt == TEXFORMAT_PALETTE16 && prim->texture_palette != NULL)
                assert(TRUE);
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


