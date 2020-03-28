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
- (void)getImage:(NSURL*)url size:(CGSize)size localURL:(NSURL*)localURL completionHandler:(ImageCacheCallback)handler;
- (void)getImage:(NSURL*)url size:(CGSize)size completionHandler:(ImageCacheCallback)handler;
- (void)getImage:(NSURL*)url completionHandler:(ImageCacheCallback)handler;
- (void)cancelImage:(NSURL*)url;
@end

@interface UIImage (Resize)
- (UIImage*)scaledToSize:(CGSize)size aspect:(CGFloat)aspect mode:(UIViewContentMode)mode;
- (UIImage*)scaledToSize:(CGSize)size mode:(UIViewContentMode)mode;
- (UIImage*)scaledToSize:(CGSize)size;
- (UIColor*)averageColor:(UIRectEdge)edge width:(CGFloat)width;
- (UIColor*)averageColor;
@end

