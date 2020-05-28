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
    float frame_num;
    float factor;
    float2 render_target_size;    // sizeof the render target
    float4 mame_screen_dst_rect;  // height of the mame screen
    float4 mame_screen_src_rect;  // height of the mame screen texture
};
fragment half4
mame_screen_test(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler texture_sampler [[sampler(0)]],
                constant MameScreenTestUniforms &uniforms [[buffer(0)]])
{
    // ignore teh passed in sampler, and use our own
    constexpr sampler linear_texture_sampler(mag_filter::linear, min_filter::linear);
    
    float  t = (uniforms.frame_num / 60.0) * 2.0 * M_PI_F;
    float2 uv = float2(v.tex.x + sin(t/2) * uniforms.factor * (1.0 / uniforms.mame_screen_src_rect.w), v.tex.y);
    float4 color = texture.sample(linear_texture_sampler, uv) * v.color;
    return half4(color);
}






