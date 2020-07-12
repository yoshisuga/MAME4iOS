//
//  SkinManager.h
//  MAME4iOS
//
//  Created by Todd Laney on 7/11/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSkinNameDefault @"Default"

NS_ASSUME_NONNULL_BEGIN

@interface SkinManager : NSObject

+ (NSArray<NSString*>*)getSkinNames;
- (void)update;

- (void)setCurrentSkin:(NSString*)name;

- (nullable UIImage *)loadImage:(NSString *)name;

- (void)exportToURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
