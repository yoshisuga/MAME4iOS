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
#import "MetalScreenView.h"
#import "libmame.h"

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

#pragma mark - TIMERS

//#define WANT_TIMERS
#import "Timer.h"

TIMER_INIT_BEGIN
TIMER_INIT(draw_screen)
TIMER_INIT(texture_load)
TIMER_INIT(texture_load_pal16)
TIMER_INIT(texture_load_rgb32)
TIMER_INIT(texture_load_rgb15)
TIMER_INIT(line_prim)
TIMER_INIT(quad_prim)
TIMER_INIT_END

#pragma mark - MetalScreenView

@implementation MetalScreenView {
    NSDictionary* _options;
    MTLSamplerMinMagFilter _filter;
    
    Shader _screen_shader;
    
    Shader _line_shader;
    CGFloat _line_width_scale;
    NSString* _line_width_scale_variable;
    BOOL _line_shader_wants_past_lines;
    
    NSTimeInterval _drawScreenStart;

    #define LINE_BUFFER_SIZE (8*1024)
    #define LINE_MAX_FADE_TIME 1.0
    myosd_render_primitive* _line_buffer;
    int _line_buffer_base;
    int _line_buffer_count;
}

#pragma mark - SCREEN SHADER and LINE SHADER Options

// SCREEN SHADER
//
// Metal shader string is of the form:
//        @"<Friendly Name>", @"<shader description>"
//
// the first shader in this list is used the *Default*
//
// NOTE: see MetalView.h for what a <shader description> is.
// in addition to the <shader description> in MetalView.h you can specify a named variable like so....
//
//      variable_name = <default value> <min value> <max value> <step value>
//          dont use commas to separate values, use spaces.
//          min, max, and step are all optional, and only effect the InfoHUD, MetalView ignores them.
//
//  the following variables are pre-defined by MetalView and MetalScreenView
//
//      frame-count             - current frame number, this will reset to zero from time to time (like on resize)
//      render-target-size      - size of the render target (in pixels)
//      mame-screen-dst-rect    - the size (in pixels) of the output quad
//      mame-screen-src-rect    - the size (in pixels) of the input SCREEN texture
//      mame-screen-size        - the size (in pixels) of the input SCREEN texture
//      mame-screen-matrix      - matrix to convert texture coordinates (u,v) to crt (x,scanline)
//
//  Presets are simply the @string without the key names, only numbers!
//
+ (NSArray*)screenShaders {
    return @[@"simpleTron", @"simpleCRT, mame-screen-dst-rect, mame-screen-src-rect,\
                            Vertical Curvature = 5.0 1.0 10.0 0.1,\
                            Horizontal Curvature = 4.0 1.0 10.0 0.1,\
                            Curvature Strength = 0.25 0.0 1.0 0.05,\
                            Light Boost = 1.3 0.1 3.0 0.1, \
                            Vignette Strength = 0.05 0.0 1.0 0.05,\
                            Zoom Factor = 1.0 0.01 5.0 0.1,\
                            Brightness Factor = 1.0 0.0 2.0",
             @"megaTron", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,\
                            Shadow Mask Type = 3.0 0.0 3.0 1.0,\
                            Shadow Mask Intensity = 0.5 0.0 1.0 0.05,\
                            Scanline Thinness = 0.7 0.0 1.0 0.05,\
                            Horizontal Scanline Blur = 1.8 1.0 10.0 0.05,\
                            CRT Curvature = 0.02 0.0 0.25 0.01,\
                            Use Trinitron-style Curvature = 0.0 0.0 1.0 1.0,\
                            CRT Corner Roundness = 3.0 2.0 11.0 1.0,\
                            CRT Gamma = 2.9 0.0 5.0 0.1",
             @"megaTron - Shadow Mask Strong", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,3.0,0.75,0.6,1.4,0.02,1.0,2.0,3.0",
             @"megaTron - Vertical Games (Use Linear Filter)", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,3.0,0.4,0.8,3.0,0.02,0.0,3.0,2.9",
             @"megaTron - Grille Mask", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,2.0,0.85,0.6,2.0,0.02,1.0,2.0,3.0",
             @"megaTron - Grille Mask Lite", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,1.0,0.6,0.6,1.6,0.02,1.0,2.0,2.8",
             @"megaTron - No Shadow Mask but Blurred", @"megaTron, mame-screen-src-rect, mame-screen-dst-rect,0.0,0.6,0.6,1.0,0.02,0.0,2.0,2.6",
             
             @"ulTron ", @"ultron,\
                        mame-screen-src-rect,\
                        mame-screen-dst-rect,\
                        Scanline Sharpness = -6.0 -20.0 0.0 1.0,\
                        Pixel Sharpness = -3.0 -20.0 0.0 1.0,\
                        Horizontal Curve = 0.031 0.0 0.125 0.01,\
                        Vertical Curve = 0.041 0.0 0.125 0.01,\
                        Dark Shadow Mask Strength = 0.5 0.0 2.0 0.1,\
                        Bright Shadow Mask Strength = 1.0 0.0 2.0 0.1,\
                        Shadow Mask Type = 3.0 0.0 4.0 1.0,\
                        Overal Brightness Boost = 1.0 0.0 2.0 0.05,\
                        Horizontal Phosphor Glow Softness = -1.5 -2.0 -0.5 0.1,\
                        Vertical Phosphor Glow Softness = -2.0 -4.0 -1.0 0.1,\
                        Glow Amount = 0.15 0.0 1.0 0.05,\
                        Phosphor Focus = 1.75 0.0 10.0 0.05",
             
             @"None", ShaderTexture,
             
#ifdef DEBUG
             @"Wombat1", @"mame_screen_test, mame-screen-size, frame-count, 1.0, 8.0, 8.0",
             @"Wombat2", @"mame_screen_test, mame-screen-size, frame-count, wombat_rate=2.0, wombat_u=16.0, wombat_v=16.0",
             @"Test (dot)", @"mame_screen_dot, mame-screen-matrix",
             @"Test (scanline)", @"mame_screen_line, mame-screen-matrix",
             @"Test (rainbow)", @"mame_screen_rainbow, mame-screen-matrix, frame-count, rainbow_h = 16.0 4.0 32.0 1.0, rainbow_speed = 1.0 1.0 16.0",
             @"Test (color)", @"texture, blend=copy, color-test-pattern=1 0 1 1, test-brightness-factor=1.0 1.0 4.0",
#endif
    ];
}

+ (NSArray*)screenShaderList {
    // return only the shader names, shaders will have a comma
    return [self.screenShaders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (self CONTAINS ',')"]];
}
+ (Shader)getScreenShader:(NSString*)name {
    NSInteger idx = [self.screenShaders indexOfObject:name];
    if (idx == NSNotFound) idx = 0;     // use the first shader as a default
    return self.screenShaders[idx + 1];
}




// LINE SHADER - a line shader is exactly like a screen shader.
//
// **EXCEPT** the first parameter of a line-shader is assumed to be the `line-width-scale`
//
// all line widths will be multiplied by `line-width-scale` before being converted to triangles
//
// when the line fragment shader is called, the following is set:
//
//      color.rgb is the line color
//      color.a is itterated from 1.0 on center line to 0.25 on the line edge.
//      texture.x is itterated along the length of the line 0 ... length (the length is in model cordinates)
//      texture.y is itterated along the width of the line, -1 .. +1, with 0 being the center line
//
//  the default line shader just uses the passed color and a blend mode of ADD.
//  so the default line shader depends on the color.a being ramped down to 0.25x and color.rgb being the line color.
//
//  PAST LINES
//
//  if a line shader specifies `line-time` as a parameter value, we will re-draw a buffer of past lines every frame.
//
//      `line-time` == 0.0  - lines for the current frame
//      `line-time` > 0.0   - lines for past frames (line-time is the number of seconds in the past)
//
+ (NSArray*)lineShaders {
    return @[
        @"lineTron", @"lineTron, blend=alpha, fade-width-scale=1.2 0.1 8, line-time, fade-falloff=3 1 8, fade-strength = 0.2 0.1 3.0 0.1",
             
        @"None", ShaderNone,

#ifdef DEBUG
        @"Dash",         @"mame_test_vector_dash, blend=add, width-scale=1.0 0.25 6.0, frame-count, length=25.0, speed=16.0",
        @"Dash (Fast)",  @"mame_test_vector_dash, blend=add, 1.0, frame-count, 15.0, 16.0",
        @"Dash (Slow)",  @"mame_test_vector_dash, blend=add, 1.0, frame-count, 15.0, 2.0",
                 
        @"Pulse",        @"mame_test_vector_pulse, blend=add, width-scale=1.0 0.25 6.0, frame-count, rate=2.0",
        @"Pulse (Fast)", @"mame_test_vector_pulse, blend=add, 1.0, frame-count, 0.5",
        @"Pulse (Slow)", @"mame_test_vector_pulse, blend=add, 1.0, frame-count, 2.0",

        @"Fade (Alpha)", @"mame_test_vector_fade, blend=alpha, fade-width-scale=1.2 1 8, line-time, fade-falloff=2 1 4, fade-strength = 0.5 0.1 3.0 0.1",
        @"Fade (Add)",   @"mame_test_vector_fade, blend=add,   fade-width-scale=1.2 1 8, line-time, fade-falloff=2 1 4, fade-strength = 0.5 0.1 3.0 0.1",
#endif
    ];
}
+ (NSArray*)lineShaderList {
    // return only the shader names, shaders will have a comma
    return [self.lineShaders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (self CONTAINS ',')"]];
}
+ (Shader)getLineShader:(NSString*)name {
    NSInteger idx = [self.lineShaders indexOfObject:name];
    if (idx == NSNotFound) idx = 0;     // use the first shader as a default
    return self.lineShaders[idx + 1];
}

+ (NSArray*)filterList {
    return @[kScreenViewFilterLinear, kScreenViewFilterNearest];
}

#pragma mark - MetalScreenView INIT

// split and trim a string
// TODO: move this to a common place??
static NSMutableArray* split(NSString* str, NSString* sep) {
    NSMutableArray* arr = [[str componentsSeparatedByString:sep] mutableCopy];
    for (int i=0; i<arr.count; i++)
        arr[i] = [arr[i] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    return arr;
}

- (void)setOptions:(NSDictionary *)options {
    _options = options;
    
#ifdef DEBUG
    // background color
    self.backgroundColor = UIColor.orangeColor;
#endif
    
    // set our framerate
    self.preferredFramesPerSecond = 60;
    
    // enable filtering (default to Linear)
    NSString* filter_string = _options[kScreenViewFilter];

    if ([filter_string isEqualToString:kScreenViewFilterNearest])
        _filter = MTLSamplerMinMagFilterNearest;
    else
        _filter = MTLSamplerMinMagFilterLinear;

    // get the shader to use when drawing the SCREEN, default to the 3 entry in the list (simpleTron).
    _screen_shader = [MetalScreenView getScreenShader:_options[kScreenViewScreenShader]];

    // get the shader to use when drawing VECTOR lines, default to lineTron
    _line_shader = [MetalScreenView getLineShader:_options[kScreenViewLineShader]];
    
    // see if the line shader wants past lines, ie does it list `line-time` in the parameter list.x
    _line_shader_wants_past_lines = [_line_shader rangeOfString:@"line-time"].length != 0;
    
    // parse the first param of the line shader to get the line width scale factor.
    // NOTE the first param can be a variable or a constant, support variables for the HUD.
    _line_width_scale = 1.0;
    _line_width_scale_variable = nil;
    NSArray* arr = split(_line_shader, @",");
    NSUInteger idx = 1; // skip first component that is the shader name.
    if (idx < arr.count && [arr[idx] hasPrefix:@"blend="])
        idx++;
    if (idx < arr.count && [arr[idx] floatValue] != 0.0)
        _line_width_scale = [arr[idx] floatValue];
    else if (idx < arr.count)
        _line_width_scale_variable = split(arr[idx],@"=").firstObject;
    
    NSLog(@"FILTER: %@", _filter == MTLSamplerMinMagFilterNearest ? @"NEAREST" : @"LINEAR");
    NSLog(@"SCREEN SHADER: %@", split(_screen_shader, @",").firstObject);
    NSLog(@"LINE SHADER: %@", split(_line_shader, @",").firstObject);
    NSLog(@"LINE SHADER WANTS PAST LINES: %@", _line_shader_wants_past_lines ? @"YES" : @"NO");
    if (_line_width_scale_variable != nil)
        NSLog(@"    width-scale: %@", _line_width_scale_variable);
    else
        NSLog(@"    width-scale: %0.3f", _line_width_scale);

    [self setNeedsLayout];
}

- (void)dealloc {
    if (_line_buffer != NULL)
        free(_line_buffer);
}

#pragma mark - LINE BUFFER

- (void)saveLine:(myosd_render_primitive*) line {
    NSParameterAssert(line->type == MYOSD_RENDER_PRIMITIVE_LINE);
    
    if (_line_buffer == NULL)
        _line_buffer = malloc(LINE_BUFFER_SIZE * sizeof(_line_buffer[0]));

    int i = (_line_buffer_base + _line_buffer_count + 1) % LINE_BUFFER_SIZE;
    
    _line_buffer[i] = *line;
    _line_buffer[i].texcoords[0].u = _drawScreenStart;

    if (_line_buffer_count < LINE_BUFFER_SIZE)
        _line_buffer_count++;
    else
        _line_buffer_base = (_line_buffer_base + 1) % LINE_BUFFER_SIZE;
}

- (void)drawPastLines {
    CGFloat line_time = CGFLOAT_MAX;
    
    for (int i=0; i<_line_buffer_count; i++) {
        myosd_render_primitive* prim = _line_buffer + (_line_buffer_base + i) % LINE_BUFFER_SIZE;
        
        // calculate how far back in time this line is....
        NSTimeInterval t = _drawScreenStart - prim->texcoords[0].u;

        // ignore lines from the future, or too far in the past
        if (t <= 0.0 || t > LINE_MAX_FADE_TIME)
            continue;
        
        if (line_time != t) {
            line_time = t;
            [self setShaderVariables:@{@"line-time": @(line_time)}];
        }
        
        VertexColor color = VertexColor(prim->color_r, prim->color_g, prim->color_b, prim->color_a);
        color = color * simd_make_float4(color.a, color.a, color.a, 1/color.a);     // pre-multiply alpha
        
        [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:(prim->width * _line_width_scale) color:color];
    }
}

#pragma mark - texture conversion

static void load_texture_prim(id<MTLTexture> texture, myosd_render_primitive* prim) {
    
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;

    #define TEMP_BUFFER_WIDTH  3840
    #define TEMP_BUFFER_HEIGHT 2160
    static unsigned short temp_buffer[TEMP_BUFFER_WIDTH * TEMP_BUFFER_HEIGHT * 2];

    NSCParameterAssert(texture.pixelFormat == MTLPixelFormatBGRA8Unorm);
    NSCParameterAssert(texture.width == prim->texture_width);
    NSCParameterAssert(texture.height == prim->texture_height);

    static char* texture_format_name[] = {"UNDEFINED", "PAL16", "PALA16", "555", "RGB", "ARGB", "YUV16"};
    texture.label = [NSString stringWithFormat:@"MAME %08lX:%d %dx%d %s", (NSUInteger)prim->texture_base, prim->texture_seqid, prim->texture_width, prim->texture_height, texture_format_name[prim->texformat]];

    TIMER_START(texture_load);

    switch (prim->texformat) {
        case MYOSD_TEXFORMAT_RGB15:
        {
            // map 0-31 -> 0-255
            static uint32_t pal_ident[32] = {0,8,16,24,32,41,49,57,65,74,82,90,98,106,115,123,131,139,148,156,164,172,180,189,197,205,213,222,230,238,246,255};
            TIMER_START(texture_load_rgb15);
            uint16_t* src = prim->texture_base;
            uint32_t* dst = (uint32_t*)temp_buffer;
            const uint32_t* pal = prim->texture_palette ?: pal_ident;
            for (NSUInteger y=0; y<height; y++) {
                for (NSUInteger x=0; x<width; x++) {
                    uint16_t u16 = *src++;
                    *dst++ = (pal[(u16 >>  0) & 0x1F] >>  0) |
                             (pal[(u16 >>  5) & 0x1F] <<  8) |
                             (pal[(u16 >> 10) & 0x1F] << 16) |
                             0xFF000000;
                }
                src += prim->texture_rowpixels - width;
            }
            TIMER_STOP(texture_load_rgb15);
            [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:temp_buffer bytesPerRow:width*4];
            break;
        }
        case MYOSD_TEXFORMAT_RGB32:
        case MYOSD_TEXFORMAT_ARGB32:
        {
            TIMER_START(texture_load_rgb32);
            if (prim->texture_palette == NULL) {
                [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:prim->texture_base bytesPerRow:prim->texture_rowpixels*4];
            }
            else {
                uint32_t* src = prim->texture_base;
                uint32_t* dst = (uint32_t*)temp_buffer;
                const uint32_t* pal = prim->texture_palette;
                for (NSUInteger y=0; y<height; y++) {
                    for (NSUInteger x=0; x<width; x++) {
                        uint32_t rgba = *src++;
                        *dst++ = (pal[(rgba >>  0) & 0xFF] <<  0) |
                                 (pal[(rgba >>  8) & 0xFF] <<  8) |
                                 (pal[(rgba >> 16) & 0xFF] << 16) |
                                 (pal[(rgba >> 24) & 0xFF] << 24) ;
                    }
                    src += prim->texture_rowpixels - width;
                }
                [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:temp_buffer bytesPerRow:width*4];
            }
            TIMER_STOP(texture_load_rgb32);
            break;
        }
        case MYOSD_TEXFORMAT_PALETTE16:
        case MYOSD_TEXFORMAT_PALETTEA16:
        {
            TIMER_START(texture_load_pal16);
            uint16_t* src = prim->texture_base;
            uint32_t* dst = (uint32_t*)temp_buffer;
            const uint32_t* pal = prim->texture_palette;
            for (NSUInteger y=0; y<height; y++) {
                NSUInteger dx = width;
                if ((intptr_t)dst % 8 == 0) {
                    while (dx >= 4) {
                        uint64_t u64 = *(uint64_t*)src;
                        ((uint64_t*)dst)[0] = ((uint64_t)pal[(u64 >>  0) & 0xFFFF]) | (((uint64_t)pal[(u64 >> 16) & 0xFFFF]) << 32);
                        ((uint64_t*)dst)[1] = ((uint64_t)pal[(u64 >> 32) & 0xFFFF]) | (((uint64_t)pal[(u64 >> 48) & 0xFFFF]) << 32);
                        dst += 4; src += 4; dx -= 4;
                    }
                    if (dx >= 2) {
                        uint32_t u32 = *(uint32_t*)src;
                        ((uint64_t*)dst)[0] = ((uint64_t)pal[(u32 >>  0) & 0xFFFF]) | (((uint64_t)pal[(u32 >> 16) & 0xFFFF]) << 32);
                        dst += 2; src += 2; dx -= 2;
                    }
                }
                while (dx-- > 0)
                    *dst++ = pal[*src++];
                src += prim->texture_rowpixels - width;
            }
            TIMER_STOP(texture_load_pal16);
            [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:temp_buffer bytesPerRow:width*4];
            break;
        }
        case MYOSD_TEXFORMAT_YUY16:
        {
            // this texture format is only used for AVI files and LaserDisc player!
            NSCParameterAssert(FALSE);
            break;
        }
        default:
            NSCParameterAssert(FALSE);
            break;
    }
    TIMER_STOP(texture_load);
}

#pragma mark - draw MAME primitives

// NOTE this is called on MAME background thread, dont do anything stupid.
- (void)drawScreen:(void*)prim_list size:(CGSize)size {
    static Shader shader_map[] = {ShaderNone, ShaderAlpha, ShaderMultiply, ShaderAdd};
    static Shader shader_tex_map[]  = {ShaderTexture, ShaderTextureAlpha, ShaderTextureMultiply, ShaderTextureAdd};

#ifdef DEBUG
    [self drawScreenDebug:prim_list];
#endif
    
    if (![self drawBegin]) {
        NSLog(@"drawBegin *FAIL* dropping frame on the floor.");
        return;
    }
    _drawScreenStart = CACurrentMediaTime();
    TIMER_START(draw_screen);

    [self setViewRect:CGRectMake(0, 0, size.width, size.height)];
    
    CGFloat scale_x = self.drawableSize.width  / size.width;
    CGFloat scale_y = self.drawableSize.height / size.height;
    CGFloat scale   = MIN(scale_x, scale_y);
    
    // get the line width scale for this frame, if it is variable.
    if (_line_width_scale_variable != nil) {
        NSValue* val = [self getShaderVariables][_line_width_scale_variable];
        if (val != nil && [val isKindOfClass:[NSNumber class]])
            _line_width_scale = [(NSNumber*)val floatValue];
    }
    
    BOOL first_line = TRUE;
    
    // prim_list == NULL means erase
    if (prim_list == NULL) {
        VertexColor color = VertexColor(0, 0, 0, 1);
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        [self setShader:ShaderCopy];
        [self drawRect:rect color:color];
    }
    
    // walk the primitive list and render
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        
        if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD)
            TIMER_START(quad_prim);
        else
            TIMER_START(line_prim);

        VertexColor color = VertexColor(prim->color_r, prim->color_g, prim->color_b, prim->color_a);
        
        CGRect rect = CGRectMake(floor(prim->bounds_x0 + 0.5),  floor(prim->bounds_y0 + 0.5),
                                 floor(prim->bounds_x1 + 0.5) - floor(prim->bounds_x0 + 0.5),
                                 floor(prim->bounds_y1 + 0.5) - floor(prim->bounds_y0 + 0.5));

        if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD && prim->texture_base != NULL) {
            
            // set the texture
            [self setTexture:0 texture:prim->texture_base hash:prim->texture_seqid
                       width:prim->texture_width height:prim->texture_height
                      format:MTLPixelFormatBGRA8Unorm
                texture_load:^(id<MTLTexture> texture) {load_texture_prim(texture, prim);} ];

            // set the shader
            if (prim->screentex) {
                // render of the game screen, use a custom shader
                // set the following shader variables so the shader knows the pixel size of a scanline etc....
                //
                //      mame-screen-dst-rect - the size (in pixels) of the output quad
                //      mame-screen-src-rect - the size (in pixels) of the input texture
                //      mame-screen-size     - the size (in pixels) of the input texture
                //      mame-screen-matrix   - matrix to convert texture coordinates (u,v) to crt (x,scanline)
                //
                CGSize src_size = CGSizeMake((prim->texorient & MYOSD_ORIENTATION_SWAP_XY) ? prim->texture_height : prim->texture_width,
                                             (prim->texorient & MYOSD_ORIENTATION_SWAP_XY) ? prim->texture_width : prim->texture_height);
                
                CGRect src_rect = CGRectMake(0, 0, src_size.width, src_size.height);
                CGRect dst_rect = CGRectMake(rect.origin.x * scale_x, rect.origin.y * scale_y, rect.size.width * scale_x, rect.size.height * scale_y);
                
                // create a matrix to convert texture coordinates (u,v) to crt scanlines (x,y)
                simd_float2x2 mame_screen_matrix;
                if (prim->texorient & MYOSD_ORIENTATION_SWAP_XY)
                    mame_screen_matrix = (matrix_float2x2){{ {0,prim->texture_width}, {prim->texture_height,0} }};
                else
                    mame_screen_matrix = (matrix_float2x2){{ {prim->texture_width,0}, {0,prim->texture_height} }};
                
                [self setShaderVariables:@{
                    @"mame-screen-dst-rect" :@(dst_rect),
                    @"mame-screen-src-rect" :@(src_rect),
                    @"mame-screen-size"     :@(src_size),
                    @"mame-screen-matrix"   :[NSValue value:&mame_screen_matrix withObjCType:@encode(float[2][2])],
                }];
                [self setTextureFilter:_filter];
                [self setShader:_screen_shader];
            }
            else {
                // render of artwork (or mame text). use normal shader with no filtering
                [self setTextureFilter:MTLSamplerMinMagFilterNearest];
                [self setShader:shader_tex_map[prim->blendmode]];
            }
            
            // set the address mode.
            if (prim->texwrap)
                [self setTextureAddressMode:MTLSamplerAddressModeRepeat];
            else
                [self setTextureAddressMode:MTLSamplerAddressModeClampToZero];

            // draw a textured rect.
            [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:(Vertex2D[]){
                Vertex2D(rect.origin.x,                  rect.origin.y,                   prim->texcoords[0].u,prim->texcoords[0].v,color),
                Vertex2D(rect.origin.x + rect.size.width,rect.origin.y,                   prim->texcoords[1].u,prim->texcoords[1].v,color),
                Vertex2D(rect.origin.x,                  rect.origin.y + rect.size.height,prim->texcoords[2].u,prim->texcoords[2].v,color),
                Vertex2D(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height,prim->texcoords[3].u,prim->texcoords[3].v,color),
            } count:4];
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD) {
            // solid color quad. only ALPHA or NONE blend mode.
            
            if (prim->blendmode != MYOSD_BLENDMODE_ALPHA || prim->color_a == 1.0) {
                [self setShader:ShaderNone];
                [self drawRect:rect color:color];
            }
            else if (prim->color_a != 0.0) {
                [self setShader:ShaderAlpha];
                [self drawRect:rect color:color];
            }
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_LINE && (prim->width * scale) <= 1.0) {
            // single pixel line.
            [self setShader:shader_map[prim->blendmode]];
            [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) color:color];
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_LINE) {
            // wide line, if the blendmode is ADD this is a VECTOR line, else a UI line.
            if (prim->blendmode == MYOSD_BLENDMODE_ADD && _line_shader != ShaderNone) {
                // this line is a vector line, use a special shader

                // pre-multiply color, so shader has non-iterated color
                color = color * simd_make_float4(color.a, color.a, color.a, 1/color.a);
                [self setShader:_line_shader];

                // handle lines from the past.
                if (_line_shader_wants_past_lines) {
                    // first time we see a line, draw all old lines, and set line-time=0.0
                    if (first_line) {
                        first_line = FALSE;
                        [self drawPastLines];
                        [self setShaderVariables:@{@"line-time": @(0.0)}];
                    }
                    [self saveLine:prim];

                    [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:prim->width color:color edgeAlpha:0.0];
                }
                else {
                    [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:(prim->width * _line_width_scale) color:color];
                }
            }
            else {
                // this line is from MAME UI, draw normal
                [self setShader:shader_map[prim->blendmode]];
                
                if (prim->blendmode == MYOSD_BLENDMODE_NONE)
                    [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:prim->width color:color];
                else
                    [self drawLine:CGPointMake(prim->bounds_x0, prim->bounds_y0) to:CGPointMake(prim->bounds_x1, prim->bounds_y1) width:prim->width color:color edgeAlpha:0.0];
            }
        }
        else {
            NSLog(@"Unknown RENDER_PRIMITIVE!");
            NSParameterAssert(FALSE);  // bad primitive
        }
        
        if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD)
            TIMER_STOP(quad_prim);
        else
            TIMER_STOP(line_prim);
    }
    
#ifdef DEBUG
    if ([_screen_shader containsString:@"color-test-pattern"] && [(id)self.getShaderVariables[@"color-test-pattern"] boolValue]) {
        [self drawTestPattern:CGRectMake(0, 0, size.width, size.height)];
    }
#endif
    
    [self drawEnd];
    TIMER_STOP(draw_screen);
}

#pragma mark - TEST PATTERN

#ifdef DEBUG
#undef NSLog

// COLOR MATCH a CGColor
simd_float4 ColorMatchCGColor(CGColorSpaceRef destColorSpace, CGColorRef sourceColor) {
    CGColorRef destColor = CGColorCreateCopyByMatchingToColorSpace(destColorSpace, kCGRenderingIntentDefault, sourceColor, NULL);
    const CGFloat* c = CGColorGetComponents(destColor);
    simd_float4 color = simd_make_float4(c[0], c[1], c[2], c[3]);
    CGColorRelease(destColor);
    return color;
}
// COLOR MATCH a SIMD Color
simd_float4 ColorMatch(CGColorSpaceRef destColorSpace, CGColorSpaceRef sourceColorSpace, simd_float4 color) {
    CGFloat rgba[] = {color.r,color.g,color.b,color.a};
    CGColorRef sourceSolor = CGColorCreate(sourceColorSpace, rgba);
    return ColorMatchCGColor(destColorSpace, sourceSolor);
}

-(void)drawGradientRect:(CGRect)rect color:(simd_float4)color0 color:(simd_float4)color1 steps:(int)steps {
    CGFloat w = rect.size.width / steps;
    CGFloat h = rect.size.height;
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    
    for (int i=0; i<steps; i++) {
        float f = (float)i / (float)(steps-1);
        simd_float4 color = color0 + f * (color1 - color0);
        [self drawRect:CGRectMake(x, y, w, h) color:color];
        x += w;
    }
}

-(void)drawTestPattern:(CGRect)rect {
    CGFloat width = rect.size.width;
    
    float factor = [(id)self.getShaderVariables[@"test-brightness-factor"] floatValue];
    simd_float4 brightness = simd_make_float4(factor, factor, factor, 1);
    
    static CGColorSpaceRef displayP3, extendedSRGB;
    
    if (displayP3 == NULL) {
        displayP3 = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
        extendedSRGB = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    }

    simd_float4 colors[] = {simd_make_float4(1, 0, 0, 1), simd_make_float4(0, 1, 0, 1), simd_make_float4(0, 0, 1, 1), simd_make_float4(1, 1, 0, 1), simd_make_float4(1, 1, 1, 1)};
    int n = sizeof(colors)/sizeof(colors[0]);
    
    static int g_foo;
    if (g_foo++ == 0) {
        for (int i=0; i<n; i++) {
            simd_float4 color_p3 = colors[i];
            simd_float4 color_srgb = ColorMatch(extendedSRGB, displayP3, color_p3);
            NSLog(@"displayP3(%f,%f,%f) ==> extendedSRGB(%f,%f,%f)",
                  color_p3.r, color_p3.g, color_p3.b,
                  color_srgb.r, color_srgb.g, color_srgb.b);
        }
        
        if (@available(iOS 13.4, tvOS 13.4, *)) {
            NSLog(@"");
            CGColorSpaceRef rec2020 = CGColorSpaceCreateWithName(kCGColorSpaceITUR_2020_PQ);
            for (int i=0; i<n; i++) {
                simd_float4 color = colors[i];
                simd_float4 color_srgb = ColorMatch(extendedSRGB, rec2020, color);
                NSLog(@"rec2020_PQ(%f,%f,%f) ==> extendedSRGB(%f,%f,%f)",
                      color.r, color.g, color.b,
                      color_srgb.r, color_srgb.g, color_srgb.b);
            }
            CGColorSpaceRelease(rec2020);
        }
        
        if (@available(iOS 13.4, tvOS 13.4, *)) {
            NSLog(@"");
            CGColorSpaceRef hlg = CGColorSpaceCreateWithName(kCGColorSpaceITUR_2020_HLG);
            for (int i=0; i<n; i++) {
                simd_float4 color = colors[i];
                simd_float4 color_srgb = ColorMatch(extendedSRGB, hlg, color);
                NSLog(@"rec2020_HLG(%f,%f,%f) ==> extendedSRGB(%f,%f,%f)",
                      color.r, color.g, color.b,
                      color_srgb.r, color_srgb.g, color_srgb.b);
            }
            CGColorSpaceRelease(hlg);
        }
    }

    CGFloat space_x = width / 32;
    CGFloat space_y = width / 32;
    CGFloat y = 0;
    CGFloat x = 0;
    CGFloat w = (width - (n-1) * space_x) / n;
    CGFloat h = w/2;

    // draw rects via polygons
    x = 0;
    y += space_y;
    [self setShader:ShaderCopy];
    for (int i=0; i<n; i++) {
        simd_float4 color0 = ColorMatch(self.colorSpace, extendedSRGB, colors[i]);
        simd_float4 color1 = ColorMatch(self.colorSpace, displayP3, colors[i]);
        [self drawRect:CGRectMake(x,y,w,h) color:color0 * brightness];
        [self drawRect:CGRectMake(x+w/3,y+h/3,w/3,h/3) color:color1];
        x += w + space_x;
    }
    y += h;
    
    // draw rects as P3 textures.
    x = 0;
    y += space_y;
    for (int i=0; i<sizeof(colors)/sizeof(colors[0]); i++) {
        simd_float4 color = colors[i];
        
        [self setShader:ShaderTextureAlpha];
        [self setTextureFilter:MTLSamplerMinMagFilterNearest];
        NSString* ident = [NSString stringWithFormat:@"TestP3%d", i];
        
        [self setTexture:0 texture:(void*)ident hash:0 width:3 height:3 format:MTLPixelFormatBGRA8Unorm colorspace:displayP3 texture_load:^(id<MTLTexture> texture) {
            
            simd_float4 c0 = ColorMatch(displayP3, displayP3,    color); // P3 -> P3 (should be a NOOP)
            simd_float4 c1 = ColorMatch(displayP3, extendedSRGB, color); // sRGB -> P3
            
            uint32_t dw0 = 0xFF000000 |
                ((uint32_t)(c0.r * 255.0) << 16) |
                ((uint32_t)(c0.g * 255.0) << 8) |
                ((uint32_t)(c0.b * 255.0) << 0);

            uint32_t dw1 = 0xFF000000 |
                ((uint32_t)(c1.r * 255.0) << 16) |
                ((uint32_t)(c1.g * 255.0) << 8) |
                ((uint32_t)(c1.b * 255.0) << 0);

            uint32_t rgb[3*3];
            for (int i=0; i<3*3; i++)
                rgb[i] = i==4 ? dw0 : dw1;
            [texture replaceRegion:MTLRegionMake2D(0, 0, 3, 3) mipmapLevel:0 withBytes:rgb bytesPerRow:3*4];
            texture.label = @"TestP3";
        }];

        [self drawRect:CGRectMake(x,y,w,h) color:simd_make_float4(1, 1, 1, 1)];
        x += w + space_x;
    }
    y += h;

    // draw RGB gradients in SRGB and P3.
    h = width/16;
    w = width/2;
    x = 0;
    y += space_y;
    [self setShader:ShaderCopy];
    for (int i=0; i<sizeof(colors)/sizeof(colors[0]); i++) {
        simd_float4 color0 = ColorMatch(self.colorSpace, extendedSRGB, colors[i]) * brightness;
        simd_float4 color1 = ColorMatch(self.colorSpace, displayP3, colors[i]);
        [self drawGradientRect:CGRectMake(x,y,w,h)   color:VertexColor(0, 0, 0, 1) color:color0 orientation:UIImageOrientationRight];
        [self drawGradientRect:CGRectMake(x+w,y,w,h) color:VertexColor(0, 0, 0, 1) color:color1 orientation:UIImageOrientationLeft];
        y += h;
    }
    
    // draw RGB gradients.
    h = width/16;
    w = width;
    x = 0;
    y += space_y;
    [self setShader:ShaderCopy];
    for (int i=0; i<sizeof(colors)/sizeof(colors[0]); i++) {
        simd_float4 color0 = ColorMatch(self.colorSpace, extendedSRGB, colors[i]) * brightness;
        simd_float4 color1 = ColorMatch(self.colorSpace, displayP3, colors[i]);
        [self drawGradientRect:CGRectMake(x,y,w,h)       color:color0 * 0.5 color:color0 steps:16];
        [self drawGradientRect:CGRectMake(x,y+h/2,w,h/2) color:color1 * 0.5 color:color1 steps:16];
        y += h;
    }

    // draw some text
    h = width/32;
    w = width;
    x = 0;
    y += space_y;
    for (int i=0; i<sizeof(colors)/sizeof(colors[0]); i++) {
        simd_float4 color = ColorMatch(self.colorSpace, extendedSRGB, colors[i]) * brightness;
        NSString* text = @"ABCabc ";
        [self drawText:text at:CGPointMake(x, y) height:h color:color];
        x += [self sizeText:text height:h].width;
    }
}
#endif

#pragma mark - CODE COVERAGE and DEBUG stuff

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
//      [X] antialias <= 1.0            asteroid (slider menu, adjust beam width)
//      [X] antialias  > 1.0            asteroid
//      [ ] blend mode NONE
//      [X] blend mode ALPHA            MAME menu
//      [ ] blend mode MULTIPLY
//      [X] blend mode ADD              asteroid
//
// QUADS
//      [X] blend mode NONE             MAME menu
//      [X] blend mode ALPHA            MAME menu
//      [X] blend mode MULTIPLY         N/A
//      [X] blend mode ADD              N/A
//
// TEXTURED QUADS
//      [X] blend mode NONE
//      [X] blend mode ALPHA            MAME menu (text)
//      [X] blend mode MULTIPLY         bzone
//      [X] blend mode ADD              dkong artwork
//      [X] rotate 0                    MAME menu (text)
//      [X] rotate 90                   pacman
//      [X] rotate 180                  mario, cocktail
//      [X] rotate 270                  mario, cocktail.
//      [X] flip X                      othunder
//      [X] flip Y                      lethalen
//      [X] swap XY                     kick
//      [ ] swap XY + flip X + flip Y   
//      [X] texture WRAP                MAME menu
//      [X] texture CLAMP               MAME menu
//
// TEXTURE FORMATS
//      [X] PALETTE16                   pacman
//      [ ] PALETTEA16
//      [X] RGB15                       megaplay, streets of rage II
//      [X] RGB32                       neogeo
//      [X] ARGB32                      MAME menu (text)
//      [-] YUY16                       N/A
//      [X] RGB15 with PALETTE          megaplay
//      [X] RGB32 with PALETTE          neogeo
//      [-] ARGB32 with PALETTE         N/A
//      [-] YUY16 with PALETTE          N/A
//
- (void)drawScreenDebug:(void*)prim_list {
    
    for (myosd_render_primitive* prim = prim_list; prim != NULL; prim = prim->next) {
        
        assert(prim->type == MYOSD_RENDER_PRIMITIVE_LINE || prim->type == MYOSD_RENDER_PRIMITIVE_QUAD);
        assert(prim->blendmode <= MYOSD_BLENDMODE_ADD);
        assert(prim->texformat <= MYOSD_TEXFORMAT_YUY16);
        assert(prim->texture_base == NULL || prim->texformat != MYOSD_TEXFORMAT_UNDEFINED);
        assert(prim->unused == 0);

        float width = prim->width;
        int blend = prim->blendmode;
        int fmt = prim->texformat;
        int aa = prim->antialias;
        int orient = prim->texorient;
        int wrap = prim->texwrap;

        if (prim->type == MYOSD_RENDER_PRIMITIVE_LINE) {
            if (width <= 1.0 && !aa)
                assert(TRUE);
            if (width  > 1.0 && !aa)
                assert(TRUE);
            if (width <= 1.0 && aa)
                assert(TRUE);
            if (width  > 1.0 && aa)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_NONE)
                assert(FALSE);
            if (blend == MYOSD_BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_RGB_MULTIPLY)
                assert(FALSE);
            if (blend == MYOSD_BLENDMODE_ADD)
                assert(TRUE);
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD && prim->texture_base == NULL) {
            if (blend == MYOSD_BLENDMODE_NONE)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_RGB_MULTIPLY)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_ADD)
                assert(TRUE);
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD) {
            if (blend == MYOSD_BLENDMODE_NONE)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_ALPHA)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_RGB_MULTIPLY)
                assert(TRUE);
            if (blend == MYOSD_BLENDMODE_ADD)
                assert(TRUE);
            
            if (orient == MYOSD_ORIENTATION_ROT0)
                assert(TRUE);
            if (orient == MYOSD_ORIENTATION_ROT90)
                assert(TRUE);
            if (orient == MYOSD_ORIENTATION_ROT180)
                assert(TRUE);
            if (orient == MYOSD_ORIENTATION_ROT270)
                assert(TRUE);
            
            if (orient == MYOSD_ORIENTATION_FLIP_X)
                assert(TRUE);
            if (orient == MYOSD_ORIENTATION_FLIP_Y)
                assert(TRUE);
            if (orient == MYOSD_ORIENTATION_SWAP_XY)
                assert(TRUE);
            if (orient == (MYOSD_ORIENTATION_SWAP_XY | MYOSD_ORIENTATION_FLIP_X | MYOSD_ORIENTATION_FLIP_Y))
                assert(FALSE);

            if (wrap == 0)
                assert(TRUE);
            if (wrap == 1)
                assert(TRUE);

            if (fmt == MYOSD_TEXFORMAT_RGB15 && prim->texture_palette == NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_RGB32 && prim->texture_palette == NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_ARGB32 && prim->texture_palette == NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_YUY16 && prim->texture_palette == NULL)
                assert(FALSE);

            if (fmt == MYOSD_TEXFORMAT_PALETTE16 && prim->texture_palette != NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_PALETTEA16 && prim->texture_palette != NULL)
                assert(FALSE);
            if (fmt == MYOSD_TEXFORMAT_RGB15 && prim->texture_palette != NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_RGB32 && prim->texture_palette != NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_ARGB32 && prim->texture_palette != NULL)
                assert(TRUE);
            if (fmt == MYOSD_TEXFORMAT_YUY16 && prim->texture_palette != NULL)
                assert(FALSE);
        }
    }
}
#endif

// code to DEBUG dump the current screen
#ifdef DEBUG
#undef NSLog

- (void)dumpScreen:(void*)primitives size:(CGSize)size {
    
    static char* texture_format_name[] = {"UNDEFINED", "PAL16", "PALA16", "555", "RGB", "ARGB", "YUV16"};
    static char* blend_mode_name[] = {"NONE", "ALPHA", "MUL", "ADD"};
    
    // DUMP TIMERS....
    TIMER_DUMP();
    TIMER_RESET();
    
    NSLog(@"Draw Screen: %dx%d",(int)size.width,(int)size.height);
    
    for (myosd_render_primitive* prim = primitives; prim != NULL; prim = prim->next) {
        
        NSParameterAssert(prim->type == MYOSD_RENDER_PRIMITIVE_LINE || prim->type == MYOSD_RENDER_PRIMITIVE_QUAD);
        NSParameterAssert(prim->blendmode <= MYOSD_BLENDMODE_ADD);
        NSParameterAssert(prim->texformat <= MYOSD_TEXFORMAT_YUY16);
        NSParameterAssert(prim->unused == 0);
        
        int blend = prim->blendmode;
        int fmt = prim->texformat;
        int aa = prim->antialias;
        int screen = prim->screentex;
        int orient = prim->texorient;
        int wrap = prim->texwrap;
        
        if (prim->type == MYOSD_RENDER_PRIMITIVE_LINE) {
            NSLog(@"    LINE (%.0f,%.0f) -> (%.0f,%.0f) (%0.2f,%0.2f,%0.2f,%0.2f) %f %s%s%s",
                  prim->bounds_x0, prim->bounds_y0, prim->bounds_x1, prim->bounds_y1,
                  prim->color_r, prim->color_g, prim->color_b, prim->color_a,
                  prim->width, blend_mode_name[blend], aa ? " AA" : "", screen ? " SCREEN" : "");
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD && prim->texture_base == NULL) {
            NSLog(@"    QUAD [%.0f,%.0f,%.0f,%.0f] (%0.2f,%0.2f,%0.2f,%0.2f) %s%s",
                  prim->bounds_x0, prim->bounds_y0, prim->bounds_x1 - prim->bounds_x0, prim->bounds_y1 - prim->bounds_y0,
                  prim->color_r, prim->color_g, prim->color_b, prim->color_a,
                  blend_mode_name[blend], aa ? " AA" : "");
        }
        else if (prim->type == MYOSD_RENDER_PRIMITIVE_QUAD) {
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
                  (orient & MYOSD_ORIENTATION_FLIP_X) ? " FLIPX" : "",
                  (orient & MYOSD_ORIENTATION_FLIP_Y) ? " FLIPY" : "",
                  (orient & MYOSD_ORIENTATION_SWAP_XY) ? " SWAPXY" : ""
                  );
        }
    }
}
#endif

@end


