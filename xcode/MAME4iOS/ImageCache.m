//
//  ImageCache.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#import "ImageCache.h"

#define ImageCacheDebug 0
#define ImageCacheLog 0
#if !ImageCacheLog
#define NSLog(...) (void)0
#endif

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#define ERROR_RETRY_TIME (1.0 * 60.0)   // retry again after this amount...

@implementation ImageCache
{
    NSCache* cache;
    NSMutableDictionary* task_dict;
}

static ImageCache* sharedInstance = nil;

+(ImageCache*) sharedInstance
{
    NSParameterAssert([NSThread isMainThread]);
    if (sharedInstance == nil)
        sharedInstance = [[ImageCache alloc] init];
    return sharedInstance;
}

-(id)init
{
    if ((self = [super init]))
    {
        cache = [[NSCache alloc] init];
        task_dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)dealloc
{
    if (sharedInstance == self)
        sharedInstance = nil;
}

- (void)flush
{    
    [cache removeAllObjects];
}

- (void)getData:(NSURL*)url localURL:(NSURL*)localURL completionHandler:(void (^)(NSData* data, NSError* error))handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (localURL != nil && ImageCacheDebug == 0)
        {
            NSData* data = [NSData dataWithContentsOfURL:localURL];
            
            if (data != nil)
                return handler(data, nil);
        }
        
        if (url == nil)
            return handler(nil, nil);
        
        NSURLSession* session = [NSURLSession sharedSession];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        
#if ImageCacheDebug
        // randomly force a timeout to test code....
        if (arc4random_uniform(10) == 0) {
            NSLog(@"TESTING A NETWORK ERROR: %@", url);
            request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.com:81/wombat.png"]];
        }
#endif
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request
            completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {

            NSInteger status = [(NSHTTPURLResponse*)response statusCode];

            if (error != nil)
                NSLog(@"GET DATA\n\tURL:%@\n\tERROR:%@", url, error);

            if (status != 200)
            {
                NSLog(@"GET DATA: BAD RESPONSE (%d)\n\tURL:%@\n\tBODY:%@",
                      (int)status, url, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                data = nil;
            }

            if (localURL != nil && data != nil && error == nil)
                [data writeToURL:localURL atomically:YES];

            handler(data, error);
        }];
        [task resume];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSParameterAssert([NSThread isMainThread]);
            self->task_dict[url] = task;
        });
    });
}

- (void)getImage:(NSURL*)url size:(CGSize)size localURL:(NSURL*)localURL completionHandler:(ImageCacheCallback)handler
{
    NSParameterAssert([NSThread isMainThread]);
    NSParameterAssert(handler != nil);
    NSParameterAssert(localURL == nil || [localURL isFileURL]);

    NSLog(@"IMAGE CACHE: getImage: %@ [%f,%f]", url.path, size.width, size.height);
    
    NSString* key = [NSString stringWithFormat:@"%@[%f,%f]", url.path, size.width, size.height];
    id val = [cache objectForKey:key];
    
    if ([val isKindOfClass:[UIImage class]])
    {
        NSLog(@"....IMAGE CACHE HIT");
        return handler(val);
    }
    
    if ([val isKindOfClass:[NSDate class]])
    {
        if ([((NSDate*)val) timeIntervalSinceNow] > (-1.0 * ERROR_RETRY_TIME))
        {
            NSLog(@"....IMAGE LOAD ERROR: NIL");
            return handler(nil);
        }
        NSLog(@"....IMAGE LOAD ERROR: RETRY");
        val = nil;
    }
    
    if ([val isKindOfClass:[NSNull class]])
    {
        NSLog(@"....IMAGE CACHE NULL");
        return handler(nil);
    }

    if ([val isKindOfClass:[NSMutableArray class]])
    {
        NSLog(@"....IMAGE CACHE LOADING");
        return [val addObject:handler];
    }
    
    // if we have a local copy on disk, and we dont need to resize, get the image synchronously.
    // this prevents showing default icons unless we need to go to the net, at expense of a little scrolling perf.
    if (localURL != nil && (size.width == 0 && size.height == 0) && ImageCacheDebug == 0)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localURL.path])
        {
            NSLog(@"....IMAGE LOCAL CACHE HIT");
            UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localURL]];
            [cache setObject:(image ?: [NSNull null]) forKey:key];
            return handler(image);
        }
    }
    
    NSLog(@"....IMAGE CACHE MISS");
    NSParameterAssert(val == nil);
    [cache setObject:[NSMutableArray arrayWithObject:handler] forKey:key];
    
    [self getData:url localURL:localURL completionHandler:^(NSData *data, NSError* error) {
        NSLog(@"IMAGE CACHE DATA: %d bytes", (int)[data length]);
        UIImage* image = [UIImage imageWithData:data];
        NSLog(@"IMAGE IMAGE: %@", image);
        image = [image scaledToSize:size];
        NSLog(@"IMAGE SCALE IMAGE: %@", image);

#if ImageCacheDebug
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, arc4random_uniform(5000) * USEC_PER_SEC), dispatch_get_main_queue(), ^{
#else
        dispatch_async(dispatch_get_main_queue(), ^{
#endif
            self->task_dict[url] = nil;
            NSArray* callbacks = [self->cache objectForKey:key];

            if (image == nil && error != nil && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
                NSLog(@"IMAGE LOAD CANCELED: %@ [%d clients]", url.lastPathComponent, (int)[callbacks count]);
                [self->cache removeObjectForKey:key];
            }
            else {
                //  * if we got an error, put the current date in the cache
                //    so we will try again later (after a while)
                //
                //  * if we got an image, put that in the cache, success!
                //
                //  * if we got a nil image, but no error, the url must not exist (404)
                //    or be a bad image. put a NSNull in the cache.
                //
                if (image == nil && error != nil)
                    [self->cache setObject:[NSDate date] forKey:key];
                else
                    [self->cache setObject:(image ?: [NSNull null]) forKey:key];
                
                NSLog(@"IMAGE START CALLBACKS for %@ [%d clients]", url.lastPathComponent, (int)[callbacks count]);
                for (ImageCacheCallback callback in callbacks) {
                    NSLog(@"....IMAGE CALLBACK: %@", image);
                    callback(image);
                }
                NSLog(@"IMAGE STOP CALLBACKS for %@", url.lastPathComponent);
            }
        });
    }];
}

- (void)getImage:(NSURL*)url size:(CGSize)size completionHandler:(ImageCacheCallback)handler
{
    [self getImage:url size:size localURL:nil completionHandler:handler];
}

- (void)getImage:(NSURL*)url completionHandler:(ImageCacheCallback)handler
{
    [self getImage:url size:CGSizeZero completionHandler:handler];
}
                       
- (void)cancelImage:(NSURL*)url
{
    NSParameterAssert([NSThread isMainThread]);
    NSURLSessionDataTask* task = task_dict[url];
    if (task != nil) {
        NSLog(@"cancelImage: %@", url);
        [task cancel];
        task_dict[url] = nil;
    }
}

@end
                       
#define lerp(a,b,f) ((a)*(1-(f)) + (b)*(f))

static CGColorRef blend(CGColorRef c0, CGColorRef c1, CGFloat f)
{
    assert(CGColorGetColorSpace(c0) == CGColorGetColorSpace(c1));
    
    const CGFloat* cc0 = CGColorGetComponents(c0);
    const CGFloat* cc1 = CGColorGetComponents(c1);
    CGFloat rgba[4] = {lerp(cc0[0],cc1[0],f),lerp(cc0[1],cc1[1],f),lerp(cc0[2],cc1[2],f),lerp(cc0[3],cc1[3],f)};
    
    return CGColorCreate(CGColorGetColorSpace(c0), rgba);
}

// compute/create a average color from a bunch of raw RGBA pixels
static CGColorRef averageColorRGBA(uint32_t* image_ptr, NSInteger image_width, NSInteger image_height, CGColorSpaceRef colorSpace, CGImageAlphaInfo alpha, NSInteger x, NSInteger y, NSInteger dx, NSInteger dy)
{
   y = image_height-(y+dy);    // CoreGraphics images are stored bottom up, not top down
   image_ptr += (image_width * y) + x;

   NSUInteger vec[4] = {0,0,0,0};
   for (NSInteger y = 0; y < dy; y++) {
      for (NSInteger x = 0; x < dx; x++) {
          NSUInteger pixel = OSSwapHostToLittleInt32(*image_ptr++);
          vec[0] += ((pixel >>  0) & 0xFF);
          vec[1] += ((pixel >>  8) & 0xFF);
          vec[2] += ((pixel >> 16) & 0xFF);
          vec[3] += ((pixel >> 24) & 0xFF);
      }
      image_ptr += (image_width - dx);
   }
  
   CGFloat f = 1.0 / (255.0 * dx * dy);
   CGFloat r = vec[0] * f;
   CGFloat g = vec[1] * f;
   CGFloat b = vec[2] * f;
   CGFloat a = vec[3] * f;
   
   if (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaNoneSkipFirst) {
       CGFloat t = r;
       r = g;
       g = b;
       b = a;
       a = t;
   }

   if ((alpha == kCGImageAlphaPremultipliedLast || alpha == kCGImageAlphaPremultipliedFirst) && a != 0.0) {
       r /= a;
       g /= a;
       b /= a;
   }
   
   if (alpha == kCGImageAlphaNoneSkipLast || alpha == kCGImageAlphaNoneSkipFirst) {
       a = 1.0;
   }
   
   CGFloat rgba[] = {r,g,b,a};
   return CGColorCreate(colorSpace, rgba);
}
                       
//
// background safe image resize
//
static UIImage* resizeImage(UIImage* image, CGFloat aspect, CGFloat width, CGFloat height, UIViewContentMode mode)
{
    CGRect src;
    CGRect dst;
    CGFloat scale;

    if (image == nil)
        return nil;
    
    if (width == 0.0 && height == 0.0)
        return image;

    CGFloat image_width = image.size.width;
    CGFloat image_height = image.size.height;

    if (aspect == 0.0)
        aspect = image_width / image_height;
        
    if (width == 0.0)
        width = floor(height * aspect);
    
    if (height == 0.0)
        height = floor(width / aspect);
    
    if (width == image_width && height == image_height)
        return image;

    scale = image.scale;
    image_width = image_width * scale;
    image_height = image_height * scale;

    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
        scale = [[UIScreen mainScreen] scale];
    else
        scale = 1.0;
    
    width = floor(width * scale);
    height = floor(height * scale);
    
    if (mode == UIViewContentModeScaleAspectFit)
    {
        // Aspect Fit
        CGFloat w = width;
        CGFloat h = floor(width / aspect);
        
        if (h > height)
        {
            w = floor(height * aspect);
            h = height;
        }
        
        src = CGRectMake(0,0,image_width,image_height);
        dst = CGRectMake(floor((width - w)/2),floor((height-h)/2),w,h);
    }
    else if (mode == UIViewContentModeScaleAspectFill)
    {
        // Aspect Fill
        
        dst = CGRectMake(0,0,width,height);
        
        if (aspect <= (width / height))
        {
            CGFloat w = image_width;
            CGFloat h = floor(image_width * height / width);
            src = CGRectMake(0,floor((image_height - h)/2),w,h);
        }
        else
        {
            CGFloat w = floor(image_height * width / height);
            CGFloat h = image_height;
            src = CGRectMake(floor((image_width - w)/2),0,w,h);
        }
    }
    else // if (mode == UIViewContentModeScaleToFill)
    {
        src = CGRectMake(0,0,image_width,image_height);
        dst = CGRectMake(0,0,width,height);
    }
    
    CGImageRef imageRef = [image CGImage];
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (alphaInfo == kCGImageAlphaNone)
        alphaInfo = kCGImageAlphaNoneSkipLast;
    if (alphaInfo == kCGImageAlphaFirst)
        alphaInfo = kCGImageAlphaPremultipliedFirst;
    if (alphaInfo == kCGImageAlphaLast)
        alphaInfo = kCGImageAlphaPremultipliedFirst;

    CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, colorSpace, alphaInfo);
    //CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    if (mode == UIViewContentModeScaleAspectFill && !CGRectEqualToRect(src, CGRectMake(0,0,image_width,image_height)))
    {
        CGImageRef source = CGImageCreateWithImageInRect(imageRef, src);
        CGContextDrawImage(bitmap, dst, source);
        CGImageRelease(source);
    }
    else
    {
        CGContextDrawImage(bitmap, dst, imageRef);
    }
    
    // in the AspectFit case fill in the top/bottom or left/right with a average color from the image.
    if (!CGRectEqualToRect(dst, CGRectMake(0,0,width,height)))
    {
        uint32_t* image_ptr = CGBitmapContextGetData(bitmap);
        NSInteger w = 2; // number of scanline/rows to average

        if (dst.origin.x > 0.0)
        {
            CGColorRef left = averageColorRGBA(image_ptr, width, height, colorSpace, alphaInfo, dst.origin.x, dst.origin.y, w, dst.size.height);
            CGColorRef right = averageColorRGBA(image_ptr, width, height, colorSpace, alphaInfo, dst.origin.x + dst.size.width - w, dst.origin.y, w, dst.size.height);
            CGColorRef color = blend(left, right, 0.5);

            CGContextSetFillColorWithColor(bitmap, color);
            CGContextFillRect(bitmap, CGRectMake(0, 0, dst.origin.x, height));
            CGContextFillRect(bitmap, CGRectMake(dst.origin.x + dst.size.width, 0, width - (dst.origin.x + dst.size.width), height));
            CGColorRelease(left);
            CGColorRelease(right);
            CGColorRelease(color);
        }
        else
        {
            CGColorRef top = averageColorRGBA(image_ptr, width, height, colorSpace, alphaInfo, dst.origin.x, dst.origin.y, dst.size.width, w);
            CGColorRef bot = averageColorRGBA(image_ptr, width, height, colorSpace, alphaInfo, dst.origin.x, dst.origin.y + dst.size.height - w, dst.size.width, w);
            CGColorRef color = blend(top, bot, 0.5);

            CGContextSetFillColorWithColor(bitmap, color);
            CGContextFillRect(bitmap, CGRectMake(0, 0, width, dst.origin.y));
            CGContextFillRect(bitmap, CGRectMake(0, dst.origin.y + dst.size.height, width, height - (dst.origin.y + dst.size.height)));
            CGColorRelease(top);
            CGColorRelease(bot);
            CGColorRelease(color);
        }
    }
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    
    UIImage* newImage;
    
    if (scale == 1.0)
        newImage = [UIImage imageWithCGImage:newImageRef];
    else
        newImage = [UIImage imageWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
    
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    CGColorSpaceRelease(colorSpace);
    
    return newImage;
}

@implementation UIImage (Resize)
- (UIImage*)scaledToSize:(CGSize)size aspect:(CGFloat)aspect mode:(UIViewContentMode)mode
{
    return resizeImage(self, aspect, size.width, size.height, mode);
}
- (UIImage*)scaledToSize:(CGSize)size mode:(UIViewContentMode)mode
{
    return resizeImage(self, 0.0, size.width, size.height, mode);
}
- (UIImage*)scaledToSize:(CGSize)size
{
    return [self scaledToSize:size mode:UIViewContentModeScaleToFill];
}
+ (UIImage*)imageWithColor:(UIColor*)color size:(CGSize)size
{
    return [[[UIGraphicsImageRenderer alloc] initWithSize:size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
        [color setFill];
        [context fillRect:CGRectMake(0, 0, size.width, size.height)];
    }];
}
@end


