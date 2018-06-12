/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */

#import <UIKit/UIKit.h>

@interface Options : NSObject
{
   NSMutableArray*	  optionsArray;

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
    
   @public int turboXEnabled;
   @public int turboYEnabled;
   @public int turboAEnabled;
   @public int turboBEnabled;
   @public int turboLEnabled;
   @public int turboREnabled;
    
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

@property (readwrite,assign) NSString *filterKeyword;

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
@property (readwrite,assign) NSString *wfpeeraddr;
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

@property (readwrite,assign) int mainThreadType;
@property (readwrite,assign) int videoThreadType;

@end

enum OptionSections
{
    kSupportSection = 0,
    kMultiplayerSection = 1,
    kFilterSection = 2,
    kInputSection = 3,
    kPortraitSection = 4,
    kLandscapeSection = 5,
    kMiscSection = 6,
    kDefaultsSection = 7,
    kNumSections = 8
};

enum ListOptionType
{
    kTypeNumButtons,
    kTypeEmuRes,
    kTypeStickType,
    kTypeTouchType,
    kTypeControlType,
    kTypeAnalogDZValue,
    kTypeBTDZValue,
    kTypeSoundValue,
    kTypeFSValue,
    kTypeOverscanValue,
    kTypeSkinValue,
    kTypeManufacturerValue,
    kTypeYearGTEValue,
    kTypeYearLTEValue,
    kTypeDriverSourceValue,
    kTypeCategoryValue,
    kTypeVideoPriorityValue,
    kTypeMainPriorityValue,
    kTypeAutofireValue,
    kTypeStickSizeValue,
    kTypeButtonSizeValue,
    kTypeArrayWPANtype,
    kTypeWFframeSync,
    kTypeBTlatency,
    kTypeEmuSpeed,
    kTypeVideoThreadTypeValue,
    kTypeMainThreadTypeValue
};

@class EmulatorController;

@interface OptionsController : UIViewController  <UITableViewDelegate, UITableViewDataSource>
{
    EmulatorController*  emuController;
    
    UISwitch*		  switchKeepAspectPort;
    UISwitch*		  switchKeepAspectLand;
    UISwitch*		  switchSmoothedPort;
    UISwitch*		  switchSmoothedLand;
    
    UISwitch*		  switchTvFilterPort;
    UISwitch*		  switchScanlineFilterPort;
    
    UISwitch*		  switchTvFilterLand;
    UISwitch*		  switchScanlineFilterLand;
    
    UISwitch*		  switchShowFPS;
    UISwitch*		  switchShowINFO;
    
    UISwitch*		  switchfullLand;
    UISwitch*		  switchfullPort;
        
    UISwitch *switchThrottle;
    
    UISwitch *switchSleep;
    
    UISwitch *switchForcepxa;
    
    NSArray *arrayEmuRes;
    
    NSArray *arrayFSValue;
    NSArray *arrayOverscanValue;
    NSArray *arraySkinValue;
    
    UISwitch *switchLowlsound;
    
    NSArray  *arrayEmuSpeed;
}

- (void)optionChanged:(id)sender;

@property (nonatomic, assign) EmulatorController *emuController;

@end
