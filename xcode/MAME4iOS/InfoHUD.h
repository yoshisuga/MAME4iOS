//
//  InfoHUD.h
//  Wombat
//
//  Created by Todd Laney on 6/4/20.
//  Copyright © 2020 Wombat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InfoHUD : UIControl

@property(nonatomic) CGFloat spacing;
@property(nonatomic) BOOL moveable;
@property(nonatomic) BOOL sizeable;
@property(null_resettable,nonatomic,strong) UIFont* font;
@property(readonly,nonatomic,strong) NSString* changedKey;

- (NSArray<NSString*>*)allKeys;

- (void)removeAll;

- (void)addValue:(id)value;
- (void)addValue:(id)value forKey:(NSString *)key;
- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format;
- (void)addValue:(id)value forKey:(nullable NSString *)key format:(nullable NSString*)format min:(nullable id)min max:(nullable id)max;
- (void)addValue:(id)value forKey:(nullable NSString *)key format:(nullable NSString*)format min:(nullable id)min max:(nullable id)max step:(nullable id)step;
- (void)addValues:(NSDictionary*)values;

- (void)addTitle:(NSString*)str;
- (void)addText:(NSString*)str;
- (void)addView:(UIView*)view;
- (void)addImage:(UIImage*)image;
- (void)addSeparator;

// toolbar and button items can be a UIImage or a NSString
// strings starting with ":symbol-name:fallback:" will be expanded to a SF Symbol (or use fallback text)
- (void)addToolbar:(NSArray*)items handler:(void (^)(NSUInteger button))handler;
- (void)addButtons:(NSArray*)items color:(nullable UIColor*)color handler:(void (^)(NSUInteger button))handler;
- (void)addButtons:(NSArray*)items handler:(void (^)(NSUInteger button))handler;
- (void)addButton:(id)item color:(nullable UIColor*)color handler:(void (^)(void))handler;
- (void)addButton:(id)item handler:(void (^)(void))handler;

- (void)setValue:(nullable id)value forKey:(NSString *)key;
- (void)setValues:(NSDictionary*)values;

- (id)valueForKey:(NSString *)key;
- (NSDictionary*)getValues;

- (void)handleButtonPress:(UIPressType)type;

@end

// HUD Button style (based on UIAlertActionStyle)
typedef NS_ENUM(NSInteger, HUDButtonStyle) {
    HUDButtonStyleDefault = UIAlertActionStyleDefault,
    HUDButtonStyleCancel = UIAlertActionStyleCancel,
    HUDButtonStyleDestructive = UIAlertActionStyleDestructive,
    HUDButtonStylePlain
};

// a simple UIViewController for InfoHUD
@interface HUDViewController : UIViewController

- (void)addButtons:(NSArray*)items style:(HUDButtonStyle)style handler:(void (^)(NSUInteger button))handler;
- (void)addButton:(id)item style:(HUDButtonStyle)style handler:(void (^)(void))handler;
- (void)onCancel:(void (^)(void))handler;
- (void)onDismiss:(void (^)(void))handler;

- (void)handleButtonPress:(UIPressType)type;

@end

// a UIAlertViewController(ish) compatible interface
@interface HUDAlertController : HUDViewController

@property (nonatomic, readonly) NSArray<UIAlertAction *> *actions;
@property (nonatomic, strong, nullable) UIAlertAction *preferredAction;

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

-(void)addAction:(UIAlertAction *)action;

@end

NS_ASSUME_NONNULL_END
