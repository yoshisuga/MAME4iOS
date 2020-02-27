//
//  Alert.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Alert)

// replacement for old UIAlertView show (uses new UIAlertController)
-(void)showAlertWithTitle:(NSString* __nullable)title message:(NSString* __nullable)message buttons:(NSArray*)buttons handler:(void (^ __nullable)(NSUInteger button))handler;
-(void)showAlertWithTitle:(NSString* __nullable)title message:(NSString* __nullable)message;
-(void)showAlertWithTitle:(NSString* __nullable)title message:(NSString* __nullable)message timeout:(NSTimeInterval)timeout;
-(void)dismissAlert;

@end

@interface UIAlertController(Dismiss)
-(UIAlertAction*  __nullable)cancelAction;
-(void)dismissWithAction:(UIAlertAction*)action completion: (void (^ __nullable)(void))completion;
-(void)dismissWithDefault;
-(void)dismissWithCancel;
-(void)moveDefaultAction:(NSUInteger)direction;
@end

@interface UIAlertController(setProgress)
- (void)setProgress:(double)value;
@end

@interface UIAlertAction(Helper)
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style image:(UIImage*)image handler:(void (^ __nullable)(UIAlertAction *action))handler;
- (void)callActionHandler;
- (void)setHighlighted:(BOOL)value;
@end

NS_ASSUME_NONNULL_END
