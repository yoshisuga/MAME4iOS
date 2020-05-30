//
//  MetalView.h
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//
#import <Metal/Metal.h>
#import <simd/SIMD.h>

typedef simd_float4 VertexColor;
#define VertexColor(r,g,b,a) simd_make_float4(r,g,b,a)
#define VertexRGBA(r,g,b,a)  simd_make_float4(r,g,b,a)
#define VertexRGB(r,g,b)     simd_make_float4(r,g,b,1)

typedef struct {
    simd_float2 position;
    simd_float2 tex;
    simd_float4 color;
} Vertex2D;
#define Vertex2D(x,y,u,v,color) (Vertex2D){simd_make_float2(x,y), simd_make_float2(u,v), color}

// pre-defined shaders and blend modes.
typedef NSString * Shader NS_STRING_ENUM;
static Shader const ShaderNone          = @"default, blend=copy";
static Shader const ShaderCopy          = @"default, blend=copy";
static Shader const ShaderAlpha         = @"default, blend=alpha";
static Shader const ShaderAdd           = @"default, blend=add";
static Shader const ShaderMultiply      = @"default, blend=mul";
static Shader const ShaderTexture       = @"texture, blend=copy";
static Shader const ShaderTextureAlpha  = @"texture, blend=alpha";
static Shader const ShaderTextureAdd    = @"texture, blend=add";
static Shader const ShaderTextureMultiply = @"texture, blend=mul";

typedef void (*texture_load_function_t)(void*, id<MTLTexture>);

@interface MetalView : UIView

@property(class, readonly) BOOL isSupported;
@property(readwrite) CGColorSpaceRef colorSpace;

@property(nonatomic) NSInteger preferredFramesPerSecond;

// thread safe versions of bounds and drawable size.
@property(readonly) CGSize drawableSize;
@property(readonly) CGSize boundsSize;

// frame and render statistics
@property(readwrite) NSUInteger frameCount;         // total frames drawn.
@property(readonly)  CGFloat    frameRate;          // time it took last frame to draw (1/sec)
@property(readonly)  CGFloat    frameRateAverage;   // average frameRate
@property(readonly)  CGFloat    renderTime;         // time it took last frame to render (sec)
@property(readonly)  CGFloat    renderTimeAverage;  // average renderTime

-(BOOL)drawBegin;
-(void)drawPrim:(MTLPrimitiveType)type vertices:(Vertex2D*)vertices count:(NSUInteger)count;
-(void)drawPoint:(CGPoint)point size:(CGFloat)size color:(VertexColor)color;
-(void)drawLine:(CGPoint)start to:(CGPoint)end color:(VertexColor)color;
-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color;
-(void)drawRect:(CGRect)rect color:(VertexColor)color;
-(void)drawRect:(CGRect)rect color:(VertexColor)color orientation:(UIImageOrientation)orientation;
-(void)drawTriangle:(CGPoint*)points color:(VertexColor)color;
-(void)drawEnd;

/// set the drawing corrdinates, by default it is set to the view bounds (in points)
-(void)setViewRect:(CGRect)rect;

/// transforms
-(void)setViewMatrix:(matrix_float4x4)matrix;
-(void)setModelMatrix:(matrix_float4x4)matrix;

/// a shader is a string that selects the fragment function and blend mode to use.
/// it has the following format:
///
///     <function name>, <blend mode>, <parameters>
///
///     <function name> - name of the fragment function name in the shader library.
///
///     <blend mode>    -  blend mode used to write into render target.
///                 blend=copy   - D.rgb = S.rgb
///                 blend=alpha  - D.rgb = S.rgb * S.a + D.rgb * (1-S.a)
///                 blend=add     - D.rgb = S.rgb * S.a + D.rgb
///                 blend=mul     - D.rgb = S.rgb * D.rgb
///
///     <parameters> - list of floats to pass to shader as uniforms, any named variables in this list will be expanded, see setShaderVariables
///
-(void)setShader:(Shader)shader;

/// sets the named custom variables that shaders can access.
///
/// by default the following variables are availible:
///     frame-count                  - current frame number, this will reset to zero from time to time (like on resize)
///     render-target-size         - size of the render target (in pixels)
///
-(void)setShaderVariables:(NSDictionary<NSString*, NSValue*>*)variables;

-(void)setTextureFilter:(MTLSamplerMinMagFilter)filter;
-(void)setTextureAddressMode:(MTLSamplerAddressMode)mode;
-(void)setTexture:(NSUInteger)index texture:(void*)texture hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format texture_load:(texture_load_function_t)texture_load texture_load_data:(void*)texture_load_data;

/// set a UIImage as a texture
-(void)setTexture:(NSUInteger)index image:(UIImage*)image;

@end



