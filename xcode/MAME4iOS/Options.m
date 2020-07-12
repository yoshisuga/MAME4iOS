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
#import "SkinManager.h"         // for skinList
#import "MetalScreenView.h"     // for shader and filter list
#import "CGScreenView.h"        // for shader and filter list

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
    return @[@"Keyboard",@"iCade or compatible",@"iCP, Gametel",@"iMpulse", @"8BitDo Zero"];
}

+ (NSArray*)arraySkin {
    return [SkinManager getSkinNames];
}
+ (NSArray*)arrayFilter {
    Options* op = [[Options alloc] init];
    if (g_isMetalSupported && op.useMetal)
        return [MetalScreenView filterList];
    else
        return [CGScreenView filterList];
}
+ (NSArray*)arrayScreenShader {
    Options* op = [[Options alloc] init];
    if (g_isMetalSupported && op.useMetal)
        return [MetalScreenView screenShaderList];
    else
        return [CGScreenView screenShaderList];
}
+ (NSArray*)arrayLineShader {
    Options* op = [[Options alloc] init];
    if (g_isMetalSupported && op.useMetal)
        return [MetalScreenView lineShaderList];
    else
        return [CGScreenView lineShaderList];
}
+ (NSArray*)arrayColorSpace {
    Options* op = [[Options alloc] init];
    if (g_isMetalSupported && op.useMetal)
        return [MetalScreenView colorSpaceList];
    else
        return [CGScreenView colorSpaceList];
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
        _keepAspectRatio=1;
        
        _filter = @"";
        _skin = @"";
        _screenShader = @"";
        _lineShader = @"";

        _colorSpace = @"";
        _useMetal = 1;
        
        _integerScalingOnly = 0;

        _showFPS = 0;
        _showHUD = 0;
        _showINFO = 0;
        _animatedButtons = 1;
        
#if TARGET_OS_MACCATALYST
        _fullscreenLandscape= 0;
        _fullscreenPortrait = 0;
        _fullscreenJoystick = 0;
#else
        _fullscreenLandscape= 1;
        _fullscreenPortrait = 0;
        _fullscreenJoystick = 1;
#endif
        
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

        _keepAspectRatio = [([optionsDict objectForKey:@"KeepAspect"] ?: @(1)) intValue];
        
        _filter = [optionsDict objectForKey:@"filter"] ?: @"";
        _skin = [optionsDict objectForKey:@"skin"] ?: @"";
        _screenShader = [optionsDict objectForKey:@"screen-shader"] ?: [optionsDict objectForKey:@"effect"] ?: @"";
        _lineShader = [optionsDict objectForKey:@"line-shader"] ?: @"";

        _colorSpace = [optionsDict objectForKey:@"sourceColorSpace"] ?: @"";
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
        _animatedButtons =  [[optionsDict objectForKey:@"animatedButtons"] intValue];
        
        _fullscreenLandscape =  [([optionsDict objectForKey:@"fullLand"] ?: @(1)) intValue];
        _fullscreenPortrait  =  [([optionsDict objectForKey:@"fullPort"] ?: @(0)) intValue];
        _fullscreenJoystick  =  [([optionsDict objectForKey:@"fullJoy"]  ?: @(1)) intValue];

        _turboXEnabled = [[optionsDict objectForKey:@"turboXEnabled"] intValue];
        _turboYEnabled = [[optionsDict objectForKey:@"turboYEnabled"] intValue];
        _turboAEnabled = [[optionsDict objectForKey:@"turboAEnabled"] intValue];
        _turboBEnabled = [[optionsDict objectForKey:@"turboBEnabled"] intValue];
        _turboLEnabled = [[optionsDict objectForKey:@"turboLEnabled"] intValue];
        _turboREnabled = [[optionsDict objectForKey:@"turboREnabled"] intValue];
        
        _touchDirectionalEnabled = [[optionsDict objectForKey:@"touchDirectionalEnabled"] intValue];
        
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
                             [NSString stringWithFormat:@"%d", _keepAspectRatio], @"KeepAspect",
                              
                             _filter, @"filter",
                             _skin, @"skin",
                             _screenShader, @"screen-shader",
                             _lineShader, @"line-shader",

                             _colorSpace, @"sourceColorSpace",
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
                             [NSString stringWithFormat:@"%d", _animatedButtons], @"animatedButtons",
                             
                             [NSString stringWithFormat:@"%d", _turboXEnabled], @"turboXEnabled",
                             [NSString stringWithFormat:@"%d", _turboYEnabled], @"turboYEnabled",
                             [NSString stringWithFormat:@"%d", _turboAEnabled], @"turboAEnabled",
                             [NSString stringWithFormat:@"%d", _turboBEnabled], @"turboBEnabled",
                             [NSString stringWithFormat:@"%d", _turboLEnabled], @"turboLEnabled",
                             [NSString stringWithFormat:@"%d", _turboREnabled], @"turboREnabled",
                             
                             [NSString stringWithFormat:@"%d", _touchDirectionalEnabled], @"touchDirectionalEnabled",
                             
                             [NSString stringWithFormat:@"%d", _fullscreenLandscape], @"fullLand",
                             [NSString stringWithFormat:@"%d", _fullscreenPortrait], @"fullPort",
                             [NSString stringWithFormat:@"%d", _fullscreenJoystick], @"fullJoy",

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
