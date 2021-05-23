//
//  Options.m
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 1/12/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "Options.h"
#import "Globals.h"
#import "SkinManager.h"         // for skinList
#import "MetalScreenView.h"     // for shader and filter list

@implementation Options

#pragma mark - class properties

+ (NSArray*)arrayEmuSpeed {
    return @[@"Default",@"50%",@"60%",@"70%",@"80%",@"85%",@"90%",@"95%",@"100%",@"105%",@"110%",@"115%",@"120%",@"130%",@"140%",@"150%"];
}
+ (NSArray*)arrayControlType {
    return @[@"Keyboard",@"iCade or compatible",@"iCP, Gametel",@"iMpulse"];
}

+ (NSArray*)arraySkin {
    return [SkinManager getSkinNames];
}
+ (NSArray*)arrayFilter {
    return [MetalScreenView filterList];
}
+ (NSArray*)arrayScreenShader {
    return [MetalScreenView screenShaderList];
}
+ (NSArray*)arrayLineShader {
    return [MetalScreenView lineShaderList];
}

#pragma mark - utility funciton to set a single option and save it.

+ (void)setOption:(id)value forKey:(NSString*)key {
    Options* op = [[Options alloc] init];
    [op setValue:value forKey:key];
    [op saveOptions];
}


#pragma mark - instance code

- (id)init {
    
    if (self = [super init]) {
        [self loadOptions];
    }
    
    return self;
}

+ (NSString*)optionsFile
{
    return @"iOS/options_v23.bin";
}

+ (NSString*)optionsPath
{
    return [NSString stringWithUTF8String:get_documents_path(self.optionsFile.UTF8String)];
}

+ (void)resetOptions
{
    [[NSFileManager defaultManager] removeItemAtPath:Options.optionsPath error:nil];
}

- (void)loadOptions
{
    NSString *path = Options.optionsPath;
    
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
        
        _touchtype = 1;
        _analogDeadZoneValue = 2;
        
        _controltype = 0;
        
        _sticktype = 0;
        _numbuttons = 0;
        _aplusb = 0;
        _cheats = 1;
        
        _forcepxa = 0;
        _p1aspx = 0;
        
        _filterClones=0;
        _filterNotWorking=1;
        _filterBIOS=1;

        _autofire = 0;
        _hiscore = 1;
        
        _stickSize = 2;
        _buttonSize= 2;
        _nintendoBAYX=0;

        _vbean2x = 1;
        _vflicker = 0;
        
        _emuspeed = 0;
        
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
        
        _hapticButtonFeedback = 1;
    }
    else
    {
        NSDictionary* optionsDict = plist;

        _keepAspectRatio = [([optionsDict objectForKey:@"KeepAspect"] ?: @(1)) intValue];
        
        _filter = [optionsDict objectForKey:@"filter"] ?: @"";
        _skin = [optionsDict objectForKey:@"skin"] ?: @"";
        _screenShader = [optionsDict objectForKey:@"screen-shader"] ?: [optionsDict objectForKey:@"effect"] ?: @"";
        _lineShader = [optionsDict objectForKey:@"line-shader"] ?: @"";

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
        
        _touchtype =  [[optionsDict objectForKey:@"inputTouchType"] intValue];
        _analogDeadZoneValue =  [[optionsDict objectForKey:@"analogDeadZoneValue"] intValue];
        _controltype =  [[optionsDict objectForKey:@"controlType"] intValue];
        
        _sticktype  =  [[optionsDict objectForKey:@"sticktype"] intValue];
        _numbuttons  =  [[optionsDict objectForKey:@"numbuttons"] intValue];
        _aplusb  =  [[optionsDict objectForKey:@"aplusb"] intValue];
        _cheats  =  [[optionsDict objectForKey:@"cheats"] intValue];
        
        _forcepxa  =  [[optionsDict objectForKey:@"forcepxa"] intValue];
        
        _p1aspx  =  [[optionsDict objectForKey:@"p1aspx"] intValue];
        
        _filterClones  =  [[optionsDict objectForKey:@"filterClones"] intValue];
        _filterNotWorking  =  [[optionsDict objectForKey:@"filterNotWorking"] intValue];
        _filterBIOS  =  [([optionsDict objectForKey:@"filterBIOS"] ?: @(1)) intValue];

        _autofire =  [[optionsDict objectForKey:@"autofire"] intValue];
        _hiscore  =  [[optionsDict objectForKey:@"hiscore"] intValue];
        
        _buttonSize =  [[optionsDict objectForKey:@"buttonSize"] intValue];
        _stickSize =  [[optionsDict objectForKey:@"stickSize"] intValue];
        _nintendoBAYX = [[optionsDict objectForKey:@"nintendoBAYX"] intValue];
        
        _vbean2x  =  [[optionsDict objectForKey:@"vbean2x"] intValue];
        _vflicker  =  [[optionsDict objectForKey:@"vflicker"] intValue];
        
        _emuspeed  =  [[optionsDict objectForKey:@"emuspeed"] intValue];
        
        _hapticButtonFeedback = [([optionsDict objectForKey:@"hapticButtonFeedback"] ?: @(1)) intValue];
    }
    
}

- (NSDictionary*)getDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat:@"%d", _keepAspectRatio], @"KeepAspect",
                              
                             _filter, @"filter",
                             _skin, @"skin",
                             _screenShader, @"screen-shader",
                             _lineShader, @"line-shader",

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

                             [NSString stringWithFormat:@"%d", _touchtype], @"inputTouchType",
                             [NSString stringWithFormat:@"%d", _analogDeadZoneValue], @"analogDeadZoneValue",
                             
                             [NSString stringWithFormat:@"%d", _controltype], @"controlType",
                             
                             [NSString stringWithFormat:@"%d", _sticktype], @"sticktype",
                             [NSString stringWithFormat:@"%d", _numbuttons], @"numbuttons",
                             [NSString stringWithFormat:@"%d", _aplusb], @"aplusb",
                             [NSString stringWithFormat:@"%d", _cheats], @"cheats",
                             
                             [NSString stringWithFormat:@"%d", _forcepxa], @"forcepxa",
                             
                             [NSString stringWithFormat:@"%d", _p1aspx], @"p1aspx",
                             
                             [NSString stringWithFormat:@"%d", _filterClones], @"filterClones",
                             [NSString stringWithFormat:@"%d", _filterNotWorking], @"filterNotWorking",
                             [NSString stringWithFormat:@"%d", _filterBIOS], @"filterBIOS",
                             
                             [NSString stringWithFormat:@"%d", _autofire], @"autofire",
                             [NSString stringWithFormat:@"%d", _hiscore], @"hiscore",
                             
                             [NSString stringWithFormat:@"%d", _stickSize], @"stickSize",
                             [NSString stringWithFormat:@"%d", _buttonSize], @"buttonSize",
                             [NSString stringWithFormat:@"%d", _nintendoBAYX], @"nintendoBAYX",

                             [NSString stringWithFormat:@"%d", _vbean2x], @"vbean2x",
                             [NSString stringWithFormat:@"%d", _vflicker], @"vflicker",
                             
                             [NSString stringWithFormat:@"%d", _emuspeed], @"emuspeed",
                                 
                             [NSString stringWithFormat:@"%d", _hapticButtonFeedback], @"hapticButtonFeedback",
                                 
                             nil];
}

- (void)saveOptions
{
    NSDictionary* optionsDict = [self getDictionary];
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:optionsDict format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    NSParameterAssert(data != nil);
    [data writeToFile:Options.optionsPath atomically:NO];
}

// compare two Options, but only the specified keys
- (BOOL)isEqualToOptions:(Options*)other withKeys:(NSArray<NSString*>*)keys {

    NSDictionary* lhs = [self getDictionary];
    NSDictionary* rhs = [other getDictionary];

    for (NSString* key in keys) {
        id a = lhs[key];
        id b = rhs[key];
        if (!(a == b || [a isEqual:b]))
            return FALSE;
    }
    return TRUE;
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
