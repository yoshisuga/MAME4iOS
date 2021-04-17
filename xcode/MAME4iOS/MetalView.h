//
//  MetalView.h
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <simd/SIMD.h>

NS_ASSUME_NONNULL_BEGIN

typedef simd_float4 VertexColor;
#define VertexColor(r,g,b,a) simd_make_float4(r,g,b,a)

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


//
// MetalView - a UIView subclass for custom drawing with Metal (in 2D)
//
@interface MetalView : UIView

@property(class, readonly, nonatomic) BOOL isSupported;
@property(readonly, nonatomic) CGColorSpaceRef colorSpace;
@property(readonly, nonatomic) MTLPixelFormat pixelFormat;

@property(readwrite, nonatomic) NSInteger preferredFramesPerSecond;

// thread safe versions of bounds and drawable size.
@property(readonly, nonatomic) CGSize drawableSize;
@property(readonly, nonatomic) CGSize boundsSize;

// frame and render statistics
@property(readwrite, nonatomic) NSUInteger frameCount;         // total frames drawn.
@property(readonly, nonatomic)  CGFloat    frameRate;          // time it took last frame to draw (1/sec)
@property(readonly, nonatomic)  CGFloat    frameRateAverage;   // average frameRate
@property(readonly, nonatomic)  CGFloat    renderTime;         // time it took last frame to render (sec)
@property(readonly, nonatomic)  CGFloat    renderTimeAverage;  // average renderTime
@property(readonly, nonatomic)  NSUInteger vertexCount;        // total verticies drawn last frame.
@property(readonly, nonatomic)  NSUInteger primCount;          // total primitives drawn last frame.

@property(readwrite, nonatomic) BOOL       showFPS;            // draw FPS stats
@property(readwrite, nonatomic) CGFloat    sizeFPS;            // size of FPS text, height in points

-(BOOL)drawBegin;
-(void)drawPrim:(MTLPrimitiveType)type vertices:(const Vertex2D*)vertices count:(NSUInteger)count;
-(void)drawPoint:(CGPoint)point size:(CGFloat)size color:(VertexColor)color;
-(void)drawLine:(CGPoint)start to:(CGPoint)end color:(VertexColor)color;
-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color;
-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color edgeAlpha:(CGFloat)alpha;
-(void)drawRect:(CGRect)rect color:(VertexColor)color;
-(void)drawRect:(CGRect)rect color:(VertexColor)color orientation:(UIImageOrientation)orientation;
-(void)drawGradientRect:(CGRect)rect color:(VertexColor)color1 color:(VertexColor)color2 orientation:(UIImageOrientation)orientation;
-(void)drawTriangle:(const CGPoint*)points color:(VertexColor)color;
-(void)drawText:(NSString*)text at:(CGPoint)xy height:(CGFloat)height color:(VertexColor)color;
-(void)drawEnd;

-(CGSize)sizeText:(NSString*)text height:(CGFloat)height;

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
///                 blend=premulalpha - D.rgb = S.rgb + D.rgb * (1-S.a)
///                 blend=add     - D.rgb = S.rgb * S.a + D.rgb
///                 blend=mul     - D.rgb = S.rgb * D.rgb
///
///     <parameters>    - list of parameters to be passed to fragment shader as uniforms.  each parameter is one of the following...
///                 42.0 - a floating point contant value
///                 named-variable - a value that will be queried from the the shader variable dictionary.
///                 named-variable=42.0 - a named variable with a default value.
///
-(void)setShader:(nullable Shader)shader;

/// sets the named custom variables that shaders can access.
///
/// by default the following variables are availible:
///     frame-count                  - current frame number, this will reset to zero from time to time (like on resize)
///     render-target-size         - size of the render target (in pixels)
///
-(void)setShaderVariables:(nullable NSDictionary<NSString*, NSValue*>*)variables;
-(NSDictionary<NSString*, NSValue*>*)getShaderVariables;

-(void)textureCacheFlush;
-(void)setTextureFilter:(MTLSamplerMinMagFilter)filter;
-(void)setTextureAddressMode:(MTLSamplerAddressMode)mode;
-(void)setTexture:(NSUInteger)index texture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format texture_load:(void (NS_NOESCAPE ^)(id<MTLTexture> texture))texture_load;
-(void)setTexture:(NSUInteger)index texture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format colorspace:(CGColorSpaceRef)colorspace texture_load:(void (NS_NOESCAPE ^)(id<MTLTexture> texture))texture_load;

/// set a UIImage as a texture
-(void)setTexture:(NSUInteger)index image:(UIImage*)image;

@end

NS_ASSUME_NONNULL_END




