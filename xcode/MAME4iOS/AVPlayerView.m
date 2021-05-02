//
//  AVPlayerView.m
//  MAME4iOS
//
//  Created by ToddLa on 3/24/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerView.h"

@implementation AVPlayer_View {
    AVPlayerLayer* _layer;
}

- (instancetype)initWithURL:(NSURL*)url
{
    self = [super initWithFrame:CGRectZero];
    
    _player = [AVPlayer playerWithURL:url];
    _layer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _layer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.layer addSublayer:_layer];
    
#ifdef DEBUG
    if (@available(iOS 13.4, tvOS 13.4, *)) {
        AVPlayerHDRMode hdr = [AVPlayer availableHDRModes];
        NSLog(@"HDR: %@", [AVPlayer eligibleForHDRPlayback] ? @"YES" : @"NO");
        NSLog(@"HDR MODES: %@%@%@",
          (hdr & AVPlayerHDRModeHLG) ? @"HLG " : @"",
          (hdr & AVPlayerHDRModeHDR10) ? @"HDR10 " : @"",
          (hdr & AVPlayerHDRModeDolbyVision) ? @"Dolby " : @"");
    }
#endif
    
    return self;
}

- (void)layoutSubviews {
    _layer.frame = self.bounds;
}

@end
