//
//  UIViewController+Alert
//  MAME4iOS
//
//  Created by Todd Laney on 10/19/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "Alert.h"

@implementation UIViewController (Alert)

-(void)showAlertWithTitle:(NSString*)title message:(NSString*)message buttons:(NSArray*)buttons handler:(void (^ __nullable)(NSUInteger button))handler
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    for (NSUInteger i=0; i<buttons.count; i++)
    {
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        
        if ([buttons[i] caseInsensitiveCompare:@"Cancel"] == NSOrderedSame)
            style = UIAlertActionStyleCancel;
        
        [alert addAction:[UIAlertAction actionWithTitle:buttons[i] style:style handler:^(UIAlertAction* action) {
            if (handler != nil)
                handler(i);
        }]];
        
        if (style != UIAlertActionStyleCancel && alert.preferredAction == nil)
            alert.preferredAction = alert.actions.lastObject;
    }
    UIViewController* vc = self;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    [self showAlertWithTitle:title message:message buttons:@[@"OK"] handler:nil];
}

-(void)showAlertWithTitle:(NSString*)title message:(NSString*)message timeout:(NSTimeInterval)timeout
{
    [self showAlertWithTitle:title message:message];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissAlert];
    });
}

-(void)dismissAlert
{
    if (![[self presentedViewController] isKindOfClass:[UIAlertController class]])
        return;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation UIAlertController(setProgress)

// a simple hack to have a progress bar in a Alert
// you must call setProgress at least once before presenting Alert
- (void)setProgress:(double)value
{
    if (![NSThread isMainThread]) {
        return dispatch_async(dispatch_get_main_queue(), ^{
            [self setProgress:value];
        });
    }

    if (self.textFields.count == 0)
    {
        UIColor* tintColor = self.view.tintColor;
        [self addTextFieldWithConfigurationHandler:^(UITextField* textField) {
            textField.enabled = NO;
            textField.font = [UIFont fontWithName:@"Menlo" size:32.0];
            textField.textColor = tintColor;
        }];
    }
    UITextField* textField = self.textFields.firstObject;

    /// make a progress bar using  [block characters](https://en.wikipedia.org/wiki/Block_Elements)
    static NSString* blocks[] = {@"",@"▏",@"▎",@"▍",@"▌",@"▋",@"▊",@"▉",@"█"};
    CGFloat width = textField.bounds.size.width;
    CGFloat charw = [blocks[8] sizeWithAttributes:@{NSFontAttributeName:textField.font}].width;
    int n = (int)round(8.0 * MIN(value,1.0) * floor(width / charw));
    textField.text = [[@"" stringByPaddingToLength:n/8 withString:blocks[8] startingAtIndex:0] stringByAppendingString:blocks[n % 8]];
}
@end

@implementation UIAlertController(Dismiss)

-(UIAlertAction*)cancelAction
{
    for (UIAlertAction* action in self.actions)
    {
        if (action.style == UIAlertActionStyleCancel)
            return action;
    }
    return nil;
}
-(void)dismissWithAction:(UIAlertAction*)action completion: (void (^ __nullable)(void))completion
{
    if (action == nil)
        return;
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [action callActionHandler];
        if (completion != nil)
            completion();
    }];
}
-(void)dismissWithDefault
{
    return [self dismissWithAction:self.preferredAction completion:nil];
}
-(void)dismissWithCancel
{
    return [self dismissWithAction:self.cancelAction completion:nil];
}
-(void)moveDefaultAction:(NSUInteger)direction
{
    NSInteger index = [self.actions indexOfObjectIdenticalTo:self.preferredAction];
    NSUInteger count = [self.actions count];
    
    if (self.actions.lastObject.style == UIAlertActionStyleCancel)
        count--;
    
    if (count == 1 && index != NSNotFound)
        return;

    if (index == NSNotFound)
        index = 0;
    else
        index = index + direction;
    
    index = MIN(MAX(index, 0), count-1);
    [self.preferredAction setHighlighted:NO];
    self.preferredAction = self.actions[index];
    [self.preferredAction setHighlighted:YES];
}
@end

@implementation UIAlertAction(Missing)
- (void)callActionHandler
{
    if ([self respondsToSelector:@selector(handler)])
    {
        void (^handler)(UIAlertAction *) = [self valueForKey:@"handler"];
        if (handler != nil)
            handler(self);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (void)setHighlighted:(BOOL)value
{
    if ([self respondsToSelector:@selector(_representer)])
    {
        id view = [self valueForKey:@"_representer"];
        if ([view respondsToSelector:@selector(setHighlighted:)])
            [view setHighlighted:value];
    }
}
#pragma clang diagnostic pop
@end


