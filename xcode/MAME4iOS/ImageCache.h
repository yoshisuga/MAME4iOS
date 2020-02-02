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
@end

@interface UIImage (Resize)
- (UIImage*)scaledToSize:(CGSize)size mode:(UIViewContentMode)mode;
- (UIImage*)scaledToSize:(CGSize)size;
@end
