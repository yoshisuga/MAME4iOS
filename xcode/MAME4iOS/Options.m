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

@synthesize keepAspectRatioPort;
@synthesize keepAspectRatioLand;
@synthesize smoothedLand;
@synthesize smoothedPort;

@synthesize tvFilterLand;
@synthesize tvFilterPort;
@synthesize scanlineFilterLand;
@synthesize scanlineFilterPort;

@synthesize showFPS;
@synthesize showINFO;
@synthesize animatedButtons;
@synthesize fourButtonsLand;
@synthesize fullLand;
@synthesize fullPort;

@synthesize lightgunEnabled;
@synthesize lightgunBottomScreenReload;

@synthesize touchAnalogEnabled;
@synthesize touchAnalogSensitivity;
@synthesize touchAnalogHideTouchButtons;
@synthesize touchAnalogHideTouchDirectionalPad;
@synthesize touchControlsOpacity;

@synthesize touchDirectionalEnabled;

@synthesize skinValue;

@synthesize btDeadZoneValue;
@synthesize touchDeadZone;

@synthesize overscanValue;
@synthesize tvoutNative;

@synthesize touchtype;
@synthesize analogDeadZoneValue;
@synthesize controltype;

@synthesize soundValue;

@synthesize throttle;
@synthesize fsvalue;
@synthesize sticktype;
@synthesize numbuttons;
@synthesize aplusb;
@synthesize cheats;
@synthesize sleep;

@synthesize forcepxa;
@synthesize emures;
@synthesize p1aspx;

@synthesize filterClones;
@synthesize filterFavorites;
@synthesize filterNotWorking;
@synthesize manufacturerValue;
@synthesize yearGTEValue;
@synthesize yearLTEValue;
@synthesize driverSourceValue;
@synthesize categoryValue;

@synthesize filterKeyword;

@synthesize lowlsound;
@synthesize vsync;
@synthesize threaded;
@synthesize dblbuff;

@synthesize mainPriority;
@synthesize videoPriority;

@synthesize autofire;

@synthesize hiscore;

@synthesize buttonSize;
@synthesize stickSize;

@synthesize wpantype;
@synthesize wfpeeraddr;
@synthesize wfport;
@synthesize wfframesync;
@synthesize btlatency;

@synthesize vbean2x;
@synthesize vantialias;
@synthesize vflicker;

@synthesize emuspeed;

@synthesize mainThreadType;
@synthesize videoThreadType;

- (id)init {
    
    if (self = [super init]) {
        [self loadOptions];
    }
    
    return self;
}

- (void)loadOptions
{
    NSString *path=[NSString stringWithUTF8String:get_documents_path("iOS/options_v23.bin")];
    
    NSData *plistData;
    id plist = nil;
    NSError *error = nil;
    
    NSPropertyListFormat format;
    
    NSError *sqerr;
    plistData = [NSData dataWithContentsOfFile:path options: NSMappedRead error:&sqerr];
    
    if (plistData != nil)
    {
        plist = [NSPropertyListSerialization propertyListWithData:plistData
                                                      options:NSPropertyListImmutable
                                                       format:&format
                                                        error:&error];
    }
    
    if(!plist)
    {
        
        //NSLog(error);
        
        //[error release];
        
        optionsArray = [[NSMutableArray alloc] init];
        
        keepAspectRatioPort=1;
        keepAspectRatioLand=1;
        smoothedPort=g_isIpad?1:0;
        smoothedLand=g_isIpad?1:0;
        
        tvFilterPort = 0;
        tvFilterLand = 0;
        scanlineFilterPort = 0;
        scanlineFilterLand = 0;
        
        showFPS = 0;
        showINFO = 0;
        fourButtonsLand = 0;
        animatedButtons = 1;
        
        fullLand = animatedButtons;
        fullPort = 0;
        
        skinValue = 0;
        
        btDeadZoneValue = 2;
        touchDeadZone = 1;
        
        overscanValue = 0;
        tvoutNative = 1;
        
        touchtype = 1;
        analogDeadZoneValue = 2;
        
        controltype = 0;
        
        soundValue = 5;
        
        throttle = 1;
        fsvalue = 0;
        sticktype = 0;
        numbuttons = 0;
        aplusb = 0;
        cheats = 1;
        sleep = 1;
        
        forcepxa = 0;
        emures = 0;
        p1aspx = 0;
        
        filterClones=0;
        filterFavorites=0;
        filterNotWorking=1;
        manufacturerValue=0;
        yearGTEValue=0;
        yearLTEValue=0;
        driverSourceValue=0;
        categoryValue=0;
        
        filterKeyword = nil;
        
        lowlsound = 0;
        vsync = 0;
        threaded = 1;
        dblbuff = 1;
        
        mainPriority = 5;
        videoPriority = 5;
        
        autofire = 0;
        hiscore = 0;
        
        stickSize = 2;
        buttonSize= 2;
        
        wpantype = 0;
        wfpeeraddr = nil;
        wfport = NETPLAY_PORT;
        wfframesync = 0;
        btlatency = 1;
        
        vbean2x = 1;
        vantialias = 1;
        vflicker = 0;
        
        emuspeed = 0;
        
        mainThreadType = 0;
        videoThreadType = 0;
        
        lightgunEnabled = 1;
        lightgunBottomScreenReload = 0;
        
        _turboXEnabled = 0;
        _turboYEnabled = 0;
        _turboAEnabled = 0;
        _turboBEnabled = 0;
        _turboLEnabled = 0;
        _turboREnabled = 0;
        
        touchAnalogEnabled = 1;
        touchAnalogHideTouchDirectionalPad = 1;
        touchAnalogHideTouchButtons = 0;
        touchAnalogSensitivity = 500.0;
        touchControlsOpacity = 50.0;
        
        touchDirectionalEnabled = 0;
    }
    else
    {
        
        optionsArray = [[NSMutableArray alloc] initWithArray:plist];
        
        keepAspectRatioPort = [[[optionsArray objectAtIndex:0] objectForKey:@"KeepAspectPort"] intValue];
        keepAspectRatioLand = [[[optionsArray objectAtIndex:0] objectForKey:@"KeepAspectLand"] intValue];
        smoothedLand = [[[optionsArray objectAtIndex:0] objectForKey:@"SmoothedLand"] intValue];
        smoothedPort = [[[optionsArray objectAtIndex:0] objectForKey:@"SmoothedPort"] intValue];
        
        tvFilterPort = [[[optionsArray objectAtIndex:0] objectForKey:@"TvFilterPort"] intValue];
        tvFilterLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"TvFilterLand"] intValue];
        
        scanlineFilterPort =  [[[optionsArray objectAtIndex:0] objectForKey:@"ScanlineFilterPort"] intValue];
        scanlineFilterLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"ScanlineFilterLand"] intValue];
        lightgunEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"lightgunEnabled"] intValue];
        lightgunBottomScreenReload = [[[optionsArray objectAtIndex:0] objectForKey:@"lightgunBottomScreenReload"] intValue];
        touchAnalogEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"touchAnalogEnabled"] intValue];
        touchAnalogHideTouchDirectionalPad = [[[optionsArray objectAtIndex:0] objectForKey:@"touchAnalogHideTouchDirectionalPad"] intValue];
        touchAnalogHideTouchButtons = [[[optionsArray objectAtIndex:0] objectForKey:@"touchAnalogHideTouchButtons"] intValue];
        touchAnalogSensitivity = [[[optionsArray objectAtIndex:0] objectForKey:@"touchAnalogSensitivity"] floatValue];
        id prefTouchControlOpacity = [[optionsArray objectAtIndex:0] objectForKey:@"touchControlsOpacity"];
        if ( prefTouchControlOpacity == nil ) {
            touchControlsOpacity = 50.0;
        } else {
            touchControlsOpacity = [prefTouchControlOpacity floatValue];
        }
        showFPS =  [[[optionsArray objectAtIndex:0] objectForKey:@"showFPS"] intValue];
        showINFO =  [[[optionsArray objectAtIndex:0] objectForKey:@"showINFO"] intValue];
        fourButtonsLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"fourButtonsLand"] intValue];
        animatedButtons =  [[[optionsArray objectAtIndex:0] objectForKey:@"animatedButtons"] intValue];
        fullLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"fullLand"] intValue];
        fullPort =  [[[optionsArray objectAtIndex:0] objectForKey:@"fullPort"] intValue];
        
        _turboXEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboXEnabled"] intValue];
        _turboYEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboYEnabled"] intValue];
        _turboAEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboAEnabled"] intValue];
        _turboBEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboBEnabled"] intValue];
        _turboLEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboLEnabled"] intValue];
        _turboREnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"turboREnabled"] intValue];
        
        touchDirectionalEnabled = [[[optionsArray objectAtIndex:0] objectForKey:@"touchDirectionalEnabled"] intValue];
        
        skinValue =  [[[optionsArray objectAtIndex:0] objectForKey:@"skinValue"] intValue];
        
        btDeadZoneValue =  [[[optionsArray objectAtIndex:0] objectForKey:@"btDeadZoneValue"] intValue];
        touchDeadZone =  [[[optionsArray objectAtIndex:0] objectForKey:@"touchDeadZone"] intValue];
        
        overscanValue =  [[[optionsArray objectAtIndex:0] objectForKey:@"overscanValue"] intValue];
        tvoutNative =  [[[optionsArray objectAtIndex:0] objectForKey:@"tvoutNative"] intValue];
        
        touchtype =  [[[optionsArray objectAtIndex:0] objectForKey:@"inputTouchType"] intValue];
        analogDeadZoneValue =  [[[optionsArray objectAtIndex:0] objectForKey:@"analogDeadZoneValue"] intValue];
        controltype =  [[[optionsArray objectAtIndex:0] objectForKey:@"controlType"] intValue];
        
        soundValue =  [[[optionsArray objectAtIndex:0] objectForKey:@"soundValue"] intValue];
        
        throttle  =  [[[optionsArray objectAtIndex:0] objectForKey:@"throttle"] intValue];
        fsvalue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"fsvalue"] intValue];
        sticktype  =  [[[optionsArray objectAtIndex:0] objectForKey:@"sticktype"] intValue];
        numbuttons  =  [[[optionsArray objectAtIndex:0] objectForKey:@"numbuttons"] intValue];
        aplusb  =  [[[optionsArray objectAtIndex:0] objectForKey:@"aplusb"] intValue];
        cheats  =  [[[optionsArray objectAtIndex:0] objectForKey:@"cheats"] intValue];
        sleep  =  [[[optionsArray objectAtIndex:0] objectForKey:@"sleep"] intValue];
        
        forcepxa  =  [[[optionsArray objectAtIndex:0] objectForKey:@"forcepxa"] intValue];
        emures  =  [[[optionsArray objectAtIndex:0] objectForKey:@"emures"] intValue];
        
        p1aspx  =  [[[optionsArray objectAtIndex:0] objectForKey:@"p1aspx"] intValue];
        
        filterClones  =  [[[optionsArray objectAtIndex:0] objectForKey:@"filterClones"] intValue];
        filterFavorites  =  [[[optionsArray objectAtIndex:0] objectForKey:@"filterFavorites"] intValue];
        filterNotWorking  =  [[[optionsArray objectAtIndex:0] objectForKey:@"filterNotWorking"] intValue];
        manufacturerValue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"manufacturerValue"] intValue];
        yearGTEValue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"yearGTEValue"] intValue];
        yearLTEValue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"yearLTEValue"] intValue];
        driverSourceValue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"driverSourceValue"] intValue];
        categoryValue  =  [[[optionsArray objectAtIndex:0] objectForKey:@"categoryValue"] intValue];
        
        filterKeyword  =  [[optionsArray objectAtIndex:0] objectForKey:@"filterKeyword"];
        
        lowlsound  =  [[[optionsArray objectAtIndex:0] objectForKey:@"lowlsound"] intValue];
        vsync  =  [[[optionsArray objectAtIndex:0] objectForKey:@"vsync"] intValue];
        threaded  =  [[[optionsArray objectAtIndex:0] objectForKey:@"threaded"] intValue];
        dblbuff  =  [[[optionsArray objectAtIndex:0] objectForKey:@"dblbuff"] intValue];
        
        mainPriority  =  [[[optionsArray objectAtIndex:0] objectForKey:@"mainPriority"] intValue];
        videoPriority  =  [[[optionsArray objectAtIndex:0] objectForKey:@"videoPriority"] intValue];
        
        autofire =  [[[optionsArray objectAtIndex:0] objectForKey:@"autofire"] intValue];
        
        hiscore  =  [[[optionsArray objectAtIndex:0] objectForKey:@"hiscore"] intValue];
        
        buttonSize =  [[[optionsArray objectAtIndex:0] objectForKey:@"buttonSize"] intValue];
        stickSize =  [[[optionsArray objectAtIndex:0] objectForKey:@"stickSize"] intValue];
        
        wpantype  =  [[[optionsArray objectAtIndex:0] objectForKey:@"wpantype"] intValue];
        wfpeeraddr  =  [[optionsArray objectAtIndex:0] objectForKey:@"wfpeeraddr"];
        wfport  =  [[[optionsArray objectAtIndex:0] objectForKey:@"wfport"] intValue];
        wfframesync  =  [[[optionsArray objectAtIndex:0] objectForKey:@"wfframesync"] intValue];
        btlatency  =  [[[optionsArray objectAtIndex:0] objectForKey:@"btlatency"] intValue];
        
        if([wfpeeraddr isEqualToString:@""])
            wfpeeraddr = nil;
        if([filterKeyword isEqualToString:@""])
            filterKeyword = nil;
        
        vbean2x  =  [[[optionsArray objectAtIndex:0] objectForKey:@"vbean2x"] intValue];
        vantialias  =  [[[optionsArray objectAtIndex:0] objectForKey:@"vantialias"] intValue];
        vflicker  =  [[[optionsArray objectAtIndex:0] objectForKey:@"vflicker"] intValue];
        
        emuspeed  =  [[[optionsArray objectAtIndex:0] objectForKey:@"emuspeed"] intValue];
        
        mainThreadType  =  [[[optionsArray objectAtIndex:0] objectForKey:@"mainThreadType"] intValue];
        videoThreadType  =  [[[optionsArray objectAtIndex:0] objectForKey:@"videoThreadType"] intValue];
    }
    
}

- (void)saveOptions
{
    
    NSString *wfpeeraddr_tmp = wfpeeraddr == nil ? @"" : wfpeeraddr;
    NSString *filterKeyword_tmp = filterKeyword == nil ? @"" : filterKeyword;
    
    [optionsArray removeAllObjects];
    [optionsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat:@"%d", keepAspectRatioPort], @"KeepAspectPort",
                             [NSString stringWithFormat:@"%d", keepAspectRatioLand], @"KeepAspectLand",
                             [NSString stringWithFormat:@"%d", smoothedLand], @"SmoothedLand",
                             [NSString stringWithFormat:@"%d", smoothedPort], @"SmoothedPort",
                             
                             [NSString stringWithFormat:@"%d", tvFilterPort], @"TvFilterPort",
                             [NSString stringWithFormat:@"%d", tvFilterLand], @"TvFilterLand",
                             
                             [NSString stringWithFormat:@"%d", scanlineFilterPort], @"ScanlineFilterPort",
                             [NSString stringWithFormat:@"%d", scanlineFilterLand], @"ScanlineFilterLand",
                             [NSString stringWithFormat:@"%d", lightgunEnabled],
                             @"lightgunEnabled",
                             [NSString stringWithFormat:@"%d", lightgunBottomScreenReload], @"lightgunBottomScreenReload",
                             [NSString stringWithFormat:@"%d", touchAnalogEnabled], @"touchAnalogEnabled",
                             [NSString stringWithFormat:@"%d", touchAnalogHideTouchDirectionalPad], @"touchAnalogHideTouchDirectionalPad",
                             [NSString stringWithFormat:@"%d", touchAnalogHideTouchButtons], @"touchAnalogHideTouchButtons",
                             [NSString stringWithFormat:@"%f", touchAnalogSensitivity], @"touchAnalogSensitivity",
                             [NSString stringWithFormat:@"%f", touchControlsOpacity], @"touchControlsOpacity",
                             [NSString stringWithFormat:@"%d", showFPS], @"showFPS",
                             [NSString stringWithFormat:@"%d", showINFO], @"showINFO",
                             [NSString stringWithFormat:@"%d", fourButtonsLand], @"fourButtonsLand",
                             [NSString stringWithFormat:@"%d", animatedButtons], @"animatedButtons",
                             
                             [NSString stringWithFormat:@"%d", _turboXEnabled], @"turboXEnabled",
                             [NSString stringWithFormat:@"%d", _turboYEnabled], @"turboYEnabled",
                             [NSString stringWithFormat:@"%d", _turboAEnabled], @"turboAEnabled",
                             [NSString stringWithFormat:@"%d", _turboBEnabled], @"turboBEnabled",
                             [NSString stringWithFormat:@"%d", _turboLEnabled], @"turboLEnabled",
                             [NSString stringWithFormat:@"%d", _turboREnabled], @"turboREnabled",
                             
                             [NSString stringWithFormat:@"%d", touchDirectionalEnabled], @"touchDirectionalEnabled",
                             
                             [NSString stringWithFormat:@"%d", fullLand], @"fullLand",
                             [NSString stringWithFormat:@"%d", fullPort], @"fullPort",
                             
                             [NSString stringWithFormat:@"%d", skinValue], @"skinValue",
                             
                             [NSString stringWithFormat:@"%d", btDeadZoneValue], @"btDeadZoneValue",
                             [NSString stringWithFormat:@"%d", touchDeadZone], @"touchDeadZone",
                             
                             [NSString stringWithFormat:@"%d", overscanValue], @"overscanValue",
                             [NSString stringWithFormat:@"%d", tvoutNative], @"tvoutNative",
                             
                             [NSString stringWithFormat:@"%d", touchtype], @"inputTouchType",
                             [NSString stringWithFormat:@"%d", analogDeadZoneValue], @"analogDeadZoneValue",
                             
                             [NSString stringWithFormat:@"%d", controltype], @"controlType",
                             
                             [NSString stringWithFormat:@"%d", soundValue], @"soundValue",
                             
                             [NSString stringWithFormat:@"%d", throttle], @"throttle",
                             [NSString stringWithFormat:@"%d", fsvalue], @"fsvalue",
                             [NSString stringWithFormat:@"%d", sticktype], @"sticktype",
                             [NSString stringWithFormat:@"%d", numbuttons], @"numbuttons",
                             [NSString stringWithFormat:@"%d", aplusb], @"aplusb",
                             [NSString stringWithFormat:@"%d", cheats], @"cheats",
                             [NSString stringWithFormat:@"%d", sleep], @"sleep",
                             
                             [NSString stringWithFormat:@"%d", forcepxa], @"forcepxa",
                             [NSString stringWithFormat:@"%d", emures], @"emures",
                             
                             [NSString stringWithFormat:@"%d", p1aspx], @"p1aspx",
                             
                             [NSString stringWithFormat:@"%d", filterClones], @"filterClones",
                             [NSString stringWithFormat:@"%d", filterFavorites], @"filterFavorites",
                             [NSString stringWithFormat:@"%d", filterNotWorking], @"filterNotWorking",
                             [NSString stringWithFormat:@"%d", manufacturerValue], @"manufacturerValue",
                             [NSString stringWithFormat:@"%d", yearGTEValue], @"yearGTEValue",
                             [NSString stringWithFormat:@"%d", yearLTEValue], @"yearLTEValue",
                             [NSString stringWithFormat:@"%d", driverSourceValue], @"driverSourceValue",
                             [NSString stringWithFormat:@"%d", categoryValue], @"categoryValue",
                             [NSString stringWithFormat:@"%d", lowlsound], @"lowlsound",
                             [NSString stringWithFormat:@"%d", vsync], @"vsync",
                             [NSString stringWithFormat:@"%d", threaded], @"threaded",
                             [NSString stringWithFormat:@"%d", dblbuff], @"dblbuff",
                             
                             [NSString stringWithFormat:@"%d", mainPriority], @"mainPriority",
                             [NSString stringWithFormat:@"%d", videoPriority], @"videoPriority",
                             
                             [NSString stringWithFormat:@"%d", autofire], @"autofire",
                             [NSString stringWithFormat:@"%d", hiscore], @"hiscore",
                             
                             [NSString stringWithFormat:@"%d", stickSize], @"stickSize",
                             [NSString stringWithFormat:@"%d", buttonSize], @"buttonSize",
                             
                             [NSString stringWithFormat:@"%d", wpantype], @"wpantype",
                             [NSString stringWithFormat:@"%d", wfport], @"wfport",
                             [NSString stringWithFormat:@"%d", wfframesync], @"wfframesync",
                             [NSString stringWithFormat:@"%d", btlatency], @"btlatency",
                             wfpeeraddr_tmp, @"wfpeeraddr",
                             
                             filterKeyword_tmp, @"filterKeyword", //CUIADO si es nill termina la lista
                             
                             [NSString stringWithFormat:@"%d", vbean2x], @"vbean2x",
                             [NSString stringWithFormat:@"%d", vantialias], @"vantialias",
                             [NSString stringWithFormat:@"%d", vflicker], @"vflicker",
                             
                             [NSString stringWithFormat:@"%d", emuspeed], @"emuspeed",
                             
                             [NSString stringWithFormat:@"%d", mainThreadType], @"mainThreadType",
                             [NSString stringWithFormat:@"%d", videoThreadType], @"videoThreadType",
                             
                             nil]];
    
    
    NSString *path=[NSString stringWithUTF8String:get_documents_path("iOS/options_v23.bin")];
    
    NSData *plistData;
    
    NSError *error = nil;
    
    plistData = [NSPropertyListSerialization dataWithPropertyList:optionsArray
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
