//
//  Options.h
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 1/12/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Options : NSObject

- (void)loadOptions;
- (void)saveOptions;
+ (void)resetOptions;


@property (class, readonly, strong) NSArray* arrayEmuRes;
@property (class, readonly, strong) NSArray* arrayFSValue;
@property (class, readonly, strong) NSArray* arrayOverscanValue;
@property (class, readonly, strong) NSArray* arrayEmuSpeed;
@property (class, readonly, strong) NSArray* arrayControlType;
@property (class, readonly, strong) NSArray* arrayBorder;
@property (class, readonly, strong) NSArray* arrayFilter;
@property (class, readonly, strong) NSArray* arrayEffect;
@property (class, readonly, strong) NSArray* arrayColorSpace;

@property (readwrite,assign) int keepAspectRatioPort;
@property (readwrite,assign) int keepAspectRatioLand;

@property (readwrite,strong) NSString *filterPort;
@property (readwrite,strong) NSString *filterLand;

@property (readwrite,strong) NSString *borderPort;
@property (readwrite,strong) NSString *borderLand;

@property (readwrite,strong) NSString *effectPort;
@property (readwrite,strong) NSString *effectLand;

@property (readwrite,strong) NSString *sourceColorSpace;
@property (readwrite,assign) int useMetal;

@property (readwrite,assign) int integerScalingOnly;

@property (readwrite,assign) int showFPS;
@property (readwrite,assign) int animatedButtons;
@property (readwrite,assign) int fourButtonsLand;
@property (readwrite,assign) int fullLand;
@property (readwrite,assign) int fullPort;
@property (readwrite,assign) int fullLandJoy;
@property (readwrite,assign) int fullPortJoy;

@property (readwrite,assign) int btDeadZoneValue;
@property (readwrite,assign) int touchDeadZone;

@property (readwrite,assign) int overscanValue;
@property (readwrite,assign) int tvoutNative;

@property (readwrite,assign) int touchtype;
@property (readwrite,assign) int analogDeadZoneValue;

@property (readwrite,assign) int controltype;
@property (readwrite,assign) int showINFO;

@property (readwrite,assign) int soundValue;

@property (readwrite,assign) int throttle;
@property (readwrite,assign) int fsvalue;
@property (readwrite,assign) int sticktype;
@property (readwrite,assign) int numbuttons;
@property (readwrite,assign) int aplusb;
@property (readwrite,assign) int cheats;
@property (readwrite,assign) int sleep;

@property (readwrite,assign) int forcepxa;
@property (readwrite,assign) int emures;
@property (readwrite,assign) int p1aspx;

@property (readwrite,assign) int filterClones;
@property (readwrite,assign) int filterFavorites;
@property (readwrite,assign) int filterNotWorking;
@property (readwrite,assign) int manufacturerValue;
@property (readwrite,assign) int yearGTEValue;
@property (readwrite,assign) int yearLTEValue;
@property (readwrite,assign) int driverSourceValue;
@property (readwrite,assign) int categoryValue;

@property (readwrite,strong,nullable) NSString *filterKeyword;

@property (readwrite,assign) int lowlsound;
@property (readwrite,assign) int vsync;
@property (readwrite,assign) int threaded;
@property (readwrite,assign) int dblbuff;

@property (readwrite,assign) int mainPriority;
@property (readwrite,assign) int videoPriority;

@property (readwrite,assign) int autofire;

@property (readwrite,assign) int hiscore;

@property (readwrite,assign) int buttonSize;
@property (readwrite,assign) int stickSize;
@property (readwrite,assign) int nintendoBAYX;

@property (readwrite,assign) int wpantype;
@property (readwrite,strong,nullable) NSString *wfpeeraddr;
@property (readwrite,assign) int wfport;
@property (readwrite,assign) int wfframesync;
@property (readwrite,assign) int btlatency;

@property (readwrite,assign) int vbean2x;
@property (readwrite,assign) int vantialias;
@property (readwrite,assign) int vflicker;

@property (readwrite,assign) int emuspeed;

@property (readwrite,assign) int lightgunBottomScreenReload;
@property (readwrite,assign) int lightgunEnabled;

@property (readwrite,assign) int turboXEnabled;
@property (readwrite,assign) int turboYEnabled;
@property (readwrite,assign) int turboAEnabled;
@property (readwrite,assign) int turboBEnabled;
@property (readwrite,assign) int turboLEnabled;
@property (readwrite,assign) int turboREnabled;

@property (readwrite,assign) int touchAnalogEnabled;
@property (readwrite,assign) CGFloat touchAnalogSensitivity;
@property (readwrite,assign) int touchAnalogHideTouchDirectionalPad;
@property (readwrite,assign) int touchAnalogHideTouchButtons;

@property (readwrite,assign) int touchDirectionalEnabled;

@property (readwrite,assign) CGFloat touchControlsOpacity;

@property (readwrite,assign) int mainThreadType;
@property (readwrite,assign) int videoThreadType;


@end

@interface NSArray (optionAtIndex)
// a "safe" version of objectAtIndex
- (id)objectAtIndex:(NSUInteger)index withDefault:(nullable id)defaultObject;
// return the option at index, or default to the first one
- (NSString*)optionAtIndex:(NSUInteger)index;
// find and return option index given a name, default to first if not found
- (NSUInteger)indexOfOption:(NSString*)string;
// find and return option name given a string, default to first if not found
- (NSString*)optionName:(NSString*)string;
// find and return option data given a string, default to first if not found
- (NSString*)optionData:(NSString*)string;
@end


NS_ASSUME_NONNULL_END
