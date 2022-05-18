//
//  ImageCache.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ImageCacheCallback) (UIImage* image);

@interface ImageCache : NSObject
+ (ImageCache*) sharedInstance;
- (void)getImage:(NSURL*)url localURL:(NSURL*)localURL completionHandler:(ImageCacheCallback)handler;
- (void)getImage:(NSURL*)url completionHandler:(ImageCacheCallback)handler;
- (UIImage*)getImage:(NSURL*)url;
- (void)cancelImage:(NSURL*)url;
- (void)flush;
- (void)flush:(NSURL*)url;
// get count of people waiting for URL to load
- (NSInteger)getLoadingCount:(NSURL*)url;
@end

@interface UIImage (Resize)
- (UIImage*)scaledToSize:(CGSize)size mode:(UIViewContentMode)mode;
- (UIImage*)scaledToSize:(CGSize)size;
+ (UIImage*)imageWithColor:(UIColor*)color size:(CGSize)size;
@end

