//
//  ImageCache.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#import "ImageCache.h"

#define ImageCacheLog 0
#if ImageCacheLog == 0
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

- (void)flush:(NSURL*)url
{
    [cache removeObjectForKey:url];
}

- (void)getData:(NSURL*)url localURL:(NSURL*)localURL completionHandler:(void (^)(NSData* data, NSError* error))handler
{
    NSParameterAssert(url != nil);
    NSParameterAssert(localURL == nil || localURL.isFileURL);

    NSURLSession* session = [NSURLSession sharedSession];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
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

        if (localURL != nil && data != nil && error == nil) {
            if (![data writeToURL:localURL atomically:YES]) {
                // if we failed to write data, create directory and try again.
                [NSFileManager.defaultManager createDirectoryAtURL:localURL.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
                if (![data writeToURL:localURL atomically:YES])
                    NSLog(@"ERROR WRITING LOCAL IMAGE DATA: %@", localURL.path);
            }
        }

        handler(data, error);
    }];
    [task resume];
    
    NSParameterAssert([NSThread isMainThread]);
    self->task_dict[url] = task;
}

- (void)getImage:(NSURL*)url localURL:(NSURL*)localURL completionHandler:(ImageCacheCallback)handler
{
    NSParameterAssert([NSThread isMainThread]);
    NSParameterAssert(handler != nil);
    NSParameterAssert(localURL == nil || [localURL isFileURL]);

    NSLog(@"IMAGE CACHE: getImage: %@", url.path);
    
    if (url == nil) {
        NSLog(@"....URL is NIL");
        return handler(nil);
    }
    
    id val = [cache objectForKey:url];
    
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
    if (localURL != nil)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localURL.path])
        {
            NSLog(@"....IMAGE LOCAL CACHE HIT");
            UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localURL]];
            [cache setObject:(image ?: [NSNull null]) forKey:url];
            return handler(image);
        }
    }
    
    NSLog(@"....IMAGE CACHE MISS");
    NSParameterAssert(val == nil);
    [cache setObject:[NSMutableArray arrayWithObject:handler] forKey:url];
    
    [self getData:url localURL:localURL completionHandler:^(NSData *data, NSError* error) {
        NSLog(@"IMAGE CACHE DATA: %d bytes", (int)[data length]);
        UIImage* image = [UIImage imageWithData:data];

        dispatch_async(dispatch_get_main_queue(), ^{
            self->task_dict[url] = nil;
            NSArray* callbacks = [self->cache objectForKey:url];
            
            if (![callbacks isKindOfClass:[NSArray class]]) {
                NSLog(@"IMAGE LOAD CANCELED: %@", url.lastPathComponent);
                [self->cache removeObjectForKey:url];
            }
            else if (image == nil && error != nil && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
                NSLog(@"IMAGE LOAD CANCELED: %@ [%d clients]", url.lastPathComponent, (int)[callbacks count]);
                [self->cache removeObjectForKey:url];
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
                    [self->cache setObject:[NSDate date] forKey:url];
                else
                    [self->cache setObject:(image ?: [NSNull null]) forKey:url];
                
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

- (void)getImage:(NSURL*)url completionHandler:(ImageCacheCallback)handler
{
    [self getImage:url localURL:nil completionHandler:handler];
}

// get a image from the cache without loading.
- (UIImage*)getImage:(NSURL*)url
{
    NSParameterAssert([NSThread isMainThread]);

    id val = [cache objectForKey:url];

    if ([val isKindOfClass:[UIImage class]])
        return val;
    
    return nil;
}
     
 // get count of people waiting for URL to load
 - (NSInteger)getLoadingCount:(NSURL*)url
 {
     NSParameterAssert([NSThread isMainThread]);

     id val = [cache objectForKey:url];

     if ([val isKindOfClass:[NSArray class]])
         return [(id)val count];
     
     return 0;
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
                       
//
// background safe image resize
//
static UIImage* resizeImage(UIImage* image, CGFloat width, CGFloat height, UIViewContentMode mode)
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
    
    CGFloat aspect = image_width / image_height;
        
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
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    // in the AspectFit case fill background with black
    if (!CGRectEqualToRect(dst, CGRectMake(0,0,width,height)))
    {
        CGContextSetFillColorWithColor(bitmap, UIColor.blackColor.CGColor);
        CGContextFillRect(bitmap, CGRectMake(0, 0, width,height));
    }
    
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
- (UIImage*)scaledToSize:(CGSize)size mode:(UIViewContentMode)mode
{
    return resizeImage(self, size.width, size.height, mode);
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


