//
//  MameShaders.metal
//  Wombat
//
//  Created by Todd Laney on 5/18/20.
//  Copyright © 2020 Wombat. All rights reserved.
//
#include <metal_stdlib>
#import "MetalViewShaders.h"

using namespace metal;

// Shader to draw the MAME game SCREEN....
struct MameScreenTestUniforms {
    float2 mame_screen_size;
    float frame_num;
    float rate;
    float factor_u;
    float factor_v;
};
fragment half4
mame_screen_test(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler texture_sampler [[sampler(0)]],
                constant MameScreenTestUniforms &uniforms [[buffer(0)]])
{
    // ignore the passed in sampler, and use our own
    constexpr sampler linear_texture_sampler(mag_filter::linear, min_filter::linear);
    
    float  t = (uniforms.frame_num / 60.0) * uniforms.rate * 2.0 * M_PI_F;
    float2 uv = float2(v.tex.x + cos(t) * uniforms.factor_u * (1.0 / uniforms.mame_screen_size.x),
                       v.tex.y + sin(t) * uniforms.factor_v * (1.0 / uniforms.mame_screen_size.y));
    float4 color = texture.sample(linear_texture_sampler, uv) * v.color;
    return half4(color);
}


// Shader to draw the MAME game SCREEN....
struct MameScreenDotUniforms {
    float2x2 mame_screen_matrix;  // matrix to convert texture coordinates (u,v) to crt scanlines (x,y)
};
fragment float4
mame_screen_dot(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler tsamp [[sampler(0)]],
                constant MameScreenDotUniforms &uniforms [[buffer(0)]])
{
    float2 uv = uniforms.mame_screen_matrix * v.tex;
    float2 xy = fract(uv)*2 - float2(1,1);
    float  f = 1.0 - min(1.0, length(xy));
    float4 color = texture.sample(tsamp, v.tex) * f;
    return color;
}

// Shader to draw the MAME game SCREEN....
struct MameScreenLineUniforms {
    float2x2 mame_screen_matrix;  // matrix to convert texture coordinates (u,v) to crt scanlines (x,y)
};
fragment float4
mame_screen_line(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler tsamp [[sampler(0)]],
                constant MameScreenLineUniforms &uniforms [[buffer(0)]])
{
    float2 uv = uniforms.mame_screen_matrix * v.tex;
    float  y = fract(uv.y)*2 - 1;
    float  f = cos(y * M_PI_F * 0.5);
    float4 color = texture.sample(tsamp, v.tex) * f;
    return color;
}

constant float4 six_colors[] = {
    float4(94, 189, 62, 255),
    float4(255, 185, 0, 255),
    float4(247, 130, 0, 255),
    float4(226, 56, 56, 255),
    float4(151, 57, 153, 255),
    float4(0, 156, 223, 255),
};

// Shader to draw the MAME game SCREEN....
struct MameScreenRainbowUniforms {
    float2x2 mame_screen_matrix;  // matrix to convert texture coordinates (u,v) to crt scanlines (x,y)
    float    frame_count;
    float    rainbow_height;
    float    rainbow_speed;
};
fragment float4
mame_screen_rainbow(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler tsamp [[sampler(0)]],
                constant MameScreenRainbowUniforms &uniforms [[buffer(0)]])
{
    float2 uv = uniforms.mame_screen_matrix * v.tex;
    float4 shade = six_colors[(int)(uv.y/uniforms.rainbow_height + uniforms.frame_count/60 * uniforms.rainbow_speed) % 6] * float4(1.0/255.0);
    float4 color = (texture.sample(tsamp, v.tex) + shade) * 0.5;
    return color;
}












