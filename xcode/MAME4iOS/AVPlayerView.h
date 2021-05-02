//
//  AVPlayerView.h
//  MAME4iOS
//
//  Created by ToddLa on 3/24/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayer_View : UIView

- (instancetype)initWithURL:(NSURL*)url;

@property (nonatomic, readonly) AVPlayer* player;

@end

NS_ASSUME_NONNULL_END
