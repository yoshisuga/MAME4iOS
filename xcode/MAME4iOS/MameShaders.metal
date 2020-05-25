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
    float screen_height;  // height of the mame screen/texture
};
fragment half4
mame_screen_test(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler texture_sampler [[sampler(0)]],
                constant MameScreenTestUniforms &uniforms [[buffer(0)]])
{
    float  t = (uniforms.frame_num / 60.0) * 2.0 * M_PI_F;
    float2 uv = float2(v.tex.x + sin(t/2) * uniforms.factor * (1.0 / uniforms.screen_height), v.tex.y);
    float4 color = texture.sample(texture_sampler, uv) * v.color;
    return half4(color);
}






