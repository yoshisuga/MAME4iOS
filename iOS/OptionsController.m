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

#import "Options.h"
#import "OptionsController.h"
#import "Globals.h"
#import "ListOptionController.h"
#import "NetplayController.h"
#import "FilterOptionController.h"
#import "InputOptionController.h"
#import "DefaultOptionController.h"
#import "HelpController.h"
#import "EmulatorController.h"
#import "SystemImage.h"
#import "ImageCache.h"

@implementation OptionsController

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
        switchfullLandJoy=nil;
        switchfullPortJoy=nil;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Settings", @"");
    
    UIImageView* logo = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mame_logo"] scaledToSize:CGSizeMake(300, 0)]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel* info = [[UILabel alloc] init];
    info.text = [self.applicationVersionInfo stringByAppendingString:@"\n"];
    info.textAlignment = NSTextAlignmentCenter;
    info.numberOfLines = 0;
    [info sizeToFit];
    
    UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[logo, info]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionEqualSpacing;
    stack.layoutMargins = UIEdgeInsetsMake(4.0, 0.0, 4.0, 0.0);
    
    [stack setNeedsLayout];
    [stack layoutIfNeeded];
    
    CGSize headerSize = [stack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat height = headerSize.height;
    CGRect frame = stack.frame;
    
    frame.size.height = height;
    stack.frame = frame;
     
    self.tableView.tableHeaderView = stack;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
   NSString *cellIdentifier = [NSString stringWithFormat: @"%d:%d", (int)[indexPath indexAtPosition:0], (int)[indexPath indexAtPosition:1]];
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
   
   if (cell == nil)
   {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"CellIdentifier"];
       
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
                   cell.imageView.image = [UIImage systemImageNamed:@"questionmark.circle"];
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
               case 1:
               {
                   cell.textLabel.text   = @"What's New";
                   cell.imageView.image = [UIImage systemImageNamed:@"info.circle"];
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
                   switchSmoothedPort = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchSmoothedPort;
                   [switchSmoothedPort setOn:[op smoothedPort] animated:NO];
                   [switchSmoothedPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];                   
                   break;
               }
               
               case 1:
               {
                   cell.textLabel.text   = @"CRT Effect";
                   switchTvFilterPort  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchTvFilterPort ;
                   [switchTvFilterPort setOn:[op tvFilterPort] animated:NO];
                   [switchTvFilterPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
               case 2:
               {
                   cell.textLabel.text   = @"Scanline Effect";
                   switchScanlineFilterPort  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchScanlineFilterPort ;
                   [switchScanlineFilterPort setOn:[op scanlineFilterPort] animated:NO];
                   [switchScanlineFilterPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }          
               case 3:
               {
                   cell.textLabel.text   = @"Full Screen";
                   switchfullPort  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchfullPort;
                   [switchfullPort setOn:[op fullPort] animated:NO];
                   [switchfullPort addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
               case 4:
               {
                   cell.textLabel.text   = @"Full Screen with Controller";
                   switchfullPortJoy  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchfullPortJoy;
                   [switchfullPortJoy setOn:[op fullPortJoy] animated:NO];
                   [switchfullPortJoy addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
               case 5:
               {
	                cell.textLabel.text   = @"Keep Aspect Ratio";
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
                   switchSmoothedLand = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchSmoothedLand;
                   [switchSmoothedLand setOn:[op smoothedLand] animated:NO];
                   [switchSmoothedLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];  
                   break;
               }
               case 1:
               {
                   cell.textLabel.text   = @"CRT Effect";
                   switchTvFilterLand  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchTvFilterLand ;
                   [switchTvFilterLand setOn:[op tvFilterLand] animated:NO];
                   [switchTvFilterLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];  
                   break;
               }
               case 2:
               {
                   cell.textLabel.text   = @"Scanline Effect";
                   switchScanlineFilterLand  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchScanlineFilterLand ;
                   [switchScanlineFilterLand setOn:[op scanlineFilterLand] animated:NO];
                   [switchScanlineFilterLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 3:
               {
                   cell.textLabel.text   = @"Full Screen";
                   switchfullLand  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchfullLand ;
                   [switchfullLand setOn:[op fullLand] animated:NO];
                   [switchfullLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }

               case 4:
               {
                   cell.textLabel.text   = @"Full Screen with Controller";
                   switchfullLandJoy  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchfullLandJoy;
                   [switchfullLandJoy setOn:[op fullLandJoy] animated:NO];
                   [switchfullLandJoy addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }

               case 5:
               {
                    cell.textLabel.text   = @"Keep Aspect Ratio";
                    switchKeepAspectLand  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchKeepAspectLand;
                    [switchKeepAspectLand setOn:[op keepAspectRatioLand] animated:NO];
                    [switchKeepAspectLand addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
   
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
                   switchForcepxa  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchForcepxa ;
                   [switchForcepxa setOn:[op forcepxa] animated:NO];
                   [switchForcepxa addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }  
              case 6:
               {
                   cell.textLabel.text   = @"Sleep on Idle";
                   switchSleep  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchSleep ;
                   [switchSleep setOn:[op sleep] animated:NO];
                   [switchSleep addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }                                                                             
              case 7:
               {
                   cell.textLabel.text   = @"Show Info/Warnings";
                   switchShowINFO  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchShowINFO ;
                   [switchShowINFO setOn:[op showINFO] animated:NO];
                   [switchShowINFO addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];   
                   break;
               }
               case 8:
               {
                    cell.textLabel.text   = @"Low Latency Audio";
                    switchLowlsound  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchLowlsound ;
                    [switchLowlsound setOn:[op lowlsound] animated:NO];
                    [switchLowlsound addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
               }
               case 9:
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
                   cell.textLabel.text   = @"Hide Clones";
                   switchHideClones  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchHideClones;
                   [switchHideClones setOn:[op filterClones] animated:NO];
                   [switchHideClones addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
               case 1:
               {
                   cell.textLabel.text   = @"Hide Not Working";
                   switchHideNotWorking  = [[UISwitch alloc] initWithFrame:CGRectZero];
                   cell.accessoryView = switchHideNotWorking;
                   [switchHideNotWorking setOn:[op filterNotWorking] animated:NO];
                   [switchHideNotWorking addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                   break;
               }
           }
           break;
        }
        case kOtherSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Peer-to-peer Netplay";
                    cell.imageView.image = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Game Input";
                    cell.imageView.image = [UIImage systemImageNamed:@"gamecontroller"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = @"Defaults";
                    cell.imageView.image = [UIImage systemImageNamed:@"slider.horizontal.3"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            break;
        }
        case kImportSection:
        {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text = @"Start Server";
                   cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle"]];
                   break;
               }
               case 1:
               {
                   cell.textLabel.text = @"Import ROMs";
                   cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down"]];
                   break;
               }
               case 2:
               {
                   cell.textLabel.text = @"Export ROMs";
                   cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]];
                   break;
               }
           }
           break;
        }
        case kResetSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Reset to Defaults";
                    cell.textLabel.textColor = [UIColor whiteColor];
                    cell.textLabel.shadowColor = [UIColor blackColor];
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:24.0];
                    cell.backgroundColor = [UIColor systemRedColor];
                    break;
                }
            }
            break;
         }

   }

   return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
      return kNumSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
		
    switch (section)
    {
        case kSupportSection: return @"";
        case kPortraitSection: return @"Portrait";
        case kLandscapeSection: return @"Landscape";
        case kMiscSection: return @"Options";
        case kFilterSection: return @"Game Filter";
        case kOtherSection: return @""; // @"Other";
        case kImportSection: return @"Import and Export";
        case kResetSection: return @"";
    }
    return @"Error!";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
      switch (section)
      {
          case kSupportSection: return 2;
          case kPortraitSection: return 6;
          case kLandscapeSection: return 6;
          case kOtherSection: return 3;
          case kMiscSection: return 10;
          case kFilterSection: return 2;
          case kImportSection: return 3;
          case kResetSection: return 1;
      }
    return -1;
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
  	 
    if(sender == switchfullLandJoy)
       op.fullLandJoy = [sender isOn];
                                      
    if(sender == switchfullPortJoy)
       op.fullPortJoy = [sender isOn];
    
    if(sender == switchThrottle)
        op.throttle = [switchThrottle isOn];    
       
    if(sender == switchSleep)
        op.sleep = [switchSleep isOn];

    if(sender == switchForcepxa)
        op.forcepxa = [switchForcepxa isOn];
            
    if(sender == switchLowlsound)
        op.lowlsound = [switchLowlsound isOn];
    
    if(sender == switchHideClones)
        op.filterClones = [sender isOn];

    if(sender == switchHideNotWorking)
        op.filterNotWorking = [sender isOn];

	[op saveOptions];
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
            }
            if (row==1){
                HelpController *controller = [[HelpController alloc] initWithName:@"whatsnew.html" title:@"What's New"];
                [[self navigationController] pushViewController:controller animated:YES];
            }
            break;
        }
        case kOtherSection:
        {
            if(row==0)
            {
                NetplayController *netplayOptController = [[NetplayController alloc]  initWithEmuController:self.emuController];
                [[self navigationController] pushViewController:netplayOptController animated:YES];
                [tableView reloadData];
            }
            if (row==1){
                InputOptionController *inputOptController = [[InputOptionController alloc] initWithEmuController:self.emuController];
                [[self navigationController] pushViewController:inputOptController animated:YES];
                [tableView reloadData];
            }
            if (row==2){
                DefaultOptionController *defaultOptController = [[DefaultOptionController alloc] initWithEmuController:self.emuController];
                [[self navigationController] pushViewController:defaultOptController animated:YES];
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
            }
            if (row==2){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                              type:kTypeEmuSpeed list:arrayEmuSpeed];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==4){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                type:kTypeFSValue list:arrayFSValue];                         
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==9){
                ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                        type:kTypeOverscanValue list:arrayOverscanValue];
                [[self navigationController] pushViewController:listController animated:YES];
            }

            break;
        }
        case kImportSection:
        {
            if (row==0) {
                [self.emuController runServer];
            }
            if (row==1) {
                [self.emuController runImport];
            }
            if (row==2) {
                [self.emuController runExport];
            }
            break;
        }
        case kResetSection:
        {
            if (row==0) {
                [self.emuController runReset];
            }
            break;
        }
    }
}

@end
