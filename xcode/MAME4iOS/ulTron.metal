//
//  ulTron.metal
//
//  Created by MrJs 06/2020
//  v09062020a
//
//  Ultron (/ˈʌltrɒn/) is a fictional supervillain appearing in American comic books published by Marvel Comics.
//  He is most recognized as a nemesis of the Avengers superhero group and his quasi-familial relationship with his creator Hank Pym.
//  He was the first Marvel Comics character to wield the fictional metal alloy adamantium.
//
//  Feel free to tweak, mod, or whatever
//
#include <metal_stdlib>
#import "MetalViewShaders.h"

using namespace metal;

struct Push
{
    float4 SourceSize;
    float4 OutputSize;
};

fragment float4
ulTron(VertexOutput v[[stage_in]],
       constant Push& params [[buffer(0)]],
       texture2d<float> texture [[texture(0)]],
       sampler texture_sampler [[sampler(0)]])
{
    float4 color = texture.sample(texture_sampler, v.tex);
    float Y = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722;

    return float4(1.0,0.65,0.38,1) * Y;
}
