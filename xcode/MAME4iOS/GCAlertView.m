//
//  GCAlertView.m
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 6/7/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "GCAlertView.h"

@implementation GCAlertView

- (void) awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 10.0;
    _buttonAImageView.image = [[UIImage imageNamed:@"button_a"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _buttonBImageView.image = [[UIImage imageNamed:@"button_b"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _buttonAImageView.tintColor = [UIColor redColor];
    _buttonBImageView.tintColor = [UIColor greenColor];
}

- (void)dealloc {
    [_messageLabel release];
    [_okLabel release];
    [_cancelLabel release];
    [_buttonAImageView release];
    [_buttonBImageView release];
    [super dealloc];
}
@end
