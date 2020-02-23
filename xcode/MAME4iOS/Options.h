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
{
    NSMutableArray*      optionsArray;
    
@public  int keepAspectRatioPort;
@public  int keepAspectRatioLand;
@public  int smoothedPort;
@public  int smoothedLand;
    
@public  int tvFilterPort;
@public  int tvFilterLand;
@public  int scanlineFilterPort;
@public  int scanlineFilterLand;
    
@public  int showFPS;
@public  int animatedButtons;
@public  int fourButtonsLand;
@public  int fullLand;
@public  int fullPort;
    
@public  int skinValue;
    
@public  int btDeadZoneValue;
@public  int touchDeadZone;
    
@public  int overscanValue;
@public  int tvoutNative;
    
@public  int touchtype;
@public  int analogDeadZoneValue;
    
@public  int controltype;
@public  int showINFO;
    
@public int soundValue;
    
@public int throttle;
@public int fsvalue;
@public int sticktype;
@public int numbuttons;
@public int aplusb;
@public int cheats;
@public int sleep;
    
@public int forcepxa;
@public int emures;
@public int p1aspx;
    
@public int filterClones;
@public int filterFavorites;
@public int filterNotWorking;
@public int manufacturerValue;
@public int yearGTEValue;
@public int yearLTEValue;
@public int driverSourceValue;
@public int categoryValue;
    
@public NSString *filterKeyword;
    
@public int lowlsound;
@public int vsync;
@public int threaded;
@public int dblbuff;
    
@public int mainPriority;
@public int videoPriority;
    
@public int autofire;
@public int hiscore;
    
@public int buttonSize;
@public int stickSize;
    
@public int wpantype;
@public NSString *wfpeeraddr;
@public int wfport;
@public int wframesync;
@public int btlatency;
    
@public int vbean2x;
@public int vantialias;
@public int vflicker;
    
@public int emuspeed;
    
@public int lightgunBottomScreenReload;
@public int lightgunEnabled;
    
@public int touchAnalogEnabled;
@public CGFloat touchAnalogSensitivity;
@public int touchAnalogHideTouchDirectionalPad;
@public int touchAnalogHideTouchButtons;
    
@public int touchDirectionalEnabled;
    
/* these will be autosynthesized
@public int turboXEnabled;
@public int turboYEnabled;
@public int turboAEnabled;
@public int turboBEnabled;
@public int turboLEnabled;
@public int turboREnabled;
*/
    
@public CGFloat touchControlsOpacity;
    
}

- (void)loadOptions;
- (void)saveOptions;

@property (readwrite,assign) int keepAspectRatioPort;
@property (readwrite,assign) int keepAspectRatioLand;
@property (readwrite,assign) int smoothedPort;
@property (readwrite,assign) int smoothedLand;

@property (readwrite,assign) int tvFilterPort;
@property (readwrite,assign) int tvFilterLand;

@property (readwrite,assign) int scanlineFilterPort;
@property (readwrite,assign) int scanlineFilterLand;

@property (readwrite,assign) int showFPS;
@property (readwrite,assign) int animatedButtons;
@property (readwrite,assign) int fourButtonsLand;
@property (readwrite,assign) int fullLand;
@property (readwrite,assign) int fullPort;

@property (readwrite,assign) int skinValue;

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

NS_ASSUME_NONNULL_END
