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
+ (void)reset;

- (void)setCurrentSkin:(NSString*)name;
- (void)reload;

- (nullable UIImage *)loadImage:(NSString *)name;

- (BOOL)exportTo:(NSString*)path progressBlock:(nullable BOOL (NS_NOESCAPE ^)(double progress))block;

@end

NS_ASSUME_NONNULL_END
