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
struct MameScreenUniforms {
    float           frame_num;
    packed_float2   screen_size;    // size of the mame screen/texture
    packed_float2   target_size;    // size of output quad
};
fragment half4
mame_screen_crt(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler texture_sampler [[sampler(0)]],
                constant MameScreenUniforms &uniforms [[buffer(0)]])
{
    float2 screen_size = uniforms.screen_size;
    float  t = (uniforms.frame_num / 60.0) * 2.0 * M_PI_F;
    float2 uv = float2(v.tex.x + sin(t/2) * (8.0 / screen_size.x) , v.tex.y);
    float4 color = texture.sample(texture_sampler, uv) * v.color;
    return half4(color);
}




