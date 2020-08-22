//
//  MetalView.m
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "MetalView.h"
#import "MetalViewShaders.h"

#if !(TARGET_OS_SIMULATOR && TARGET_OS_TV)
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#endif

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

#define NUM_VERTEX (8*1024)       // number of vertices in a vertex buffer.

#define RESET_AVERAGE_EVERY 120   // reset averages every this many frames

// Direct method and property calls with Xcode 12 and above.
#if defined(__IPHONE_14_0)
__attribute__((objc_direct_members))
#endif
@implementation MetalView {

    // CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpartial-availability"
    CAMetalLayer* _layer;
    #pragma clang diagnostic pop
    
    NSUInteger _prim_count;
    NSUInteger _vert_count;

    CGColorSpaceRef _colorSpaceDevice;
    CGColorSpaceRef _colorSpaceSRGB;
    CGColorSpaceRef _colorSpaceExtendedSRGB;

    NSUInteger _maximumFramesPerSecond;
    UIWindow* _window;
    BOOL _externalDisplay;      // we are on an external display
    BOOL _wideColor;            // display supports wide-color
    BOOL _textureCacheFlush;
    BOOL _resetDevice;

    id <MTLDevice> _device;
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _queue;
    NSLock* _draw_lock;
    NSThread* _draw_thread;     // you can draw from either the main or background

    // vertex buffer cache
    NSMutableArray<id<MTLBuffer>>* _vertex_buffer_cache;
    NSLock* _vertex_buffer_cache_lock;

    // shader cache
    NSMutableDictionary<Shader, id<MTLRenderPipelineState>>* _shader_state;
    NSMutableDictionary<Shader, NSArray*>* _shader_params;
    NSMutableDictionary<NSString*, NSNumber*>* _shader_variables;
    Shader _shader_current;
    
    // texture cache
    NSMutableDictionary<NSNumber*, id<MTLTexture>>* _texture_cache;
    NSMutableDictionary<NSNumber*, NSNumber*>* _texture_hash;
    
    // sampler states
    MTLSamplerMinMagFilter _texture_filter;
    MTLSamplerAddressMode _texture_address_mode;
    id<MTLSamplerState> _texture_sampler[5*2];

    // current vertex buffer for current frame.
    id <MTLBuffer> _vertex_buffer;
    NSUInteger _vertex_buffer_base;

    // vertex buffer free list for current frame.
    NSArray<id<MTLBuffer>>* _vertex_buffer_list;

    id<CAMetalDrawable> _drawable;
    id<MTLCommandBuffer> _command;
    id<MTLCommandBuffer> _compute;
    id<MTLRenderCommandEncoder> _encoder;

    NSTimeInterval _lastDrawTime;
    NSTimeInterval _startRenderTime;
    
    matrix_float4x4 _matrix_view;
    matrix_float4x4 _matrix_model;
}

// CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
+ (Class) layerClass
{
    return [CAMetalLayer class];
}
#pragma clang diagnostic pop

+ (BOOL)isSupported {
    static int g_isMetalSupported;
    if (g_isMetalSupported == 0)
        g_isMetalSupported = (MTLCreateSystemDefaultDevice() != nil) ? 1 : 2;
    return g_isMetalSupported == 1;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])!=nil) {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        _draw_lock = [[NSLock alloc] init];
        
        _colorSpaceDevice = CGColorSpaceCreateDeviceRGB();
        _colorSpaceSRGB = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        _colorSpaceExtendedSRGB = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);

        _pixelFormat = MTLPixelFormatBGRA8Unorm;
        _colorSpace = _colorSpaceDevice;

        // CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wpartial-availability"
        _layer = (CAMetalLayer*)self.layer;
        #pragma clang diagnostic pop
    }
    
    return self;
}

- (void)dealloc {
    CGColorSpaceRelease(_colorSpaceDevice);
    CGColorSpaceRelease(_colorSpaceSRGB);
    CGColorSpaceRelease(_colorSpaceExtendedSRGB);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // TODO: have an explicit texture flush method?
    _textureCacheFlush = TRUE;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    _window = self.window;
    if (_window != nil) {
        _layer.contentsScale = _window.screen.scale;
        _maximumFramesPerSecond = _window.screen.maximumFramesPerSecond;
        _externalDisplay = (_window.screen != UIScreen.mainScreen);
        // TODO: wideColor on macCatalyst!
        _wideColor = _window.screen.traitCollection.displayGamut == UIDisplayGamutP3 && !(TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST);
        if (_wideColor) {
            _colorSpace = _colorSpaceExtendedSRGB;
#if TARGET_OS_MACCATALYST
            _pixelFormat = MTLPixelFormatRGBA16Float;
#else
            _pixelFormat = MTLPixelFormatBGR10_XR;
#endif
        }
        else {
            _colorSpace = _colorSpaceSRGB;
            _pixelFormat = MTLPixelFormatBGRA8Unorm;
        }
        _textureCacheFlush = TRUE;
        _resetDevice = TRUE;
    }
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

- (CGSize) boundsSize {
    return _layer.bounds.size;
}

- (CGSize) drawableSize {
    return _layer.drawableSize;
}

#pragma mark - device init

- (void)initDevice {
    
    if (_window == nil)
        return;
    
    // INIT
    _device = MTLCreateSystemDefaultDevice();
    
    if (_device == nil)
        return;
    
    _frameCount = 0;
    _resetDevice = FALSE;
    
    _layer.device = _device;
    _layer.pixelFormat = _pixelFormat;
    //_layer.colorspace = _colorSpace;
    _layer.framebufferOnly = TRUE;
    _layer.maximumDrawableCount = 3;    // TODO: !

    _library = [_device newDefaultLibrary];
    _queue = [_device newCommandQueue];
    
    // cache of vertex buffers.
    _vertex_buffer_cache_lock = _vertex_buffer_cache_lock ?: [[NSLock alloc] init];
    [_vertex_buffer_cache_lock lock];
    _vertex_buffer_cache = [[NSMutableArray alloc] init];
    [_vertex_buffer_cache_lock unlock];
    
    // shader cache
    _shader_state = [[NSMutableDictionary alloc] init];
    _shader_params = [[NSMutableDictionary alloc] init];
    _shader_variables = [[NSMutableDictionary alloc] init];
    _shader_current = nil;
    
    // texture cache
    _texture_cache = [[NSMutableDictionary alloc] init];
    _texture_hash = [[NSMutableDictionary alloc] init];
    
    //matrix init
    _matrix_view = matrix_identity_float4x4;
    _matrix_model = matrix_identity_float4x4;
    
    // init sampler state(s)
    _texture_address_mode = MTLSamplerAddressModeClampToEdge;
    _texture_filter = MTLSamplerMinMagFilterNearest;
}

#pragma mark - vertex buffers

/// get a free vertex buffer (or create one)
/// **NOTE** the reason we need to use a lock is because buffers are gotten on the main draw thread, but returned in a MTLCommandBuffer callback.
-(id<MTLBuffer>)getBuffer {
    id<MTLBuffer> buffer;
    [_vertex_buffer_cache_lock lock];
    buffer = [_vertex_buffer_cache lastObject];
    if (buffer == nil)
        buffer = [_device newBufferWithLength:NUM_VERTEX * sizeof(Vertex2D) options:MTLResourceStorageModeShared];
    else
        [_vertex_buffer_cache removeLastObject];
    [_vertex_buffer_cache_lock unlock];
    return buffer;
}
/// return buffer from getBuffer
-(void)returnBuffer:(id<MTLBuffer>)buffer {
    [_vertex_buffer_cache_lock lock];
    [_vertex_buffer_cache addObject:buffer];
    [_vertex_buffer_cache_lock unlock];
}
/// return buffers from getBuffer
-(void)returnBuffers:(NSArray<id<MTLBuffer>>*)buffers {
    [_vertex_buffer_cache_lock lock];
    [_vertex_buffer_cache addObjectsFromArray:buffers];
    [_vertex_buffer_cache_lock unlock];
}

#pragma mark - draw begin and end

-(BOOL)drawBegin {
    
    // nested drawBegin, very BAD!
    assert(_encoder == nil);
    if (_encoder != nil)
        return FALSE;
    
    // need to (re)create device.
    if (_device == nil || _resetDevice)
        [self initDevice];
    
    if (_device == nil)
        return FALSE;
    
    // handle a layer size change.
    CGSize size = _layer.bounds.size;
    CGFloat scale = _layer.contentsScale;
    size = CGSizeMake(floor(size.width * scale), floor(size.height * scale));
    
    if (size.width == 0.0 && size.height == 0.0)
        return FALSE;

    if (!CGSizeEqualToSize(size, _layer.drawableSize)) {
        _layer.drawableSize = size;
        _frameCount = 0;
        _textureCacheFlush = TRUE;
    }
    
    // TODO: flush unused textures via a LRU rule?
    if (_textureCacheFlush) {
        _textureCacheFlush = FALSE;
        [_texture_cache removeAllObjects];
    }
    
    // now de-queue a drawable and get to work.
    _drawable = _layer.nextDrawable;
    
    if (_drawable == nil) {
        return FALSE;
    }
    
    [_draw_lock lock];
    _draw_thread = [NSThread currentThread];

    _startRenderTime = CACurrentMediaTime();
    _prim_count = 0;
    _vert_count = 0;
    
    _command = [_queue commandBuffer];

    MTLRenderPassDescriptor* desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = _drawable.texture;
    
    if (_layer.backgroundColor != nil) {
        desc.colorAttachments[0].loadAction = MTLLoadActionClear;
        // color match the layer background color and use that as the clear color
        CGColorRef color = CGColorCreateCopyByMatchingToColorSpace(_colorSpace, kCGRenderingIntentDefault, _layer.backgroundColor, NULL);
        const CGFloat* c = CGColorGetComponents(color);
        desc.colorAttachments[0].clearColor = MTLClearColorMake(c[0], c[1], c[2], c[3]);
        CGColorRelease(color);
    }
    _encoder = [_command renderCommandEncoderWithDescriptor:desc];
    
    // get a fresh vertex buffer
    _vertex_buffer = [self getBuffer];
    _vertex_buffer_list = @[_vertex_buffer];
    _vertex_buffer_base = 0;
    [_encoder setVertexBuffer:_vertex_buffer offset:0 atIndex:0];

    // set default view matrix to match the view bounds, in points.
    _matrix_model = matrix_identity_float4x4;
    [self setViewRect:_layer.bounds];

    // setup initial state.
    _shader_current = nil;
    [self setShader:ShaderCopy];
    
    _texture_filter = _layer.minificationFilter == kCAFilterLinear ? MTLSamplerMinMagFilterLinear : MTLSamplerMinMagFilterNearest;
    _texture_address_mode = MTLSamplerAddressModeClampToEdge;
    [self updateSamplerState];

    // set default (frame based) shader variables
    [self setShaderVariables:@{
        @"frame-count": @(_frameCount),
        @"render-target-size": @(size),
        @"render-target-depth": @(_wideColor ? 10 : 8),
    }];
    
    return TRUE;
}

-(void)drawEnd {
    assert(_drawable != nil);
    NSArray* buffers = _vertex_buffer_list;
    __weak typeof(self) _self = self;
    BOOL externalDisplay = _externalDisplay;
    [_command addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        [_self returnBuffers:buffers];
        if (externalDisplay || TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST)
            [_self updateFPS:CACurrentMediaTime()];
    }];
#if !(TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST)
    if (!externalDisplay) {
        [_drawable addPresentedHandler:^(id<MTLDrawable> drawable) {
            [_self updateFPS:drawable.presentedTime];
        }];
    }
#endif
    [_encoder endEncoding];
#if !(TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST)
    if (_preferredFramesPerSecond != 0 && _preferredFramesPerSecond * 2 <= _maximumFramesPerSecond && _layer.maximumDrawableCount == 3)
        [_command presentDrawable:_drawable afterMinimumDuration:1.0/_preferredFramesPerSecond];
    else
        [_command presentDrawable:_drawable];
#else
    [_command presentDrawable:_drawable];
#endif
    [_compute commit];
    [_command commit];
    _drawable = nil;
    _command = nil;
    _compute = nil;
    _encoder = nil;
    _vertex_buffer = nil;
    _vertex_buffer_list = nil;

    _renderTime = (CACurrentMediaTime() - _startRenderTime);
    if (_renderTimeAverage != 0)
        _renderTimeAverage = (_renderTimeAverage * _frameCount + _renderTime) / (_frameCount+1);
    else
        _renderTimeAverage = _renderTime;
    
    _primCount = _prim_count;
    _vertexCount = _vert_count;
    
    [_draw_lock unlock];
}

#pragma mark - draw primitives

-(void)drawPrim:(MTLPrimitiveType)type vertices:(Vertex2D*)vertices count:(NSUInteger)count {
    assert(_encoder != nil);

    // if our buffer is full, get a new one.
    if (_vertex_buffer_base + count >= NUM_VERTEX) {
        _vertex_buffer = [self getBuffer];
        _vertex_buffer_base = 0;
        _vertex_buffer_list = [_vertex_buffer_list arrayByAddingObject:_vertex_buffer];
        [_encoder setVertexBuffer:_vertex_buffer offset:0 atIndex:0];
    }
    
    // we assume the public Vertex2D matches the private Shader VertexInput *exactly*
    _Static_assert(sizeof(Vertex2D) == sizeof(VertexInput), "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, position) == offsetof(VertexInput, position), "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, tex)      == offsetof(VertexInput, tex),      "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, color)    == offsetof(VertexInput, color),    "Vertex2D != VertexInput");
    memcpy((VertexInput*)_vertex_buffer.contents + _vertex_buffer_base, vertices, sizeof(VertexInput) * count);
    
    [_encoder drawPrimitives:type vertexStart:_vertex_buffer_base vertexCount:count];
    _vertex_buffer_base += count;

    _vert_count += count;

    if (type == MTLPrimitiveTypeTriangleStrip)
        _prim_count += (count - 2);
    else if (type == MTLPrimitiveTypeLineStrip)
        _prim_count += (count - 1);
    else if (type == MTLPrimitiveTypeTriangle)
        _prim_count += (count / 3);
    else if (type == MTLPrimitiveTypeLine)
        _prim_count += (count / 2);
}
-(void)drawLine:(CGPoint)start to:(CGPoint)end color:(VertexColor)color {
    [self drawPrim:MTLPrimitiveTypeLine vertices:(Vertex2D[]){
        Vertex2D(start.x,start.y,0.0,0.0,color),
        Vertex2D(end.x,end.y,0.0,0.0,color),
    } count:2];
}
-(void)drawLineOld:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color edgeAlpha:(CGFloat)alpha {
    
    simd_float2 p0 = simd_make_float2(start.x, start.y);
    simd_float2 p1 = simd_make_float2(end.x, end.y);

    simd_float4 color0 = color;
    simd_float4 color1 = simd_make_float4(color.xyz, color.w * alpha);
    
    // if p0 == p1, draw a little diamond
    //   2 + 4
    //    /|\
    // 1 + p + 6
    //    \|/
    //   3 + 5
    //
    //  else draw the line as a quad with pointy ends
    //
    //  ^    2 +----------------------------------+ 4
    //  |     /|                                  |\
    //  w  1 + p0------------------------------->p1 + 6
    //  |     \|                                  |/
    //  v    3 +----------------------------------+ 5

    // vector from p0 -> p1
    simd_float2 v = p1 - p0;
    float length = simd_length(v);
    float width2 = width * 0.5;
    
    // normalize vector and scale it by half width.
    if (length < 0.001)
        v = simd_make_float2(width2, 0);
    else
        v = v * (1.0 / length) * width2;
    
    // encode the position on the line in the texture coordinates for the fragment shader.
    //      vary texture_u from 0 to length along the line length.
    //      vary texture_v from -1 to +1 along the line width, zero is center.

    Vertex2D vertices[] = {
        Vertex2D(p0.x - v.y,p0.y + v.x, 0.0,1.0,        color1),  // 2
        Vertex2D(p1.x - v.y,p1.y + v.x, length,1.0,     color1),  // 4
        Vertex2D(p0.x - v.x,p0.y - v.y, -width2,0.0,    color0),  // 1
        Vertex2D(p1.x + v.x,p1.y + v.y, length+width2,0.0,color0),// 6
        Vertex2D(p0.x + v.y,p0.y - v.x, 0.0,-1.0,       color1),  // 3
        Vertex2D(p1.x + v.y,p1.y - v.x, length,-1.0,    color1),  // 5
    };
    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}

-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color edgeAlpha:(CGFloat)alpha {
    
    simd_float2 p0 = simd_make_float2(start.x, start.y);
    simd_float2 p1 = simd_make_float2(end.x, end.y);

    simd_float4 color0 = color;
    simd_float4 color1 = simd_make_float4(color.xyz, color.w * alpha);

    // vector from p0 -> p1
    simd_float2 v = p1 - p0;
    float len = simd_length(v);
    float w2 = width * 0.5;
    
    //  a zero length line (aka a point) draw a diamond
    //     3
    //    /|\
    //  2+ P +4
    //    \|/
    //     1
    //
    //  draw the line as a quad, interpolating alpha on the edges
    //
    //  ^  2 +-----------------------------------+ 3
    //  |    |\                                 /|
    //  w    | p0---------------------------->p1 |
    //  |    |/                                 \|
    //  v  1 +-----------------------------------+ 4

    if (len < 0.001)
        v = w2 * simd_make_float2(M_SQRT1_2, M_SQRT1_2);
    else
        v = w2 * v * (1.0 / len);

    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:(Vertex2D[]){
        Vertex2D(p0.x - v.x + v.y, p0.y - v.y - v.x,    -w2, -1.0, color1),  // 1
        Vertex2D(p0.x - v.x - v.y, p0.y - v.y + v.x,    -w2,  1.0, color1),  // 2
        Vertex2D(p0.x,             p0.y,                0.0,  0.0, color0),  // p0
        Vertex2D(p1.x + v.x - v.y, p1.y + v.y + v.x, len+w2,  1.0, color1),  // 3
        Vertex2D(p1.x,             p1.y,                len,  0.0, color0),  // p1
        Vertex2D(p1.x + v.x + v.y, p1.y + v.y - v.x, len+w2, -1.0, color1),  // 4
        Vertex2D(p0.x,             p0.y,                0.0,  0.0, color0),  // p0
        Vertex2D(p0.x - v.x + v.y, p0.y - v.y - v.x,    -w2, -1.0, color1),  // 1
    } count:8];
}

-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color {
    
    simd_float2 p0 = simd_make_float2(start.x, start.y);
    simd_float2 p1 = simd_make_float2(end.x, end.y);

    // vector from p0 -> p1
    simd_float2 v = p1 - p0;
    float len = simd_length(v);
    float w2 = width * 0.5;

    //  a zero length line (aka a point) draw a diamond
    //     2
    //    /|\
    //  1+ P +4
    //    \|/
    //     3
    //
    //  draw the line as a quad expanded by width/2
    //
    //  ^  1 +----------------------------------+ 2
    //  |    |                                  |
    //  w    |  p0------------------------->p1  |
    //  |    |                                  |
    //  v  3 +----------------------------------+ 4

    if (len < 0.001)
        v = w2 * simd_make_float2(M_SQRT1_2, M_SQRT1_2);
    else
        v = w2 * v * (1.0 / len);

    // encode the position on the line in the texture coordinates for the fragment shader.
    //      vary texture_u from 0 to length along the line length.
    //      vary texture_v from -1 to +1 along the line width, zero is center.

    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:(Vertex2D[]){
        Vertex2D(p0.x - v.x - v.y, p0.y - v.y + v.x,    -w2,  1.0, color),  // 1
        Vertex2D(p1.x + v.x - v.y, p1.y + v.y + v.x, len+w2,  1.0, color),  // 2
        Vertex2D(p0.x - v.x + v.y, p0.y - v.y - v.x,    -w2, -1.0, color),  // 3
        Vertex2D(p1.x + v.x + v.y, p1.y + v.y - v.x, len+w2, -1.0, color),  // 4
    } count:4];
}
-(void)drawPoint:(CGPoint)point size:(CGFloat)size color:(VertexColor)color {
    // *NOTE* we dont use MTLPrimitiveTypePoint, because that needs a special vertex shader
    [self drawLine:point to:point width:size color:color];
}
-(void)drawRect:(CGRect)rect color:(VertexColor)color orientation:(UIImageOrientation)orientation {
    
    Vertex2D vertices[] = {
        Vertex2D(rect.origin.x,rect.origin.y,0.0,0.0,color),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y,1.0,0.0,color),
        Vertex2D(rect.origin.x,rect.origin.y + rect.size.height,0.0,1.0,color),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height,1.0,1.0,color),
    };
    
    switch (orientation) {
        case UIImageOrientationUp:
            break;
        case UIImageOrientationDown:
            vertices[0].tex = simd_make_float2(1,1);
            vertices[1].tex = simd_make_float2(0,1);
            vertices[2].tex = simd_make_float2(1,0);
            vertices[3].tex = simd_make_float2(0,0);
            break;
        case UIImageOrientationLeft:
            vertices[0].tex = simd_make_float2(1,0);
            vertices[1].tex = simd_make_float2(1,1);
            vertices[2].tex = simd_make_float2(0,0);
            vertices[3].tex = simd_make_float2(0,1);
            break;
        case UIImageOrientationRight:
            vertices[0].tex = simd_make_float2(0,1);
            vertices[1].tex = simd_make_float2(0,0);
            vertices[2].tex = simd_make_float2(1,1);
            vertices[3].tex = simd_make_float2(1,0);
            break;
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            assert(FALSE);
            break;
    }

    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}
-(void)drawGradientRect:(CGRect)rect color:(VertexColor)color1 color:(VertexColor)color2 orientation:(UIImageOrientation)orientation {
    
    Vertex2D vertices[] = {
        Vertex2D(rect.origin.x,rect.origin.y,0.0,0.0,color1),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y,1.0,0.0,color2),
        Vertex2D(rect.origin.x,rect.origin.y + rect.size.height,0.0,1.0,color1),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height,1.0,1.0,color2),
    };
    
    switch (orientation) {
        case UIImageOrientationUp:
            vertices[0].color = color2;
            vertices[1].color = color2;
            vertices[2].color = color1;
            vertices[3].color = color1;
            break;
        case UIImageOrientationDown:
            vertices[0].color = color1;
            vertices[1].color = color1;
            vertices[2].color = color2;
            vertices[3].color = color2;
            break;
        case UIImageOrientationLeft:
            vertices[0].color = color2;
            vertices[1].color = color1;
            vertices[2].color = color2;
            vertices[3].color = color1;
            break;
        case UIImageOrientationRight:
            break;
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            assert(FALSE);
            break;
    }

    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}
-(void)drawRect:(CGRect)rect color:(VertexColor)color {
    Vertex2D vertices[] = {
        Vertex2D(rect.origin.x,rect.origin.y,0.0,0.0,color),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y,1.0,0.0,color),
        Vertex2D(rect.origin.x,rect.origin.y + rect.size.height,0.0,1.0,color),
        Vertex2D(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height,1.0,1.0,color),
    };
    [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}
-(void)drawTriangle:(CGPoint*)points color:(VertexColor)color {
    Vertex2D vertices[] = {
        Vertex2D(points[0].x,points[0].y,0.0,0.0,color),
        Vertex2D(points[1].x,points[1].y,0.0,0.0,color),
        Vertex2D(points[2].x,points[2].y,0.0,0.0,color),
    };
    [self drawPrim:MTLPrimitiveTypeTriangle vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}

#pragma mark - FPS

-(void)updateFPS:(NSTimeInterval)drawTime {

    if ((_frameCount % RESET_AVERAGE_EVERY) == 0) {
        _frameRateAverage = 0;
        _renderTimeAverage = 0;
    }

    self->_frameCount += 1;
    
    if (_lastDrawTime != 0 && (drawTime - _lastDrawTime) >= (1.0 / 1000.0)) {
        _frameRate  = 1.0 / (drawTime - _lastDrawTime);
        if (_frameRateAverage != 0)
            _frameRateAverage = (_frameRateAverage * (_frameCount-1) + _frameRate) / (_frameCount);
        else
            _frameRateAverage = _frameRate;
    }
    _lastDrawTime = drawTime;
}

#pragma mark - transforms

-(void)setVertexUniforms {
    VertexUniforms vertex_uni;
    vertex_uni.matrix = matrix_multiply(_matrix_view, _matrix_model);
    [_encoder setVertexBytes:&vertex_uni length:sizeof(vertex_uni) atIndex:1];
}

-(void)setViewMatrix:(matrix_float4x4)matrix {
    _matrix_view = matrix;
    [self setVertexUniforms];
}

-(void)setModelMatrix:(matrix_float4x4)matrix {
    _matrix_model = matrix;
    [self setVertexUniforms];
}

-(void)setViewRect:(CGRect)rect {

    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;

    // scale the bounds rect (x,y)-(w,h) to NDC space (-1,-1)-(1,1) and flip.
    CGFloat tx = -2*x/w - 1;
    CGFloat ty = +2*y/h + 1;
    CGFloat sx = +2/w;
    CGFloat sy = -2/h;
    
    [self setViewMatrix:(matrix_float4x4) {{
        { sx, 0,  0,  0 },
        { 0,  sy, 0,  0 },
        { 0,  0,  1,  0 },
        { tx, ty, 0,  1 }
    }}];
}

#pragma mark - shaders

// split and trim a string
static NSMutableArray* split(NSString* str, NSString* sep) {
    NSMutableArray* arr = [[str componentsSeparatedByString:sep] mutableCopy];
    for (int i=0; i<arr.count; i++)
        arr[i] = [arr[i] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    return arr;
}

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
- (void)setShader:(Shader)shader {
    assert(_encoder != nil);
    
    // fastest case, do nothing if we are setting the same shader again.
    if (_shader_current == shader || [_shader_current isEqualToString:shader])
        return;
    
    // setShader(nil) will re-set the current shader
    if (shader == nil)
        shader = _shader_current;
    
    // check for a cache hit, and set the render state from the cache.
    id<MTLRenderPipelineState> state = _shader_state[shader];
    if (state != nil) {
        _shader_current = shader;
        [_encoder setRenderPipelineState:state];

        // set any custom params to fragment shader
        [self setShaderParams:_shader_params[shader]];

        return;
    }

    // shader cache miss, parse the shader string
    NSMutableArray* arr = split(shader, @",");
    
    MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.colorAttachments[0].pixelFormat = _layer.pixelFormat;
    
    // vertex function, always use the same vertex shader
    id<MTLFunction> vert = [_library newFunctionWithName:@"vertex_default"];
    desc.vertexFunction = vert;

    // fragment function
    NSString* shader_name = arr.firstObject;
    [arr removeObjectAtIndex:0];

    // try to find fragment shader, else use default
    id<MTLFunction> frag = [_library newFunctionWithName:shader_name];
    
    if (frag == nil)
        frag = [_library newFunctionWithName:[NSString stringWithFormat:@"fragment_%@", shader_name]];
    
    if (frag == nil) {
        assert(FALSE);
        NSLog(@"SHADER NOT FOUND: %@, using default", shader_name);
        frag = [_library newFunctionWithName:@"fragment_default"];
    }
    
    desc.fragmentFunction = frag;

    // blend mode
    NSString* blend_name = nil;
    if ([arr.firstObject hasPrefix:@"blend="]) {
        blend_name = arr.firstObject;
        [arr removeObjectAtIndex:0];
    }
    
    // default blend=copy Rrgb = Srgb
    desc.colorAttachments[0].blendingEnabled = YES;
    desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
    desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorZero;
    desc.colorAttachments[0].writeMask = MTLColorWriteMaskRed | MTLColorWriteMaskGreen | MTLColorWriteMaskBlue;
    
    // blend=alpha Rrgb = Srgb * Sa + Drgb * (1-Sa)
    if ([blend_name isEqualToString:@"blend=alpha"]) {
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    }
    // blend=premulalpha Rrgb = Srgb + Drgb * (1-Sa)
    else if ([blend_name isEqualToString:@"blend=premulalpha"]) {
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
        desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    }
    // blend=add Rrgb = Srgb * Sa + Drgb
    else if ([blend_name isEqualToString:@"blend=add"]) {
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOne;
    }
    // blend=mul Rrgb = Srgb * Drgb
    else if ([blend_name isEqualToString:@"blend=mul"]) {
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorZero;
        desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorSourceColor;
    }
    // blend=copy Rrgb = Srgb
    else {
        desc.colorAttachments[0].blendingEnabled = NO;
    }
    
    // set a label for this shader, just use the full string.
    desc.label = shader;
    
    // done parsing, create a state object and save it in the cache.
    state = [_device newRenderPipelineStateWithDescriptor:desc error:nil];
    _shader_state[shader] = state;

    // ...also save the shader params, convert any numbers to NSNumber, leave variables as NSString
    if (arr.count > 0) {
        NSNumberFormatter* formater = [[NSNumberFormatter alloc] init];
        for (int i=0; i<arr.count; i++) {
            NSString* str = arr[i];
            // handle variable-name=value
            if ([str containsString:@"="]) {
                NSArray* arr = split(str, @"=");
                str = arr.firstObject;
                if (_shader_variables[str] == nil)
                    _shader_variables[str] = @([arr[1] floatValue]);
            }
            arr[i] = [formater numberFromString:str] ?: str;
        }
        _shader_params[shader] = [arr copy];
    }

    // call ourself again to set the state to the device.
    [self setShader:shader];
}

// resolve nammed shader variables and send float(s) to fragment function
- (void)setShaderParams:(NSArray*)params {
    assert(_encoder != nil);
    
    if ([params count] == 0)
        return;

    float float_params[128];
    NSUInteger count = 0;
    for (id param in params) {
        
        // just ignore too many params.
        assert(count <= sizeof(float_params)/sizeof(float) - 16);
        if (count > sizeof(float_params)/sizeof(float) - 16)
            break;
        
        // a param is either a constant (NSValue/NSNumber) or a variable name (NSString)
        NSValue* val = param;
        if ([param isKindOfClass:[NSString class]]) {
            val = _shader_variables[param];
            if (val == nil) {
                NSLog(@"UNKNOWN SHADER VARIABLE '%@' for shader \"%@\"", param, _shader_current);
                assert(FALSE);
                val = @(0);
            }
        }
        assert([val isKindOfClass:[NSValue class]]);

        if ([val isKindOfClass:[NSNumber class]]) {
            float_params[count++] = [(id)val floatValue];
        }
        else if (strcmp([val objCType], @encode(CGRect)) == 0) {
            CGRect rect = [val CGRectValue];
            float_params[count++] = rect.origin.x;
            float_params[count++] = rect.origin.y;
            float_params[count++] = rect.size.width;
            float_params[count++] = rect.size.height;
        }
        else if (strcmp([val objCType], @encode(CGSize)) == 0) {
            CGSize size = [val CGSizeValue];
            float_params[count++] = size.width;
            float_params[count++] = size.height;
        }
        else if (strcmp([val objCType], @encode(float[2])) == 0) {
            [val getValue:float_params+count size:2*sizeof(float)];
            count += 2;
        }
        else if (strcmp([val objCType], @encode(float[4])) == 0) {
            [val getValue:float_params+count size:4*sizeof(float)];
            count += 4;
        }
        else if (strcmp([val objCType], @encode(float[2][2])) == 0) {
            [val getValue:float_params+count size:4*sizeof(float)];
            count += 4;
        }
        else if (strcmp([val objCType], @encode(float[4][4])) == 0) {
            [val getValue:float_params+count size:16*sizeof(float)];
            count += 16;
        }
        else {
            NSLog(@"INVALID SHADER VARIABLE '%@' type=%s", param, [val objCType]);
            assert(FALSE);
        }
    }
    if (count & 1)
        float_params[count++] = 0.0;
    [_encoder setFragmentBytes:float_params length:count * sizeof(float) atIndex:0];
}

/// add to the dictionary used to resolve named shader variables
- (void)setShaderVariablesInternal:(NSDictionary *)variables {
#ifdef DEBUG
    for (NSString* key in variables.allKeys) {
        assert([key isKindOfClass:[NSString class]]);
        assert([variables[key] isKindOfClass:[NSValue class]]);
    }
#endif
    
#if DebugLog
    BOOL change = FALSE;
    for (NSString* key in variables.allKeys) {
        if ([key isEqualToString:@"frame-count"])
            continue;
        if (_shader_variables[key] == nil || ![_shader_variables[key] isEqual:variables[key]])
             change = TRUE;
    }
#endif

    [_shader_variables addEntriesFromDictionary:variables];
    
#if DebugLog
    if (change) {
        NSLog(@"SHADER VARIABLES CHANGE: %@", _shader_variables);
    }
#endif
    
    // if the currently set shader has params, re-set the render state
    if (_encoder != nil && _shader_params[_shader_current] != nil)
        [self setShader:nil];
}

/// add to the dictionary used to resolve named shader variables
- (void)setShaderVariables:(NSDictionary *)variables {
    if ([NSThread currentThread] == _draw_thread) {
        [self setShaderVariablesInternal:variables];
    }
    else {
        [_draw_lock lock];
        [self setShaderVariablesInternal:variables];
        [_draw_lock unlock];
    }
}

/// get a snapshot of the current shader variables.
-(NSDictionary<NSString*, NSValue*>*)getShaderVariables {
    if ([NSThread currentThread] == _draw_thread) {
        return _shader_variables;
    }
    else {
        NSDictionary* variables;
        [_draw_lock lock];
        variables = [_shader_variables copy];
        [_draw_lock unlock];
        return variables;
    }
}

#pragma mark - textures

// texture pixel format and texture usage combined in a single NSUInteger
#define MTLPixelFormatMask          0x0FFFFFF
#define MTLPixelFormatUsageMask     0xF000000
#define MTLPixelFormatReadOnly      0x0000000   // MTLTextureUsageShaderRead
#define MTLPixelFormatReadWrite     0x1000000   // MTLTextureUsageShaderRead + MTLTextureUsageShaderWrite

// helper to create a texture
-(id<MTLTexture>)textureWithFormat:(MTLPixelFormat)format width:(NSUInteger)width height:(NSUInteger)height {
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:(format & MTLPixelFormatMask) width:width height:height mipmapped:NO];

    if ((format & MTLPixelFormatUsageMask) == MTLPixelFormatReadWrite)
        desc.usage = (MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite);

    return [_device newTextureWithDescriptor:desc];
}

///
/// get a MTLTexture from the cache
///
/// - parameters:
///    texture identifier  - a unique identifier for this texture.
///    hash - a value that changes when texture is modified, use 0 if texture is static.
///    width, height, format, usage - size and format of the texture (used to create on cache miss)
///    texture_load - callback used to load image data.
///
-(id<MTLTexture>)getTexture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format texture_load:(void (^)(id<MTLTexture> texture))texture_load {
    
    if (identifier == NULL)
        return nil;
    
    NSNumber* texture_id = @((NSUInteger)identifier);
    id<MTLTexture> texture = _texture_cache[texture_id];
    NSUInteger texture_hash = [_texture_hash[texture_id] unsignedLongValue];
    
    // check for a cache hit, and texture data not changed (hash and size is the same)
    if (texture != nil && texture_hash == hash && texture.width == width && texture.height == height) {
        return texture;
    }
    
    // create a new Metal texture (if needed), load the data, and put in cache
    if (texture == nil || texture.width != width || texture.height != height) {
        texture = [self textureWithFormat:format width:width height:height];
        texture.label = [NSString stringWithFormat:@"%08lX:%ld %ldx%ld", (NSUInteger)identifier, hash, width, height];
        assert(texture != nil);
    }
    
    // call handler to fill the texture.
    if (texture_load != nil)
        texture_load(texture);
    
    // store in cache for next time.
    _texture_cache[texture_id] = texture;
    _texture_hash[texture_id] = @(hash);
    
    return texture;
}

///
/// get a MTLTexture from the cache and bind it to a texture index.
///
/// - parameters:
///    index - the texture index to bind to (ie 0, 1, 2, ...)
///    texture identifier  - a unique identifier for this texture.
///    hash - a value that changes when texture is modified, use 0 if texture is static.
///    width, height, format - size and format of the texture (used to create on cache miss)
///    texture_load - callback used to load image data.
///
-(void)setTexture:(NSUInteger)index texture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format texture_load:(void (NS_NOESCAPE ^)(id<MTLTexture> texture))texture_load {
    assert(_encoder != nil);
    assert(texture_load != nil);
    id<MTLTexture> texture = [self getTexture:identifier hash:hash width:width height:height format:format texture_load:texture_load];
    [_encoder setFragmentTexture:texture atIndex:index];
}

#pragma mark - filter and address mode

-(void)updateSamplerState {
    assert(_texture_filter == MTLSamplerMinMagFilterNearest || _texture_filter == MTLSamplerMinMagFilterLinear);
    assert(_texture_address_mode >= MTLSamplerAddressModeClampToEdge && _texture_address_mode <= MTLSamplerAddressModeClampToZero);
    _Static_assert(MTLSamplerAddressModeClampToEdge == 0 && MTLSamplerAddressModeClampToZero == 4, "MTLSamplerAddressMode bad!");
    _Static_assert(MTLSamplerMinMagFilterNearest == 0 && MTLSamplerMinMagFilterLinear == 1, "MTLSamplerMinMagFilter bad!");
    _Static_assert(sizeof(_texture_sampler) / sizeof(_texture_sampler[0]) == 5*2, "_texture_sampler wrong size!");

    NSUInteger index = (_texture_address_mode * 2) + _texture_filter;
    
    id<MTLSamplerState> sampler = _texture_sampler[index];
    
    if (sampler == nil) {
        MTLSamplerDescriptor *desc = [[MTLSamplerDescriptor alloc] init];
        desc.minFilter = _texture_filter;
        desc.magFilter = _texture_filter;
        desc.sAddressMode = _texture_address_mode;
        desc.tAddressMode = _texture_address_mode;
        char* address_mode_map[] = {"ClampEdge", "MirrorClamp","Repeat","MirrorRepeat","ClampZero","ClampColor"};
        desc.label = [NSString stringWithFormat:@"filter=%s, mode=%s",
                      (_texture_filter == MTLSamplerMinMagFilterNearest) ? "Nearest" : "Linear",
                      address_mode_map[_texture_address_mode]];
        sampler = [_device newSamplerStateWithDescriptor:desc];
        _texture_sampler[index] = sampler;
    }

    [_encoder setFragmentSamplerState:sampler atIndex:0];
}

-(void)setTextureFilter:(MTLSamplerMinMagFilter)filter {
    assert(_texture_filter == MTLSamplerMinMagFilterNearest || _texture_filter == MTLSamplerMinMagFilterLinear);
    if (_texture_filter != filter) {
        _texture_filter = filter;
        [self updateSamplerState];
    }
}
-(void)setTextureAddressMode:(MTLSamplerAddressMode)mode {
    assert(_texture_address_mode >= MTLSamplerAddressModeClampToEdge && _texture_address_mode <= MTLSamplerAddressModeClampToZero);
    if (_texture_address_mode != mode) {
        _texture_address_mode = mode;
        [self updateSamplerState];
    }
}

#pragma mark - texture color space converstion

///
/// get a MTLTexture from the cache and bind it to a texture index.
///
/// - parameters:
///    index - the texture index to bind to (ie 0, 1, 2, ...)
///    texture identifier  - a unique identifier for this texture.
///    hash - a value that changes when texture is modified, use 0 if texture is static.
///    width, height, format - size and format of the texture (used to create on cache miss)
///    colorspace - CGColorSpace of the texture data. pass NULL for no color conversion.
///    texture_load - callback used to load image data.
///
-(void)setTexture:(NSUInteger)index texture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height format:(MTLPixelFormat)format colorspace:(CGColorSpaceRef)colorspace texture_load:(void (NS_NOESCAPE ^)(id<MTLTexture> texture))texture_load {
    assert(_encoder != nil);
    assert(texture_load != nil);
    
#if (TARGET_OS_SIMULATOR && TARGET_OS_TV)
    // no MetalPerformanceShaders in tvOS simulator!!!
    return [self setTexture:index texture:identifier hash:hash width:width height:height format:format texture_load:texture_load];
#else
    // filter out noop colorspaces
    if (colorspace != NULL) {
        if (colorspace == _colorSpaceDevice || CFEqual(colorspace, _colorSpaceDevice))
            colorspace = NULL;

        if (format == _pixelFormat && (colorspace == _colorSpace || CFEqual(colorspace, _colorSpace)))
            colorspace = NULL;
        
        // TODO: is this right?
        if ((format == MTLPixelFormatRGBA8Unorm || format == MTLPixelFormatBGRA8Unorm) && (colorspace == _colorSpaceSRGB || CFEqual(colorspace, _colorSpaceSRGB)))
            colorspace = NULL;
    }
    
    // no color space just set the texture like normal.
    if (colorspace == NULL)
        return [self setTexture:index texture:identifier hash:hash width:width height:height format:format texture_load:texture_load];
    
    // generate a new identifier for the cache, but use the same hash
    void* new_identifier = (void*)((NSUInteger)identifier ^ 0x914F6CDD1D);
    MTLPixelFormat new_format = _pixelFormat | MTLPixelFormatReadWrite;   // use a RW texture format in the device native format
    [self setTexture:index texture:new_identifier hash:hash width:width height:height format:new_format texture_load:^(id<MTLTexture> dst_texture) {
        // cache miss we need to do color conversion in compute shader
        
        // get the original texture from the cache....
        id<MTLTexture> src_texture = [self getTexture:identifier hash:hash width:width height:height format:format texture_load:texture_load];

        // make a color convert object, and encode it into a compute command buffer
        CGColorConversionInfoRef info = CGColorConversionInfoCreate(colorspace, self->_colorSpace);
        MPSImageConversion* conv = [[MPSImageConversion alloc] initWithDevice:self->_device
            srcAlpha:MPSAlphaTypeAlphaIsOne destAlpha:MPSAlphaTypeAlphaIsOne backgroundColor:nil conversionInfo:info];
        CFRelease(info);

        if (self->_compute == nil)
            self->_compute = [self->_queue commandBuffer];

        [conv encodeToCommandBuffer:self->_compute sourceTexture:src_texture destinationTexture:dst_texture];
    }];
#endif
}

#pragma mark - UIImage textures

static void texture_load_uiimage(id<MTLTexture> texture, UIImage* image) {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;

    void* bitmap_data = malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);

    assert(texture.pixelFormat == MTLPixelFormatRGBA8Unorm);
    uint32_t bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    CGContextRef bitmap = CGBitmapContextCreate(bitmap_data, width, height, 8, width*4, colorSpace, bitmapInfo);
    CGContextSetBlendMode(bitmap, kCGBlendModeCopy);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(bitmap);

    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:bitmap_data bytesPerRow:width*4];
    texture.label = [image debugDescription];

    free(bitmap_data);
}

/// set a UIImage as a texture
-(void)setTexture:(NSUInteger)index image:(UIImage *)image {
    [self setTexture:index texture:(void*)image hash:0
               width:(image.size.width * image.scale) height:(image.size.width * image.scale)
              format:MTLPixelFormatRGBA8Unorm colorspace:CGImageGetColorSpace(image.CGImage)
        texture_load:^(id<MTLTexture> texture) {
            texture_load_uiimage(texture, image);
    }];
}

@end


