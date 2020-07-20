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

// load an image from skins, in priority order, or return built-in default.
- (nullable UIImage *)loadImage:(NSString *)name;
// get a value from one of the skin.json files, in priority order.
- (id)valueForKeyPath:(NSString*)keyPath;

// export the current skin data, if the skin is the default skin export everything, else only the changes.
- (BOOL)exportTo:(NSString*)path progressBlock:(nullable BOOL (NS_NOESCAPE ^)(double progress))block;

@end

NS_ASSUME_NONNULL_END
