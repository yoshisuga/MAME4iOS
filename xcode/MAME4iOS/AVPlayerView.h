//
//  AVPlayerView.h
//  MAME4iOS
//
//  Created by ToddLa on 3/24/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayerView : UIView

- (instancetype)initWithURL:(NSURL*)url;
- (void)play;

@end

NS_ASSUME_NONNULL_END
