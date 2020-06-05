//
//  simpleCRTv06032020a.metal
//
//  Created by MrJs 06/2020
//
//  This shader does a very simple CRT emulation using
//  Metal that should run on all of the supported
//  devices that MAME4iOS supports.
//
//  Feel free to tweak, mod, or whatever
//
#include <metal_stdlib>
#import "MetalViewShaders.h"

using namespace metal;

struct simpleCrtUniforms {
    float4 mame_screen_dst_rect;
    float4 mame_screen_src_rect;
};

fragment float4
simpleCRT(VertexOutput v [[stage_in]],
                texture2d<float> texture [[texture(0)]],
                sampler tsamp [[sampler(0)]],
                constant simpleCrtUniforms &uniforms [[buffer(0)]])
{
    float2 uv = ((v.tex - float2(0.5))*2.0)*1.1;  // add in simple curvature to uv's
    uv.x *= (1.0 + pow(abs(uv.y) / 5.0, 2.0)); // tweak vertical curvature
    uv.y *= (1.0 + pow(abs(uv.x) / 4.0, 2.0)); // tweak horizontal curvature
    uv = (uv/float2(2.0))+float2(0.5); // correct curvature
    uv = mix(v.tex, uv, 0.25); // mix back curvature process to 25% of original strength
    float evenLines = (1.0 - abs(fract(v.tex.y*(uniforms.mame_screen_src_rect.w * ( (uniforms.mame_screen_dst_rect.w / uniforms.mame_screen_src_rect.w) / floor((uniforms.mame_screen_dst_rect.w / uniforms.mame_screen_src_rect.w)+0.5))))*2 - 1)); // generate very, very simple scanlines that respect both integer and default scaling
    constexpr sampler crtTexSampler(address::clamp_to_zero, filter::linear); // set up custom Metal texture sampler using cheap linear filtering
    float4 col = texture.sample(crtTexSampler, uv); // sample texture with our modified curvature uv's
    float4 colmod = ((col*col)*evenLines)*1.3; // simple gamma boost in linear to compensate for darkening due to scanlines
    float vign = pow((0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y)),0.05); // create simple soft vignette and apply it across screen
    float4 simple_crt = (sqrt(colmod*vign)); // reapply gamma and vignette treatment
    return simple_crt;
}
