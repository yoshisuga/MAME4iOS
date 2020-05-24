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

#define NUM_VERTEX 4096      // number of vertices in a vertex buffer.

@implementation MetalView {

    // CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpartial-availability"
    CAMetalLayer* _layer;
    #pragma clang diagnostic pop

    id <MTLDevice> _device;
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _queue;

    // vertex buffer cache
    NSMutableArray<id<MTLBuffer>>* _vertex_buffer_cache;
    NSLock* _vertex_buffer_cache_lock;

    // shader cache
    NSMutableDictionary<Shader, id<MTLRenderPipelineState>>* _shader_state;
    NSMutableDictionary<Shader, NSArray*>* _shader_params;
    NSMutableDictionary<Shader, NSNumber*>* _shader_variables;
    Shader _shader_current;
    
    // texture cache
    NSMutableDictionary<NSNumber*, id<MTLTexture>>* _texture_cache;
    NSMutableDictionary<NSNumber*, NSNumber*>* _texture_hash;
    id<MTLSamplerState> _texture_sampler;

    // current vertex buffer for current frame.
    id <MTLBuffer> _vertex_buffer;
    NSUInteger _vertex_buffer_base;

    // vertex buffer free list for current frame.
    NSArray<id<MTLBuffer>>* _vertex_buffer_list;

    id<CAMetalDrawable> _drawable;
    id<MTLCommandBuffer> _buffer;
    id<MTLRenderCommandEncoder> _encoder;
    
    NSTimeInterval _lastDrawTime;
    NSTimeInterval _startRenderTime;
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
    static BOOL isMetalSupported;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isMetalSupported = MTLCreateSystemDefaultDevice() != nil;
    });
    return isMetalSupported;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])!=nil) {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        
        // CAMetalLayer avalibility is wrong in the iOS 11.3.4 sdk???
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wpartial-availability"
        _layer = (CAMetalLayer*)self.layer;
        #pragma clang diagnostic pop
	}
    
	return self;
}

-(CGColorSpaceRef)colorSpace {
    return _layer.colorspace;
}
-(void)setColorSpace:(CGColorSpaceRef)colorSpace {
    _layer.colorspace = colorSpace;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _frameCount = 0;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window != nil)
        _layer.contentsScale = self.window.screen.scale;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

/// a background safe version to get bounds of UIView
- (CGRect)bounds {
    if (_layer)
        return _layer.bounds;
    else
        return [super bounds];
}

#pragma mark - device init

- (void)initDevice {
    // INIT
    _device = MTLCreateSystemDefaultDevice();
    
    if (_device == nil)
        return;
    
    _frameCount = 0;
    
    _layer.device = _device;
    _layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _layer.framebufferOnly = TRUE;

    _library = [_device newDefaultLibrary];
    _queue = [_device newCommandQueue];
    
    // cache of vertex buffers.
    _vertex_buffer_cache = _vertex_buffer_cache ?: [[NSMutableArray alloc] init];
    _vertex_buffer_cache_lock = _vertex_buffer_cache_lock ?: [[NSLock alloc] init];
    
    // shader cache
    _shader_state = [[NSMutableDictionary alloc] init];
    _shader_params = [[NSMutableDictionary alloc] init];
    _shader_variables = [[NSMutableDictionary alloc] init];
    _shader_current = nil;
    
    // texture cache
    _texture_cache = [[NSMutableDictionary alloc] init];
    _texture_hash = [[NSMutableDictionary alloc] init];
    
    // create sampler state
    // TODO: dont hard code this.
    MTLSamplerDescriptor *desc = [[MTLSamplerDescriptor alloc] init];
    desc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    desc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    desc.minFilter = MTLSamplerMinMagFilterLinear;
    desc.magFilter = MTLSamplerMinMagFilterLinear;
    desc.mipFilter = MTLSamplerMipFilterLinear;
    _texture_sampler = [_device newSamplerStateWithDescriptor:desc];
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
    // nested drawBegin, BAD!
    assert(_drawable == nil);
    if (_drawable != nil)
        return FALSE;
    
    // need to (re)create device.
    if (_device == nil)
        [self initDevice];
    
    if (_device == nil)
        return FALSE;
    
    // handle a layer size change.
    CGSize size = _layer.bounds.size;
    CGFloat scale = _layer.contentsScale;
    size = CGSizeMake(floor(size.width * scale), floor(size.height * scale));

    if (!CGSizeEqualToSize(size, _layer.drawableSize)) {
        _layer.drawableSize = size;
        _frameCount = 0;
        [_texture_cache removeAllObjects];
    }
    
    // now de-queue a drawable and get to work.
    _drawable = _layer.nextDrawable;
    
    if (_drawable == nil)
        return FALSE;

    _startRenderTime = CACurrentMediaTime();
    
    _buffer = [_queue commandBuffer];

    MTLRenderPassDescriptor* desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = _drawable.texture;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    _encoder = [_buffer renderCommandEncoderWithDescriptor:desc];
    
    // get a fresh vertex buffer
    _vertex_buffer = [self getBuffer];
    _vertex_buffer_list = @[_vertex_buffer];
    _vertex_buffer_base = 0;
    [_encoder setVertexBuffer:_vertex_buffer offset:0 atIndex:0];

    // vertex uniforms
    [self setViewRect:_layer.bounds];

    // setup initial state.
    _shader_current = nil;
    [self setShader:ShaderCopy];

    // set default (frame based) shader variables
    [self setShaderVariables:@{
        @"frame-count": @(_frameCount),
        @"render-target-width": @(size.width),
        @"render-target-height": @(size.height),
    }];

    return TRUE;
}

-(void)drawEnd {
    assert(_drawable != nil);
    [_encoder endEncoding];
    [_buffer presentDrawable:_drawable];
    NSArray* buffers = _vertex_buffer_list;
    __weak typeof(self) weakSelf = self;
    [_buffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        [weakSelf returnBuffers:buffers];
    }];
    [_drawable addPresentedHandler:^(id<MTLDrawable> drawable) {
        [weakSelf updateFPS:drawable.presentedTime];
    }];
    [_buffer commit];
    _drawable = nil;
    _buffer = nil;
    _encoder = nil;
    _vertex_buffer = nil;
    _vertex_buffer_list = nil;

    _renderTime = (CACurrentMediaTime() - _startRenderTime);
    if (_renderTimeAverage != 0)
        _renderTimeAverage = (_renderTimeAverage * _frameCount + _renderTime) / (_frameCount+1);
    else
        _renderTimeAverage = _renderTime;
}

#pragma mark - draw primitives

-(void)drawPrim:(MTLPrimitiveType)type vertices:(Vertex2D*)vertices count:(NSUInteger)count {
    assert(_drawable != nil);

    // if our buffer is full, get a new one.
    if (_vertex_buffer_base + count >= NUM_VERTEX) {
        _vertex_buffer = [self getBuffer];
        _vertex_buffer_base = 0;
        _vertex_buffer_list = [_vertex_buffer_list arrayByAddingObject:_vertex_buffer];
        [_encoder setVertexBuffer:_vertex_buffer offset:0 atIndex:0];
    }
    
    // TODO: only update the state if it changes!!
    //[_encoder setRenderPipelineState:_state];
    //[_encoder setVertexBuffer:_vertex offset:0 atIndex:0];
    
    // we assume the public Vertex2D matches the private Shader VertexInput *exactly*
    _Static_assert(sizeof(Vertex2D) == sizeof(VertexInput), "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, position) == offsetof(VertexInput, position), "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, tex)      == offsetof(VertexInput, tex),      "Vertex2D != VertexInput");
    _Static_assert(offsetof(Vertex2D, color)    == offsetof(VertexInput, color),    "Vertex2D != VertexInput");
    memcpy((VertexInput*)_vertex_buffer.contents + _vertex_buffer_base, vertices, sizeof(VertexInput) * count);
    
    [_encoder drawPrimitives:type vertexStart:_vertex_buffer_base vertexCount:count];
    _vertex_buffer_base += count;
}
-(void)drawLine:(CGPoint)start to:(CGPoint)end color:(VertexColor)color {
    Vertex2D vertices[] = {
        Vertex2D(start.x,start.y,0.0,0.0,color),
        Vertex2D(end.x,end.y,0.0,0.0,color),
    };
    [self drawPrim:MTLPrimitiveTypeLine vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
}
-(void)drawLine:(CGPoint)start to:(CGPoint)end width:(CGFloat)width color:(VertexColor)color {

    simd_float2 p0 = simd_make_float2(start.x, start.y);
    simd_float2 p1 = simd_make_float2(end.x, end.y);
    
    // if p0 == p1, draw a little diamond
    //   2 +
    //    /|\
    // 1 + p + 4
    //    \|/
    //     + 3
    if (p0.x == p1.x && p0.y == p1.y) {
        simd_float2 v = simd_make_float2(width * 0.5, 0);

        Vertex2D vertices[] = {
            Vertex2D(p0.x - v.x,p0.y - v.y,0.0,0.0,color),
            Vertex2D(p0.x + v.y,p0.y - v.x,0.0,0.0,color),
            Vertex2D(p0.x - v.y,p0.y + v.x,0.0,0.0,color),
            Vertex2D(p0.x + v.x,p0.y + v.y,0.0,0.0,color),
        };
        [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
    }
    else {
        //  draw the line as a quad with pointy ends
        //
        //  ^    2 +----------------------------------+ 4
        //  |     /|                                  |\
        //  w  1 + p0------------------------------->p1 + 6
        //  |     \|                                  |/
        //  v    3 +----------------------------------+ 5

        // unit vector from p0 -> p1
        simd_float2 v = simd_normalize(p1 - p0) * width * 0.5;
        
        Vertex2D vertices[] = {
            Vertex2D(p0.x - v.x,p0.y - v.y,0.0,0.0,color),
            Vertex2D(p0.x + v.y,p0.y - v.x,0.0,0.0,color),
            Vertex2D(p0.x - v.y,p0.y + v.x,0.0,0.0,color),
            
            Vertex2D(p1.x - v.y,p1.y + v.x,0.0,0.0,color),
            Vertex2D(p1.x + v.y,p1.y - v.x,0.0,0.0,color),
            Vertex2D(p1.x + v.x,p1.y + v.y,0.0,0.0,color),
        };
        [self drawPrim:MTLPrimitiveTypeTriangleStrip vertices:vertices count:sizeof(vertices)/sizeof(vertices[0])];
    }
}
-(void)drawPoint:(CGPoint)point size:(CGFloat)size color:(VertexColor)color {
    // *NOTE* we dont use MTLPrimitiveTypePoint, because that needs a special vertex shader
    [self drawLine:point to:point width:size color:color];
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

    if (_frameCount == 0) {
        _frameRateAverage = 0;
        _renderTimeAverage = 0;
        _lastDrawTime = 0;
        _frameRate = 0;
    }

    if (_lastDrawTime != 0 &&  (drawTime - _lastDrawTime) >= (1.0 / 240.0)) {
        _frameRate  = 1.0 / (drawTime - _lastDrawTime);
        if (_frameRateAverage != 0)
            _frameRateAverage = (_frameRateAverage * _frameCount + _frameRate) / (_frameCount+1);
        else
            _frameRateAverage = _frameRate;
    }
    _lastDrawTime = drawTime;
    
    self->_frameCount += 1;
}

#pragma mark - transforms

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
    
    // set the Uniforms
    VertexUniforms vertex_uni;
    vertex_uni.matrix = (matrix_float4x4) {{
        { sx, 0,  0,  0 },
        { 0,  sy, 0,  0 },
        { 0,  0,  1,  0 },
        { tx, ty, 0,  1 }
    }};

    [_encoder setVertexBytes:&vertex_uni length:sizeof(vertex_uni) atIndex:1];
}

#pragma mark - shaders

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
///                 blend=add     - D.rgb = S.rgb + D.rgb
///                 blend=mul     - D.rgb = S.rgb * D.rgb
///
- (void)setShader:(Shader)shader {
    assert(_drawable != nil);
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
        NSArray* shader_params = _shader_params[shader];
        if (shader_params != nil) {
            float float_params[64];
            NSUInteger count = MIN([shader_params count], sizeof(float_params)/sizeof(float));
            for (int i=0; i<count; i++) {
                NSString* val = shader_params[i];
                float_params[i] = [((id)_shader_variables[val] ?: val) floatValue];
            }
            [_encoder setFragmentBytes:float_params length:count * sizeof(float) atIndex:0];
        }

        return;
    }

    // shader cache miss, parse the shader string
    NSMutableArray* arr = [[shader componentsSeparatedByString:@","] mutableCopy];
    for (int i=0; i<arr.count; i++)
        arr[i] = [arr[i] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    
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
    
    if (frag == nil)
        frag = [_library newFunctionWithName:@"fragment_default"];
    
    desc.fragmentFunction = frag;

    // blend mode
    NSString* blend_name = nil;
    if ([arr.firstObject hasPrefix:@"blend="]) {
        blend_name = arr.firstObject;
        [arr removeObjectAtIndex:0];
    }
    
    // default blend=copy Rrgb = Srgb
    desc.colorAttachments[0].blendingEnabled = YES;
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
    // blend=add Rrgb = Srgb + Drgb
    else if ([blend_name isEqualToString:@"blend=add"]) {
        desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
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
    
    // done parsing, create a state object and save it in the cache.
    state = [_device newRenderPipelineStateWithDescriptor:desc error:nil];
    _shader_state[shader] = state;

    // ...also save the shader params
    if (arr.count > 0) {
        _shader_params[shader] = [arr copy];
    }

    // call ourself again to set the state to the device.
    [self setShader:shader];
}

- (void)setShaderVariables:(NSDictionary *)variables {
    [_shader_variables addEntriesFromDictionary:variables];
    
    // if the currently set shader has params, re-set the render state
    if (_shader_params[_shader_current] != nil)
        [self setShader:nil];
}

#pragma mark - textures

///
/// get a MTLTexture from the cache and bind it to a texture index.
///
/// - parameters:
///    index - the texture index to bind to (ie 0, 1, 2, ...)
///    texture identifier  - a unique identifier for this texture.
///    hash - a value that changes when texture is modified, use 0 if texture is static.
///    width, height - size of the texture (used to create on cache miss)
///    texture_load - callback used to load image data.
///    texture_load_data - opaque data passed to load callback (can be same as texture identifier)
///
-(void)setTexture:(NSUInteger)index texture:(void*)identifier hash:(NSUInteger)hash width:(NSUInteger)width height:(NSUInteger)height texture_load:(texture_load_function_t)texture_load texture_load_data:(void*)texture_load_data {
    assert(_encoder != nil);
    assert(texture_load != NULL);
    
    if (identifier == NULL)
        return;
    
    NSNumber* texture_id = @((NSUInteger)identifier);
    id<MTLTexture> texture = _texture_cache[texture_id];
    NSUInteger texture_hash = [_texture_hash[texture_id] unsignedLongValue];
    
    // check for a cache hit, and texture data not changed (hash is the same)
    if (texture != nil && texture_hash == hash) {
        [_encoder setFragmentTexture:texture atIndex:index];
        [_encoder setFragmentSamplerState:_texture_sampler atIndex:0];
        return;
    }
    
    // create a new Metal texture (if needed), load the data, and put in cache
    if (texture == nil) {
        // TODO: use correct texture format?
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                width:width height:height mipmapped:NO];
        texture = [_device newTextureWithDescriptor:desc];
        assert(texture != nil);
    }
    
    texture_load(texture_load_data, texture);
    _texture_cache[texture_id] = texture;
    _texture_hash[texture_id] = @(hash);

    [_encoder setFragmentTexture:texture atIndex:index];
    [_encoder setFragmentSamplerState:_texture_sampler atIndex:0];
}

#pragma mark - UIImage textures

void texture_load_uiimage(void* data, id<MTLTexture> texture) {
    UIImage* image = (__bridge UIImage*)data;
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;

    void* bitmap_data = malloc(width * height * 4);
    
    // TODO: use the right colorSpace!
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    assert(texture.pixelFormat == MTLPixelFormatRGBA8Unorm);
    uint32_t bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    CGContextRef bitmap = CGBitmapContextCreate(bitmap_data, width, height, 8, width*4, colorSpace, bitmapInfo);
    //CGContextSetBlendMode(bitmap, kCGBlendModeNormal);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), image.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(bitmap);

    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:bitmap_data bytesPerRow:width*4];
    texture.label = [image debugDescription];

    free(bitmap_data);
}

/// set a UIImage as a texture
-(void)setTexture:(NSUInteger)index image:(UIImage *)image {
    [self setTexture:index texture:(void*)image hash:42
               width:image.size.width * image.scale height:image.size.width * image.scale
        texture_load:texture_load_uiimage texture_load_data:(void*)image];
}

@end
