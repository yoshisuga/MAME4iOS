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

#include "myosd.h"

#import "OptionsController.h"
#import "Globals.h"
#import "ListOptionController.h"
#import "NetplayController.h"
#import "FilterOptionController.h"
#import "InputOptionController.h"
#import "DefaultOptionController.h"
#import "DonateController.h"
#import "HelpController.h"
#import "EmulatorController.h"

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
	id plist;
	NSString *error;
	
	NSPropertyListFormat format;
	
    NSError *sqerr;
	plistData = [NSData dataWithContentsOfFile:path options: NSMappedRead error:&sqerr];
		
	plist = [NSPropertyListSerialization propertyListFromData:plistData			 
											 mutabilityOption:NSPropertyListImmutable			 
													   format:&format
											 errorDescription:&error];
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
        showINFO = 1;
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

        showFPS =  [[[optionsArray objectAtIndex:0] objectForKey:@"showFPS"] intValue];
        showINFO =  [[[optionsArray objectAtIndex:0] objectForKey:@"showINFO"] intValue];
        fourButtonsLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"fourButtonsLand"] intValue];
        animatedButtons =  [[[optionsArray objectAtIndex:0] objectForKey:@"animatedButtons"] intValue];	
        fullLand =  [[[optionsArray objectAtIndex:0] objectForKey:@"fullLand"] intValue];
        fullPort =  [[[optionsArray objectAtIndex:0] objectForKey:@"fullPort"] intValue];
        
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

							 [NSString stringWithFormat:@"%d", showFPS], @"showFPS",							 
							 [NSString stringWithFormat:@"%d", showINFO], @"showINFO",							 
							 [NSString stringWithFormat:@"%d", fourButtonsLand], @"fourButtonsLand",							 
							 [NSString stringWithFormat:@"%d", animatedButtons], @"animatedButtons",							 							 							 											 
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
	
	NSString *error;
		
	plistData = [NSPropertyListSerialization dataFromPropertyList:optionsArray				 
										     format:NSPropertyListBinaryFormat_v1_0				 
										     errorDescription:&error];	
	if(plistData)		
	{
	    //NSError*err;
	
		BOOL b = [plistData writeToFile:path atomically:NO];
		//BOOL b = [plistData writeToFile:path options:0  error:&err];
		if(!b)
		{
			    UIAlertView *errAlert = [[UIAlertView alloc] initWithTitle:@"Error saving preferences!" 
															message://[NSString stringWithFormat:@"Error:%@",[err localizedDescription]]  
															@"Preferences cannot be saved.\n Check for write permissions. 'chmod -R 777 /var/mobile/Media/ROMs' if needed. Look at the help for details!." 
															delegate:self 
													        cancelButtonTitle:@"OK" 
													        otherButtonTitles: nil];	
	           [errAlert show];
	           [errAlert release];
		}		
	}
	else
	{

		NSLog(@"%@",error);		
		[error release];		
	}	
}

- (void)dealloc {
    
    [optionsArray dealloc];

	[super dealloc];
}

@end

@implementation OptionsController

@synthesize emuController;


- (id)init {
    
    if (self = [super init]) {
        switchKeepAspectPort=nil;
        switchKeepAspectLand=nil;
        switchSmoothedPort=nil;
        switchSmoothedLand=nil;
        
        switchTvFilterPort=nil;
        switchTvFilterLand=nil;
        switchScanlineFilterPort=nil;
        switchScanlineFilterLand=nil;
        
        switchShowFPS=nil;
        switchShowINFO=nil;

        switchfullLand=nil;
        switchfullPort=nil;
                                        
        switchThrottle = nil;
        

        switchSleep = nil;
        
        switchForcepxa = nil;
        
        arrayEmuRes = [[NSArray alloc] initWithObjects:@"Auto",@"320x200",@"320x240",@"400x300",@"480x300",@"512x384",@"640x400",@"640x480",@"800x600",@"1024x768", nil];
                        
        arrayFSValue = [[NSArray alloc] initWithObjects:@"Auto",@"None", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10",nil];
        
        arrayOverscanValue = [[NSArray alloc] initWithObjects:@"None",@"1", @"2", @"3",@"4", @"5", @"6", nil];
        
        arraySkinValue = 
        [[NSArray alloc] initWithObjects: @"A", @"B (Layout 1)", @"B (Layout 2)", nil];
                
        switchLowlsound = nil;

        
        arrayEmuSpeed = [[NSArray alloc] initWithObjects: @"Default",
                         @"50%", @"60%", @"70%", @"80%", @"85%",@"90%",@"95%",@"100%",
                         @"105%", @"110%", @"115%", @"120%", @"130%",@"140%",@"150%",
                         nil];
    }

    return self;
}

- (void)loadView {
    

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target: emuController  action:  @selector(done:) ];
    self.navigationItem.rightBarButtonItem = backButton;
    [backButton release];
    
    self.title = NSLocalizedString(@"Settings", @"");
    
    UITableView *tableView = [[UITableView alloc] 
    initWithFrame:CGRectMake(0, 0, 240, 200) style:UITableViewStyleGrouped];
          
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizesSubviews = YES;
    self.view = tableView;
    [tableView release];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
   NSString *cellIdentifier = [NSString stringWithFormat: @"%d:%d", [indexPath indexAtPosition:0], [indexPath indexAtPosition:1]];
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
   
   if (cell == nil)
   {
       
      UITableViewCellStyle style;
       
      if((indexPath.section==kFilterSection && indexPath.row==9)
          || (indexPath.section==kMultiplayerSection && indexPath.row==0)
          || (indexPath.section==kMultiplayerSection && indexPath.row==1)
          || (indexPath.section==kMultiplayerSection && indexPath.row==2)
         )
          style = UITableViewCellStyleDefault;
       else
          style = UITableViewCellStyleValue1;
       
      cell = [[[UITableViewCell alloc] initWithStyle:style
                                      //UITableViewCellStyleDefault
                                      //UITableViewCellStyleValue1
                                      reuseIdentifier:@"CellIdentifier"] autorelease];
       
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
   }
   
   Options *op = [[Options alloc] init];
   
   switch (indexPath.section)
   {
           
       case kSupportSection:
       {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text   = @"Help";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
                   
               case 1:
               {
                   cell.textLabel.text   = @"Donate";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
           }
           break;
       }
           
       case kPortraitSection: //Portrait
       {
           switch (indexPath.row) 
           {
               case 0: 
               {
                   cell.textLabel.text   = @"Smoothed Image";
                   [switchSmoothedPort release];
                   switchSmoothedPort = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchSmoothedPort;
                   [switchSmoothedPort setOn:[op smoothedPort] animated:NO];
                   [switchSmoothedPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];                   
                   break;
               }
               
               case 1:
               {
                   cell.textLabel.text   = @"CRT Effect";
                   [switchTvFilterPort release];
                   switchTvFilterPort  = [[UISwitch alloc] initWithFrame:CGRectZero];                               
                   cell.accessoryView = switchTvFilterPort ;
                   [switchTvFilterPort setOn:[op tvFilterPort] animated:NO];
                   [switchTvFilterPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
               case 2:
               {
                   cell.textLabel.text   = @"Scanline Effect";
                   [switchScanlineFilterPort release];
                   switchScanlineFilterPort  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchScanlineFilterPort ;
                   [switchScanlineFilterPort setOn:[op scanlineFilterPort] animated:NO];
                   [switchScanlineFilterPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }          
               case 3:
               {
                   cell.textLabel.text   = @"Full Screen";
                   [switchfullPort release];
                   switchfullPort  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchfullPort;
                   [switchfullPort setOn:[op fullPort] animated:NO];
                   [switchfullPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged]; 
                   break;
               }   
               case 4:
               {
	                cell.textLabel.text   = @"Keep Aspect Ratio";
                   [switchKeepAspectPort release];
	                switchKeepAspectPort  = [[UISwitch alloc] initWithFrame:CGRectZero];                
	                cell.accessoryView = switchKeepAspectPort;
	                [switchKeepAspectPort setOn:[op keepAspectRatioPort] animated:NO];
	                [switchKeepAspectPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }             
                           
           }    
           break;
       }
       case kLandscapeSection:  //Landscape
       {
           switch (indexPath.row) 
           {
               case 0: 
               {
                   cell.textLabel.text  = @"Smoothed Image";
                   [switchSmoothedLand release];
                   switchSmoothedLand = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchSmoothedLand;
                   [switchSmoothedLand setOn:[op smoothedLand] animated:NO];
                   [switchSmoothedLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];  
                   break;
               }
               case 1:
               {
                   cell.textLabel.text   = @"CRT Effect";
                   [switchTvFilterLand release];
                   switchTvFilterLand  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchTvFilterLand ;
                   [switchTvFilterLand setOn:[op tvFilterLand] animated:NO];
                   [switchTvFilterLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];  
                   break;
               }
               case 2:
               {
                   cell.textLabel.text   = @"Scanline Effect";
                   [switchScanlineFilterLand release];
                   switchScanlineFilterLand  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchScanlineFilterLand ;
                   [switchScanlineFilterLand setOn:[op scanlineFilterLand] animated:NO];
                   [switchScanlineFilterLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 3:
               {
                   cell.textLabel.text   = @"Full Screen";
                   [switchfullLand release];
                   switchfullLand  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchfullLand ;
                   [switchfullLand setOn:[op fullLand] animated:NO];
                   [switchfullLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }

               case 4:
               {

                    cell.textLabel.text   = @"Keep Aspect Ratio";
                   [switchKeepAspectLand release];
                    switchKeepAspectLand  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                    cell.accessoryView = switchKeepAspectLand;
                    [switchKeepAspectLand setOn:[op keepAspectRatioLand] animated:NO];
                    [switchKeepAspectLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
   
                   break;
               }
           }
           break;
        }    
        case kInputSection:  //Input
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Game Input";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            break;
        }
       case kDefaultsSection:
       {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text = @"Defaults";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
           }
           break;
       }
        case kMiscSection:  //Miscellaneous
        {
            switch (indexPath.row) 
            {
              case 0:
               {
                   cell.textLabel.text   = @"Show FPS";
                   [switchShowFPS release];
                   switchShowFPS  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchShowFPS ;
                   [switchShowFPS setOn:[op showFPS] animated:NO];
                   [switchShowFPS addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 1:
               {                                                         
                   cell.textLabel.text   = @"Emulated Resolution";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   cell.detailTextLabel.text = [arrayEmuRes objectAtIndex:op.emures];

                   break;
               }
               case 2:
               {
                    cell.textLabel.text   = @"Emulated Speed";
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayEmuSpeed objectAtIndex:op.emuspeed];
                    
                    break;
               }
               case 3:
               {
                   cell.textLabel.text   = @"Throttle";
                   [switchThrottle release];
                   switchThrottle  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchThrottle ;
                   [switchThrottle setOn:[op throttle] animated:NO];
                   [switchThrottle addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 4:
               {
                   cell.textLabel.text   = @"Frame Skip";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   cell.detailTextLabel.text = [arrayFSValue objectAtIndex:op.fsvalue];
    
                   break;
               }
               case 5:
               {
                   cell.textLabel.text   = @"Force Pixel Aspect";
                   [switchForcepxa release];
                   switchForcepxa  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchForcepxa ;
                   [switchForcepxa setOn:[op forcepxa] animated:NO];
                   [switchForcepxa addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }  
              case 6:
               {
                   cell.textLabel.text   = @"Sleep on Idle";
                   [switchSleep release];
                   switchSleep  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchSleep ;
                   [switchSleep setOn:[op sleep] animated:NO];
                   [switchSleep addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }                                                                             
              case 7:
               {
                   cell.textLabel.text   = @"Show Info/Warnings";
                   [switchShowINFO release];
                   switchShowINFO  = [[UISwitch alloc] initWithFrame:CGRectZero];                
                   cell.accessoryView = switchShowINFO ;
                   [switchShowINFO setOn:[op showINFO] animated:NO];
                   [switchShowINFO addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 8:
               {
                    cell.textLabel.text   = @"Low Latency Audio";
                    [switchLowlsound release];
                    switchLowlsound  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchLowlsound ;
                    [switchLowlsound setOn:[op lowlsound] animated:NO];
                    [switchLowlsound addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
               }
               case 9:
               {
                   cell.textLabel.text   = @"Skin";
                   
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   cell.detailTextLabel.text = [arraySkinValue objectAtIndex:op.skinValue];

                   break;
               }
               case 10:
               {
                   cell.textLabel.text   = @"Overscan TV-OUT";
                   
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   cell.detailTextLabel.text = [arrayOverscanValue objectAtIndex:op.overscanValue];
                   
                   break;
               }
            }
            break;   
        }
       case kFilterSection:
       {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text = @"Game Filter";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
           }
           break;
       }
       case kMultiplayerSection:
       {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text = @"Peer-to-peer Netplay";
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
           }
           break;
       }
   }

   [op release];

   return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
      return kNumSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
		
    switch (section)
    {
          case kSupportSection: return @"Support";
          case kPortraitSection: return @"Portrait";
          case kLandscapeSection: return @"Landscape";
          case kInputSection: return @"";//@"Game Input";
          case kDefaultsSection: return @"";
          case kMiscSection: return @"";
          case kFilterSection: return @"";//@"Game Filter";
          case kMultiplayerSection: return @"";//@"Peer-to-peer Netplay";
    }
    return @"Error!";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
      switch (section)
      {
          case kSupportSection: return 2;
          case kPortraitSection: return 5;
          case kLandscapeSection: return 5;
          case kInputSection: return 1;
          case kDefaultsSection: return 1;
          case kMiscSection: return 11;
          case kFilterSection: return 1;
          case kMultiplayerSection: return 1;
      }
    return -1;
}

-(void)viewDidLoad{	

}


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     //return (interfaceOrientation == UIInterfaceOrientationPortrait);
     return YES;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


- (void)dealloc {
    
    [switchKeepAspectPort release];
    [switchKeepAspectLand release];
    [switchSmoothedPort release];
    [switchSmoothedLand release];
    [switchTvFilterPort release];
    [switchTvFilterLand release];
    [switchScanlineFilterPort release];
    [switchScanlineFilterLand release];
    
    [switchShowFPS release];
    [switchShowINFO release];

    
    [switchfullLand release];
    [switchfullPort release];
            
    [switchThrottle release];
    [switchSleep release];
    [switchForcepxa release];
    
    [arrayEmuRes release];

    [arrayFSValue release];
    [arrayOverscanValue release];
    [arraySkinValue release];
        
    [switchLowlsound release];
    
    [arrayEmuSpeed release];
    
    [super dealloc];
}

- (void)optionChanged:(id)sender
{
    Options *op = [[Options alloc] init];
	
	if(sender==switchKeepAspectPort)
	   op.keepAspectRatioPort = [switchKeepAspectPort isOn];
	
	if(sender==switchKeepAspectLand)    		
	   op.keepAspectRatioLand = [switchKeepAspectLand isOn];
	   	   
	if(sender==switchSmoothedPort)   
	   op.smoothedPort =  [switchSmoothedPort isOn];
	
	if(sender==switchSmoothedLand)
	   op.smoothedLand =  [switchSmoothedLand isOn];
		   
	if(sender == switchTvFilterPort)  
	   op.tvFilterPort =  [switchTvFilterPort isOn];
	   
	if(sender == switchTvFilterLand)   
	   op.tvFilterLand =  [switchTvFilterLand isOn];
	   
	if(sender == switchScanlineFilterPort)   
	   op.scanlineFilterPort =  [switchScanlineFilterPort isOn];
	   
	if(sender == switchScanlineFilterLand)
	   op.scanlineFilterLand =  [switchScanlineFilterLand isOn];    

    if(sender == switchShowFPS)
	   op.showFPS =  [switchShowFPS isOn];

    if(sender == switchShowINFO)
	   op.showINFO =  [switchShowINFO isOn];
				
	if(sender == switchfullLand) 
	   op.fullLand =  [switchfullLand isOn];

	if(sender == switchfullPort) 
	   op.fullPort =  [switchfullPort isOn];
  	   	     	   	         
    if(sender == switchThrottle)
        op.throttle = [switchThrottle isOn];    
       
    if(sender == switchSleep)
        op.sleep = [switchSleep isOn];

    if(sender == switchForcepxa)
        op.forcepxa = [switchForcepxa isOn];
            
    if(sender == switchLowlsound)
        op.lowlsound = [switchLowlsound isOn];
        
	[op saveOptions];
		
	[op release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    //printf("%d %d\n",section,row);
    
    switch (section)
    {
        case kSupportSection:
        {
            if (row==0){
                HelpController *controller = [[HelpController alloc] init];
                [[self navigationController] pushViewController:controller animated:YES];
                [controller release];
            }
            
            if (row==1){
                DonateController *controller = [[DonateController alloc] init];
                [[self navigationController] pushViewController:controller animated:YES];
                [controller release];
            }

            break;
        }
        case kInputSection:
        {
            if (row==0){
                InputOptionController *inputOptController = [[InputOptionController alloc] init];
                inputOptController.emuController = self.emuController;
                
                [[self navigationController] pushViewController:inputOptController animated:YES];
                [inputOptController release];
                [tableView reloadData];
            }
            break;
        }
        case kDefaultsSection:
        {
            if (row==0){
                DefaultOptionController *defaultOptController = [[DefaultOptionController alloc] init];
                defaultOptController.emuController = self.emuController;
                
                [[self navigationController] pushViewController:defaultOptController animated:YES];
                [defaultOptController release];
                [tableView reloadData];
            }
            break;
        }
        case kMiscSection:
        {
            if (row==1){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                               type:kTypeEmuRes list:arrayEmuRes];                         
                [[self navigationController] pushViewController:listController animated:YES];
                [listController release];
            }
            if (row==2){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                              type:kTypeEmuSpeed list:arrayEmuSpeed];
                [[self navigationController] pushViewController:listController animated:YES];
                [listController release];
            }
            if (row==4){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                type:kTypeFSValue list:arrayFSValue];                         
                [[self navigationController] pushViewController:listController animated:YES];
                [listController release];
            }
            if (row==9){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                        type:kTypeSkinValue list:arraySkinValue];  
                [[self navigationController] pushViewController:listController animated:YES];
                [listController release];
            }
            if (row==10){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                        type:kTypeOverscanValue list:arrayOverscanValue];
                [[self navigationController] pushViewController:listController animated:YES];
                [listController release];
            }

            break;
        }
        case kMultiplayerSection:
        {
            if(row==0)
            {
                NetplayController *netplayOptController = [[NetplayController alloc] init];
                netplayOptController.emuController = self.emuController;
                
                [[self navigationController] pushViewController:netplayOptController animated:YES];
                [netplayOptController release];
                [tableView reloadData];
            }
            break;
        }
        case kFilterSection:
        {
            if(row==0)
            {
                FilterOptionController *filterOptController = [[FilterOptionController alloc] init];
                filterOptController.emuController = self.emuController;
                
                [[self navigationController] pushViewController:filterOptController animated:YES];
                [filterOptController release];
                [tableView reloadData];
            }
            break;
        }
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UITableView *tableView = (UITableView *)self.view;
    [tableView reloadData];
}

@end
