//
//  SystemImage.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>

#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0)

#define systemImageNamed __systemImageNamed

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SystemImage)

// a polyfill for [UIImage systemImageNamed:] for pre-iOS13, will use fallback image in app bundle or nil if none
+(nullable UIImage*)__systemImageNamed:(NSString*)name;

@end

NS_ASSUME_NONNULL_END

#endif
