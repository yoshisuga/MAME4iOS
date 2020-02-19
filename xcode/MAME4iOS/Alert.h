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
-(UIAlertAction*)cancelAction;
-(void)dismissWithAction:(UIAlertAction*)action;
-(void)dismissWithDefault;
-(void)dismissWithCancel;
-(void)moveDefaultAction:(NSUInteger)direction;
@end

@interface UIAlertController(setProgress)
- (void)setProgress:(double)value;
@end

@interface UIAlertAction(Missing)
- (void)callActionHandler;
- (void)setHighlighted:(BOOL)value;
@end

NS_ASSUME_NONNULL_END
