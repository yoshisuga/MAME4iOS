//
//  GCAlertView.h
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 6/7/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCAlertView : UIView

@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (retain, nonatomic) IBOutlet UILabel *okLabel;
@property (retain, nonatomic) IBOutlet UILabel *cancelLabel;
@property (retain, nonatomic) IBOutlet UIImageView *buttonAImageView;
@property (retain, nonatomic) IBOutlet UIImageView *buttonBImageView;

@end

NS_ASSUME_NONNULL_END
