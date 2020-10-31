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
    }
    
    if (alert.cancelAction != nil && buttons.count == 2)
    {
        if (alert.cancelAction == alert.actions.firstObject)
            alert.preferredAction = alert.actions.lastObject;
        else
            alert.preferredAction = alert.actions.firstObject;
    }
    if (alert.cancelAction == nil && buttons.count == 1)
    {
        alert.preferredAction = alert.actions.firstObject;
    }
        
    [self.topViewController presentViewController:alert animated:YES completion:nil];
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
    if (![self.topViewController isKindOfClass:[UIAlertController class]])
        return;
    
    [self.topViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(UIViewController*)topViewController
{
    UIViewController* vc = self;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    return vc;
}


@end

@implementation UIAlertController(setProgress)

// a simple hack to have a progress bar in a Alert
// you must call setProgress at least once before presenting Alert
- (void)setProgress:(double)value text:(NSString*)text
{
    if (![NSThread isMainThread]) {
        return dispatch_async(dispatch_get_main_queue(), ^{
            [self setProgress:value text:text];
        });
    }
    
    if (self.textFields.count == 0)
    {
        UIColor* tintColor = self.view.tintColor;
        [self addTextFieldWithConfigurationHandler:^(UITextField* textField) {
            textField.enabled = NO;
            textField.font = [UIFont fontWithName:@"Menlo" size:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize];
            textField.textColor = tintColor;
        }];
        if (text != nil) {
            [self addTextFieldWithConfigurationHandler:^(UITextField* textField) {
                textField.enabled = NO;
            }];
        }
    }
    UITextField* textField = self.textFields.firstObject;

    /// make a progress bar using  [block characters](https://en.wikipedia.org/wiki/Block_Elements)
    static NSString* blocks[] = {@"",@"▏",@"▎",@"▍",@"▌",@"▋",@"▊",@"▉",@"█"};
    CGFloat width = textField.bounds.size.width;
    CGFloat charw = [blocks[8] sizeWithAttributes:@{NSFontAttributeName:textField.font}].width;
    int n = (int)round(8.0 * MIN(value,1.0) * floor(width / charw));
    textField.text = [[@"" stringByPaddingToLength:n/8 withString:blocks[8] startingAtIndex:0] stringByAppendingString:blocks[n % 8]];
    
    if (text != nil && self.textFields.count == 2) {
        UITextField* textField = self.textFields.lastObject;
        textField.text = text;
    }
}
- (void)setProgress:(double)value
{
    [self setProgress:value text:nil];
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
-(void)dismissWithTitle:(NSString*)title
{
    [self dismissWithAction:[self.actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title BEGINSWITH[c] %@", title]].firstObject completion:nil];
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

@implementation UIAlertAction(Helper)

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style image:(UIImage*)image handler:(void (^ __nullable)(UIAlertAction *action))handler
{
    UIAlertAction* action = [self actionWithTitle:title style:style handler:handler];
    if ([action respondsToSelector:@selector(image)])
        [action setValue:image forKey:@"image"];
    return action;
}

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
        
        // scroll the just hilighted menu item into view.
        if (value && [view isKindOfClass:[UIView class]])
        {
            UIScrollView* scroll = view;
            while (scroll != nil && ![scroll isKindOfClass:[UIScrollView class]])
                scroll = (UIScrollView*)[scroll superview];
            
            if (scroll != nil)
            {
                CGRect scroll_bounds = scroll.bounds;
                CGRect rect = [view convertRect:[view bounds] toView:scroll];

                if (CGRectGetMaxY(rect) >= CGRectGetMaxY(scroll_bounds) - rect.size.height * 0.5)
                    rect = CGRectOffset(rect, 0, rect.size.height);
                
                if (CGRectGetMinY(rect) <= CGRectGetMinY(scroll_bounds) + rect.size.height * 0.5)
                    rect = CGRectOffset(rect, 0, -rect.size.height);

                [scroll scrollRectToVisible:rect animated:YES];
            }
        }
    }
}
#pragma clang diagnostic pop

@end


