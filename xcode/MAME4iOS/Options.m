//
//  Options.m
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 1/12/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#include "myosd.h"
#import "Options.h"
#import "Globals.h"

@implementation Options

#pragma mark - class properties

+ (NSArray*)arrayEmuRes {
    return @[@"Auto",@"320x200",@"320x240",@"400x300",@"480x300",@"512x384",@"640x400",@"640x480 (SD)",@"800x600",@"1024x768",@"1280x960",
             @"1440x1080 (HD)",@"1600x1200",@"1920x1440",@"2048x1536",@"2880x2160 (UHD)"];
}
+ (NSArray*)arrayFSValue {
    return [[NSArray alloc] initWithObjects:@"Auto",@"None", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10", nil];
}
+ (NSArray*)arrayOverscanValue {
    return [[NSArray alloc] initWithObjects:@"None",@"1", @"2", @"3",@"4", @"5", @"6", nil];
}
+ (NSArray*)arrayEmuSpeed {
    return [[NSArray alloc] initWithObjects: @"Default",
                     @"50%", @"60%", @"70%", @"80%", @"85%",@"90%",@"95%",@"100%",
                     @"105%", @"110%", @"115%", @"120%", @"130%",@"140%",@"150%",
                     nil];
}
+ (NSArray*)arrayControlType {
    return @[@"Keyboard or 8BitDo",@"iCade or compatible",@"iCP, Gametel",@"iMpulse"];
}
// border string is of the form:
//        <Friendly Name> : <resource image name>
//        <Friendly Name> : <resource image name>, <fraction of border that is opaque>
//        <Friendly Name> : #RRGGBB
//        <Friendly Name> : #RRGGBBAA, <border width>
//        <Friendly Name> : #RRGGBBAA, <border width>, <corner radius>
+ (NSArray*)arrayBorder {
    return @[@"None",
             @"Dark : border-dark",
             @"Light : border-light",
             @"Solid : #007AFFaa, 2.0, 8.0",
#ifdef DEBUG
             @"Test : border-test",
             @"Test 1: border-test, 0.5",
             @"Test 2: border-test, 1.0",
             @"Red : #ff0000, 2.0",
             @"Blue : #0000FF",
             @"Green : #00FF00ee, 4.0, 16.0",
             @"Purple : #80008080, 4.0, 16.0",
             @"Tint : #007Aff, 2.0, 8.0",
#endif
    ];
}
+ (NSArray*)arrayFilter {
    return @[@"Nearest",
             @"Linear",
    ];
}

// CoreGraphics effect string is of the form:
//        <Friendly Name> : <overlay image> [,<overlay image> ...]
//
+ (NSArray*)arrayCoreGraphicsEffects {
    return @[@"None",
             @"Scanline : effect-scanline",
             @"CRT : effect-crt, effect-scanline",
#ifdef DEBUG
             @"Test Dot : effect-dot",
             @"Test All : effect-crt, effect-scanline, effect-dot",
#endif
    ];
}

// Metal effect string is of the form:
//        <Friendly Name> : <shader description>
//
// NOTE: see MetalView.h for what a <shader description> is.
//
// NOTE arrayCoreGraphicsEffects and arrayMetalEffects should use the same friendly name
// for similar effects, so if the user turns off/on metal the choosen effect wont get reset to default.
//
+ (NSArray*)arrayMetalEffects {
    return @[@"None",
             @"Simple CRT: simpleCRT, mame-screen-dst-rect, mame-screen-src-rect,\
                 curv_vert     = 5.0 1.0 10.0,\
                 curv_horiz    = 4.0 1.0 10.0,\
                 curv_strength = 0.25 0.0 1.0,\
                 light_boost   = 1.3 0.1 3.0, \
                 vign_strength = 0.05 0.0 1.0,\
                 zoom_out      = 1.1 0.01 5.0",
#ifdef DEBUG
             @"Wombat1: mame_screen_test, mame-screen-size, frame-count, 1.0, 8.0, 8.0",
             @"Wombat2: mame_screen_test, mame-screen-size, frame-count, wombat_rate=2.0, wombat_u=16.0, wombat_v=16.0",
             @"Test (dot): mame_screen_dot, mame-screen-matrix",
             @"Test (line): mame_screen_line, mame-screen-matrix",
             @"Test (rainbow): mame_screen_rainbow, mame-screen-matrix, frame-count, rainbow_h = 16.0 4.0 32.0, rainbow_speed=1.0 1.0 4.0",
#endif
    ];
}

+ (NSArray*)arrayEffect {
    Options* op = [[Options alloc] init];
    if (g_isMetalSupported && op.useMetal)
        return [self arrayMetalEffects];
    else
        return [self arrayCoreGraphicsEffects];
}

//
// color space data, we define the colorSpaces here, in one place, so it stays in-sync with the UI.
//
// you can specify a colorSpace in two ways, with a system name or with parameters.
// these strings are of the form <Friendly Name> : <colorSpace name OR colorSpace parameters>
//
// colorSpace name is one of the sytem contants passed to `CGColorSpaceCreateWithName`
// see (Color Space Names)[https://developer.apple.com/documentation/coregraphics/cgcolorspace/color_space_names]
//
// colorSpace parameters are 3 - 18 floating point numbers separated with commas.
// see [CGColorSpaceCreateCalibratedRGB](https://developer.apple.com/documentation/coregraphics/1408861-cgcolorspacecreatecalibratedrgb)
//
// if <colorSpace name OR colorSpace parameters> is blank or not valid, a device-dependent RGB color space is used.
//
// NOTE: not all iOS devices support color matching.
//
+ (NSArray*)arrayColorSpace {

    // TODO: find out what devices??
    BOOL deviceSupportsColorMatching = TRUE;
    
    if (!deviceSupportsColorMatching)
        return @[@"Default"];

    return @[@"DeviceRGB",
             @"sRGB : kCGColorSpaceSRGB",
             @"CRT (sRGB, D65, 2.5) :    0.95047,1.0,1.08883, 0,0,0, 2.5,2.5,2.5, 0.412456,0.212673,0.019334,0.357576,0.715152,0.119192,0.180437,0.072175,0.950304",
             @"Rec709 (sRGB, D65, 2.4) : 0.95047,1.0,1.08883, 0,0,0, 2.4,2.4,2.4, 0.412456,0.212673,0.019334,0.357576,0.715152,0.119192,0.180437,0.072175,0.950304",
#ifdef DEBUG
             @"Adobe RGB : kCGColorSpaceAdobeRGB1998",
             @"Linear sRGB : kCGColorSpaceLinearSRGB",
             @"NTSC Luminance : 0.9504,1.0000,1.0888, 0,0,0, 1,1,1, 0.299,0.299,0.299, 0.587,0.587,0.587, 0.114,0.114,0.114",
#endif
    ];
}

#pragma mark - instance code

- (id)init {
    
    if (self = [super init]) {
        [self loadOptions];
    }
    
    return self;
}

+ (void)resetOptions
{
    NSString *path=[NSString stringWithUTF8String:get_documents_path("iOS/options_v23.bin")];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)loadOptions
{
    NSString *path=[NSString stringWithUTF8String:get_documents_path("iOS/options_v23.bin")];
    
    NSData *plistData;
    id plist = nil;
    NSError *error = nil;
    
    NSPropertyListFormat format;
    
    NSError *sqerr;
    plistData = [NSData dataWithContentsOfFile:path options:0 error:&sqerr];
    
    if (plistData != nil)
    {
        plist = [NSPropertyListSerialization propertyListWithData:plistData
                                                      options:NSPropertyListImmutable
                                                       format:&format
                                                        error:&error];
    }
    
    if ([plist isKindOfClass:[NSArray class]])
        plist = [plist objectAtIndex:0];

    if(![plist isKindOfClass:[NSDictionary class]])
    {
        _keepAspectRatioPort=1;
        _keepAspectRatioLand=1;
        
        _filterPort = @"";
        _filterLand = @"";

        _borderPort = @"";
        _borderLand = @"";

        _effectPort = @"";
        _effectLand = @"";
        
        _sourceColorSpace = @"";
        _useMetal = 1;
        
        _integerScalingOnly = 0;

        _showFPS = 0;
        _showHUD = 0;
        _showINFO = 0;
        _fourButtonsLand = 0;
        _animatedButtons = 1;
        
        _fullLand = 1;
        _fullPort = 0;
        
        _fullLandJoy = 1;
        _fullPortJoy = 1;
        
        _btDeadZoneValue = 2;
        _touchDeadZone = 1;
        
        _overscanValue = 0;
        _tvoutNative = 1;
        
        _touchtype = 1;
        _analogDeadZoneValue = 2;
        
        _controltype = 0;
        
        _soundValue = 5;
        
        _throttle = 1;
        _fsvalue = 0;
        _sticktype = 0;
        _numbuttons = 0;
        _aplusb = 0;
        _cheats = 1;
        _sleep = 1;
        
        _forcepxa = 0;
        _emures = 0;
        _p1aspx = 0;
        
        _filterClones=0;
        _filterFavorites=0;
        _filterNotWorking=1;
        _manufacturerValue=0;
        _yearGTEValue=0;
        _yearLTEValue=0;
        _driverSourceValue=0;
        _categoryValue=0;
        
        _filterKeyword = nil;
        
        _lowlsound = 1;
        _vsync = 1;
        _threaded = 1;
        _dblbuff = 1;
        
        _mainPriority = 5;
        _videoPriority = 5;
        
        _autofire = 0;
        _hiscore = 1;
        
        _stickSize = 2;
        _buttonSize= 2;
        _nintendoBAYX=0;

        _wpantype = 0;
        _wfpeeraddr = nil;
        _wfport = NETPLAY_PORT;
        _wfframesync = 0;
        _btlatency = 1;
        
        _vbean2x = 1;
        _vantialias = 1;
        _vflicker = 0;
        
        _emuspeed = 0;
        
        _mainThreadType = 0;
        _videoThreadType = 0;
        
        _lightgunEnabled = 1;
        _lightgunBottomScreenReload = 0;
        
        _turboXEnabled = 0;
        _turboYEnabled = 0;
        _turboAEnabled = 0;
        _turboBEnabled = 0;
        _turboLEnabled = 0;
        _turboREnabled = 0;
        
        _touchAnalogEnabled = 1;
        _touchAnalogHideTouchDirectionalPad = 1;
        _touchAnalogHideTouchButtons = 0;
        _touchAnalogSensitivity = 500.0;
        _touchControlsOpacity = 50.0;
        
        _touchDirectionalEnabled = 0;
    }
    else
    {
        NSDictionary* optionsDict = plist;

        _keepAspectRatioPort = [[optionsDict objectForKey:@"KeepAspectPort"] intValue];
        _keepAspectRatioLand = [[optionsDict objectForKey:@"KeepAspectLand"] intValue];
        
        _filterPort = [optionsDict objectForKey:@"filterPort"] ?: @"";
        _filterLand = [optionsDict objectForKey:@"filterLand"] ?: @"";

        _borderPort = [optionsDict objectForKey:@"borderPort"] ?: @"";
        _borderLand = [optionsDict objectForKey:@"borderLand"] ?: @"";

        _effectPort = [optionsDict objectForKey:@"effectPort"] ?: @"";
        _effectLand = [optionsDict objectForKey:@"effectLand"] ?: @"";
        
        _sourceColorSpace = [optionsDict objectForKey:@"sourceColorSpace"] ?: @"";
        _useMetal = [([optionsDict objectForKey:@"useMetal"] ?: @(TRUE)) boolValue];

        _integerScalingOnly = [[optionsDict objectForKey:@"integerScalingOnly"] boolValue];

        _lightgunEnabled = [[optionsDict objectForKey:@"lightgunEnabled"] intValue];
        _lightgunBottomScreenReload = [[optionsDict objectForKey:@"lightgunBottomScreenReload"] intValue];
        _touchAnalogEnabled = [[optionsDict objectForKey:@"touchAnalogEnabled"] intValue];
        _touchAnalogHideTouchDirectionalPad = [[optionsDict objectForKey:@"touchAnalogHideTouchDirectionalPad"] intValue];
        _touchAnalogHideTouchButtons = [[optionsDict objectForKey:@"touchAnalogHideTouchButtons"] intValue];
        _touchAnalogSensitivity = [[optionsDict objectForKey:@"touchAnalogSensitivity"] floatValue];
        id prefTouchControlOpacity = [optionsDict objectForKey:@"touchControlsOpacity"];
        if ( prefTouchControlOpacity == nil ) {
            _touchControlsOpacity = 50.0;
        } else {
            _touchControlsOpacity = [prefTouchControlOpacity floatValue];
        }
        _showFPS =  [[optionsDict objectForKey:@"showFPS"] intValue];
        _showHUD =  [[optionsDict objectForKey:@"showHUD"] intValue];
        _showINFO =  [[optionsDict objectForKey:@"showINFO"] intValue];
        _fourButtonsLand =  [[optionsDict objectForKey:@"fourButtonsLand"] intValue];
        _animatedButtons =  [[optionsDict objectForKey:@"animatedButtons"] intValue];
        
        _fullLand =  [[optionsDict objectForKey:@"fullLand"] intValue];
        _fullPort =  [[optionsDict objectForKey:@"fullPort"] intValue];
        _fullLandJoy =  [([optionsDict objectForKey:@"fullLandJoy"] ?: @(1)) intValue];
        _fullPortJoy =  [([optionsDict objectForKey:@"fullPortJoy"] ?: @(1)) intValue];

        _turboXEnabled = [[optionsDict objectForKey:@"turboXEnabled"] intValue];
        _turboYEnabled = [[optionsDict objectForKey:@"turboYEnabled"] intValue];
        _turboAEnabled = [[optionsDict objectForKey:@"turboAEnabled"] intValue];
        _turboBEnabled = [[optionsDict objectForKey:@"turboBEnabled"] intValue];
        _turboLEnabled = [[optionsDict objectForKey:@"turboLEnabled"] intValue];
        _turboREnabled = [[optionsDict objectForKey:@"turboREnabled"] intValue];
        
        _touchDirectionalEnabled = [[optionsDict objectForKey:@"touchDirectionalEnabled"] intValue];
        
        _btDeadZoneValue =  [[optionsDict objectForKey:@"btDeadZoneValue"] intValue];
        _touchDeadZone =  [[optionsDict objectForKey:@"touchDeadZone"] intValue];
        
        _overscanValue =  [[optionsDict objectForKey:@"overscanValue"] intValue];
        _tvoutNative =  [[optionsDict objectForKey:@"tvoutNative"] intValue];
        
        _touchtype =  [[optionsDict objectForKey:@"inputTouchType"] intValue];
        _analogDeadZoneValue =  [[optionsDict objectForKey:@"analogDeadZoneValue"] intValue];
        _controltype =  [[optionsDict objectForKey:@"controlType"] intValue];
        
        _soundValue =  [[optionsDict objectForKey:@"soundValue"] intValue];
        
        _throttle  =  [[optionsDict objectForKey:@"throttle"] intValue];
        _fsvalue  =  [[optionsDict objectForKey:@"fsvalue"] intValue];
        _sticktype  =  [[optionsDict objectForKey:@"sticktype"] intValue];
        _numbuttons  =  [[optionsDict objectForKey:@"numbuttons"] intValue];
        _aplusb  =  [[optionsDict objectForKey:@"aplusb"] intValue];
        _cheats  =  [[optionsDict objectForKey:@"cheats"] intValue];
        _sleep  =  [[optionsDict objectForKey:@"sleep"] intValue];
        
        _forcepxa  =  [[optionsDict objectForKey:@"forcepxa"] intValue];
        _emures  =  [[optionsDict objectForKey:@"emures"] intValue];
        
        _p1aspx  =  [[optionsDict objectForKey:@"p1aspx"] intValue];
        
        _filterClones  =  [[optionsDict objectForKey:@"filterClones"] intValue];
        _filterFavorites  =  [[optionsDict objectForKey:@"filterFavorites"] intValue];
        _filterNotWorking  =  [[optionsDict objectForKey:@"filterNotWorking"] intValue];
        _manufacturerValue  =  [[optionsDict objectForKey:@"manufacturerValue"] intValue];
        _yearGTEValue  =  [[optionsDict objectForKey:@"yearGTEValue"] intValue];
        _yearLTEValue  =  [[optionsDict objectForKey:@"yearLTEValue"] intValue];
        _driverSourceValue  =  [[optionsDict objectForKey:@"driverSourceValue"] intValue];
        _categoryValue  =  [[optionsDict objectForKey:@"categoryValue"] intValue];
        
        _filterKeyword  =  [optionsDict objectForKey:@"filterKeyword"];
        
        _lowlsound  =  [[optionsDict objectForKey:@"lowlsound"] intValue];
        _vsync  =  [[optionsDict objectForKey:@"vsync"] intValue];
        _threaded  =  [[optionsDict objectForKey:@"threaded"] intValue];
        _dblbuff  =  [[optionsDict objectForKey:@"dblbuff"] intValue];
        
        _mainPriority  =  [[optionsDict objectForKey:@"mainPriority"] intValue];
        _videoPriority  =  [[optionsDict objectForKey:@"videoPriority"] intValue];
        
        _autofire =  [[optionsDict objectForKey:@"autofire"] intValue];
        
        _hiscore  =  [[optionsDict objectForKey:@"hiscore"] intValue];
        
        _buttonSize =  [[optionsDict objectForKey:@"buttonSize"] intValue];
        _stickSize =  [[optionsDict objectForKey:@"stickSize"] intValue];
        _nintendoBAYX = [[optionsDict objectForKey:@"nintendoBAYX"] intValue];
        
        _wpantype  =  [[optionsDict objectForKey:@"wpantype"] intValue];
        _wfpeeraddr  =  [optionsDict objectForKey:@"wfpeeraddr"];
        _wfport  =  [[optionsDict objectForKey:@"wfport"] intValue];
        _wfframesync  =  [[optionsDict objectForKey:@"wfframesync"] intValue];
        _btlatency  =  [[optionsDict objectForKey:@"btlatency"] intValue];
        
        if([_wfpeeraddr isEqualToString:@""])
            _wfpeeraddr = nil;
        if([_filterKeyword isEqualToString:@""])
            _filterKeyword = nil;
        
        _vbean2x  =  [[optionsDict objectForKey:@"vbean2x"] intValue];
        _vantialias  =  [[optionsDict objectForKey:@"vantialias"] intValue];
        _vflicker  =  [[optionsDict objectForKey:@"vflicker"] intValue];
        
        _emuspeed  =  [[optionsDict objectForKey:@"emuspeed"] intValue];
        
        _mainThreadType  =  [[optionsDict objectForKey:@"mainThreadType"] intValue];
        _videoThreadType  =  [[optionsDict objectForKey:@"videoThreadType"] intValue];
    }
    
}

- (void)saveOptions
{
    NSDictionary* optionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat:@"%d", _keepAspectRatioPort], @"KeepAspectPort",
                             [NSString stringWithFormat:@"%d", _keepAspectRatioLand], @"KeepAspectLand",
                             
                             _filterPort, @"filterPort",
                             _filterLand, @"filterLand",

                             _borderPort, @"borderPort",
                             _borderLand, @"borderLand",

                             _effectPort, @"effectPort",
                             _effectLand, @"effectLand",
                             
                             _sourceColorSpace, @"sourceColorSpace",
                             [NSString stringWithFormat:@"%d", _useMetal], @"useMetal",
                                 
                             [NSString stringWithFormat:@"%d", _integerScalingOnly], @"integerScalingOnly",

                             [NSString stringWithFormat:@"%d", _lightgunEnabled],@"lightgunEnabled",
                             
                             [NSString stringWithFormat:@"%d", _lightgunBottomScreenReload], @"lightgunBottomScreenReload",
                             [NSString stringWithFormat:@"%d", _touchAnalogEnabled], @"touchAnalogEnabled",
                             [NSString stringWithFormat:@"%d", _touchAnalogHideTouchDirectionalPad], @"touchAnalogHideTouchDirectionalPad",
                             [NSString stringWithFormat:@"%d", _touchAnalogHideTouchButtons], @"touchAnalogHideTouchButtons",
                             [NSString stringWithFormat:@"%f", _touchAnalogSensitivity], @"touchAnalogSensitivity",
                             [NSString stringWithFormat:@"%f", _touchControlsOpacity], @"touchControlsOpacity",
                             [NSString stringWithFormat:@"%d", _showFPS], @"showFPS",
                             [NSString stringWithFormat:@"%d", _showHUD], @"showHUD",
                             [NSString stringWithFormat:@"%d", _showINFO], @"showINFO",
                             [NSString stringWithFormat:@"%d", _fourButtonsLand], @"fourButtonsLand",
                             [NSString stringWithFormat:@"%d", _animatedButtons], @"animatedButtons",
                             
                             [NSString stringWithFormat:@"%d", _turboXEnabled], @"turboXEnabled",
                             [NSString stringWithFormat:@"%d", _turboYEnabled], @"turboYEnabled",
                             [NSString stringWithFormat:@"%d", _turboAEnabled], @"turboAEnabled",
                             [NSString stringWithFormat:@"%d", _turboBEnabled], @"turboBEnabled",
                             [NSString stringWithFormat:@"%d", _turboLEnabled], @"turboLEnabled",
                             [NSString stringWithFormat:@"%d", _turboREnabled], @"turboREnabled",
                             
                             [NSString stringWithFormat:@"%d", _touchDirectionalEnabled], @"touchDirectionalEnabled",
                             
                             [NSString stringWithFormat:@"%d", _fullLand], @"fullLand",
                             [NSString stringWithFormat:@"%d", _fullPort], @"fullPort",
                             
                             [NSString stringWithFormat:@"%d", _fullLandJoy], @"fullLandJoy",
                             [NSString stringWithFormat:@"%d", _fullPortJoy], @"fullPortJoy",

                             [NSString stringWithFormat:@"%d", _btDeadZoneValue], @"btDeadZoneValue",
                             [NSString stringWithFormat:@"%d", _touchDeadZone], @"touchDeadZone",
                             
                             [NSString stringWithFormat:@"%d", _overscanValue], @"overscanValue",
                             [NSString stringWithFormat:@"%d", _tvoutNative], @"tvoutNative",
                             
                             [NSString stringWithFormat:@"%d", _touchtype], @"inputTouchType",
                             [NSString stringWithFormat:@"%d", _analogDeadZoneValue], @"analogDeadZoneValue",
                             
                             [NSString stringWithFormat:@"%d", _controltype], @"controlType",
                             
                             [NSString stringWithFormat:@"%d", _soundValue], @"soundValue",
                             
                             [NSString stringWithFormat:@"%d", _throttle], @"throttle",
                             [NSString stringWithFormat:@"%d", _fsvalue], @"fsvalue",
                             [NSString stringWithFormat:@"%d", _sticktype], @"sticktype",
                             [NSString stringWithFormat:@"%d", _numbuttons], @"numbuttons",
                             [NSString stringWithFormat:@"%d", _aplusb], @"aplusb",
                             [NSString stringWithFormat:@"%d", _cheats], @"cheats",
                             [NSString stringWithFormat:@"%d", _sleep], @"sleep",
                             
                             [NSString stringWithFormat:@"%d", _forcepxa], @"forcepxa",
                             [NSString stringWithFormat:@"%d", _emures], @"emures",
                             
                             [NSString stringWithFormat:@"%d", _p1aspx], @"p1aspx",
                             
                             [NSString stringWithFormat:@"%d", _filterClones], @"filterClones",
                             [NSString stringWithFormat:@"%d", _filterFavorites], @"filterFavorites",
                             [NSString stringWithFormat:@"%d", _filterNotWorking], @"filterNotWorking",
                             [NSString stringWithFormat:@"%d", _manufacturerValue], @"manufacturerValue",
                             [NSString stringWithFormat:@"%d", _yearGTEValue], @"yearGTEValue",
                             [NSString stringWithFormat:@"%d", _yearLTEValue], @"yearLTEValue",
                             [NSString stringWithFormat:@"%d", _driverSourceValue], @"driverSourceValue",
                             [NSString stringWithFormat:@"%d", _categoryValue], @"categoryValue",
                             [NSString stringWithFormat:@"%d", _lowlsound], @"lowlsound",
                             [NSString stringWithFormat:@"%d", _vsync], @"vsync",
                             [NSString stringWithFormat:@"%d", _threaded], @"threaded",
                             [NSString stringWithFormat:@"%d", _dblbuff], @"dblbuff",
                             
                             [NSString stringWithFormat:@"%d", _mainPriority], @"mainPriority",
                             [NSString stringWithFormat:@"%d", _videoPriority], @"videoPriority",
                             
                             [NSString stringWithFormat:@"%d", _autofire], @"autofire",
                             [NSString stringWithFormat:@"%d", _hiscore], @"hiscore",
                             
                             [NSString stringWithFormat:@"%d", _stickSize], @"stickSize",
                             [NSString stringWithFormat:@"%d", _buttonSize], @"buttonSize",
                             [NSString stringWithFormat:@"%d", _nintendoBAYX], @"nintendoBAYX",

                             [NSString stringWithFormat:@"%d", _wpantype], @"wpantype",
                             [NSString stringWithFormat:@"%d", _wfport], @"wfport",
                             [NSString stringWithFormat:@"%d", _wfframesync], @"wfframesync",
                             [NSString stringWithFormat:@"%d", _btlatency], @"btlatency",
                             (_wfpeeraddr ?: @""), @"wfpeeraddr",
                             
                             (_filterKeyword ?: @""), @"filterKeyword",
                             
                             [NSString stringWithFormat:@"%d", _vbean2x], @"vbean2x",
                             [NSString stringWithFormat:@"%d", _vantialias], @"vantialias",
                             [NSString stringWithFormat:@"%d", _vflicker], @"vflicker",
                             
                             [NSString stringWithFormat:@"%d", _emuspeed], @"emuspeed",
                             
                             [NSString stringWithFormat:@"%d", _mainThreadType], @"mainThreadType",
                             [NSString stringWithFormat:@"%d", _videoThreadType], @"videoThreadType",
                             
                             nil];
    
    
    NSString *path=[NSString stringWithUTF8String:get_documents_path("iOS/options_v23.bin")];
    
    NSData *plistData;
    
    NSError *error = nil;
    
    plistData = [NSPropertyListSerialization dataWithPropertyList:@[optionsDict]
                                                           format:NSPropertyListBinaryFormat_v1_0
                                                          options:0
                                                            error:&error];

    if(plistData)
    {
        //NSError*err;
        
        BOOL b = [plistData writeToFile:path atomically:NO];
        //BOOL b = [plistData writeToFile:path options:0  error:&err];
        if(!b)
        {
            UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"Error saving preferences!" message:@"Preferences cannot be saved.\n Check for write permissions. 'chmod -R 777 /var/mobile/Media/ROMs' if needed. Look at the help for details!." preferredStyle:UIAlertControllerStyleAlert];
            [errAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            UIViewController *controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [controller presentViewController:errAlert animated:YES completion:nil];
        }
    }
    else
    {
        NSLog(@"%@",error);
    }
}

@end

#pragma mark - safe access to options array list

@implementation NSArray (optionAtIndex)
- (id)objectAtIndex:(NSUInteger)index withDefault:(id)defaultObject {
    if (index != NSNotFound && index >= 0 && index < [self count])
        return [self objectAtIndex:index];
    else
        return defaultObject;
}
- (NSString*)optionAtIndex:(NSUInteger)index {
    return [self objectAtIndex:index withDefault:self.firstObject];
}
// find and return option index given a name, default to first if not found
- (NSUInteger)indexOfOption:(NSString*)string {
    NSParameterAssert(![string containsString:@":"]); // a name should never contain the data.
    // option lists are of the form "Name : Data" or just "Name"
    for (NSUInteger idx=0; idx<self.count; idx++) {
        NSString* str = [self[idx] componentsSeparatedByString:@":"].firstObject;
        if ([string isEqualToString:[str stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]])
            return idx;
    }
    return 0;
}
// find and return option data given a string, default to first if not found
- (NSString*)optionData:(NSString*)string {

    NSString* str = [self optionAtIndex:[self indexOfOption:string]];
    str = [str componentsSeparatedByString:@":"].lastObject;
    str = [str stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

    return str;
}
// find and return option name given a string, default to first if not found
- (NSString*)optionName:(NSString*)string {

    NSString* str = [self optionAtIndex:[self indexOfOption:string]];
    str = [str componentsSeparatedByString:@":"].firstObject;
    str = [str stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    
    return str;
}
@end
