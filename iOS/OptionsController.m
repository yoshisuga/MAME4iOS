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

#import "Options.h"
#import "OptionsController.h"
#import "Globals.h"
#import "ListOptionController.h"
#import "InputOptionController.h"
#import "HelpController.h"
#import "EmulatorController.h"
#import "ImageCache.h"

#if !TARGET_APPSTORE
#import "CloudSync.h"
#endif

#import "Alert.h"

@implementation OptionsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Settings", @"");
    
    UILabel* pad = [[UILabel alloc] init];
    pad.text = @" ";

#if TARGET_APPSTORE
    UIImageView* logo = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"AppLogo"] scaledToSize:CGSizeMake(300, 0)]];
#else
  UIImageView* logo = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mame_logo"] scaledToSize:CGSizeMake(300, 0)]];
#endif
  
    logo.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel* info = [[UILabel alloc] init];
#if TARGET_APPSTORE
    info.text = [self.applicationVersionInfoRelease stringByAppendingString:@"\n"];
#else
  info.text = [self.applicationVersionInfo stringByAppendingString:@"\n"];
#endif
    info.textAlignment = NSTextAlignmentCenter;
    info.numberOfLines = 0;
    
    UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[pad, logo, info]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionEqualSpacing;
    
    [stack setNeedsLayout]; [stack layoutIfNeeded];
    CGFloat height = [stack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    stack.frame =  CGRectMake(0, 0, self.view.bounds.size.width, height);
     
    self.tableView.tableHeaderView = stack;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
   UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
   cell.accessoryType = UITableViewCellAccessoryNone;
   
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
        case kVideoSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = NSLocalizedString(@"Filter", @"Settings: Video Section: Filter option");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [Options.arrayFilter optionFind:op.filter];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text   = NSLocalizedString(@"Skin",@"Settings: Video Section: Skin option");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [Options.arraySkin optionFind:op.skin];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text   = NSLocalizedString(@"Screen Shader", @"Settings: Video Section: Shader option");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [Options.arrayScreenShader optionFind:op.screenShader];
                    break;
                }
                case 3:
                {
                    cell.textLabel.text   = NSLocalizedString(@"Vector Shader",@"Settings: Video Section: Vector shader option");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [Options.arrayLineShader optionFind:op.lineShader];
                    break;
                }
               case 4:
               {
                    cell.textLabel.text   = NSLocalizedString(@"Keep Aspect Ratio",@"Settings: Video Section: Aspect Ratio option");
                    cell.accessoryView = [self optionSwitchForKey:@"keepAspectRatio"];
                   break;
               }
               case 5:
               {
                   cell.textLabel.text   = NSLocalizedString(@"Force Integer Scaling",@"Settings: Video Section: Integer scaling option");
                   cell.accessoryView = [self optionSwitchForKey:@"integerScalingOnly"];
                   break;
               }
               case 6:
               {
                   cell.textLabel.text   = NSLocalizedString(@"Force Pixel Aspect",@"Settings: Video Section: Skin option");
                   cell.accessoryView = [self optionSwitchForKey:@"forcepxa"];
                   break;
               }
            }
            break;
        }
       case kVectorSection:
       {
           switch (indexPath.row)
           {
               case 0:
                {
                    cell.textLabel.text = NSLocalizedString(@"Beam 2x", @"Settings: Vector Section: Beam2x option");
                    cell.accessoryView = [self optionSwitchForKey:@"vbean2x"];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = NSLocalizedString(@"Flicker", @"Settings: Vector Section: Flicker option");
                    cell.accessoryView = [self optionSwitchForKey:@"vflicker"];
                    break;
                }
           }
           break;
       }
       case kFullscreenSection:
        {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell.textLabel.text   = NSLocalizedString(@"Fullscreen (Portrait)", @"Settings: FullScreen Section: Portrait option");
                   cell.accessoryView = [self optionSwitchForKey:@"fullscreenPortrait"];
                   break;
               }
               case 1:
               {
                   cell.textLabel.text   = NSLocalizedString(@"Fullscreen (Landscape)", @"Settings: FullScreen Section: Landscape option");
                   cell.accessoryView = [self optionSwitchForKey:@"fullscreenLandscape"];
                   break;
               }
               case 2:
               {
                 cell.textLabel.text   = NSLocalizedString(@"Fullscreen (Controller)", @"Settings: FullScreen Section: Controller option");
                   cell.accessoryView = [self optionSwitchForKey:@"fullscreenJoystick"];
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
                    cell.textLabel.text = NSLocalizedString(@"Show FPS", @"Toggle to display frames per second counter");
                    cell.accessoryView = [self optionSwitchForKey:@"showFPS"];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = NSLocalizedString(@"Show HUD", @"Toggle to display heads-up display overlay");
                    cell.accessoryView = [self optionSwitchForKey:@"showHUD"];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = NSLocalizedString(@"Show Info/Warnings", @"Toggle to display information messages and warnings");
                    cell.accessoryView = [self optionSwitchForKey:@"showINFO"];
                    break;
                }
                case 3:
                {
                    cell.textLabel.text = NSLocalizedString(@"Cheats", @"Enable or disable cheat codes");
                     cell.accessoryView = [self optionSwitchForKey:@"cheats"];
                     break;
                }
                case 4:
                {
                     cell.textLabel.text = NSLocalizedString(@"Save Hiscores", @"Toggle to save high scores automatically");
                     cell.accessoryView = [self optionSwitchForKey:@"hiscore"];
                     break;
                }
                case 5:
                {
                     cell.textLabel.text = NSLocalizedString(@"Use DRC", @"Enable dynamic recompilation");
                     cell.accessoryView = [self optionSwitchForKey:@"useDRC"];
                     break;
                }
                case 6:
                {
                     cell.textLabel.text = NSLocalizedString(@"Emulated Speed", @"Adjust the speed of emulation");
                     cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                     cell.detailTextLabel.text = [Options.arrayEmuSpeed optionAtIndex:op.emuspeed];
                     break;
                }
                case 7:
                {
                     cell.textLabel.text = NSLocalizedString(@"Sound", @"Audio settings and configuration");
                     cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                     cell.detailTextLabel.text = [Options.arraySoundValue optionAtIndex:op.soundValue];
                     break;
                }
              case 8:
              {
                cell.textLabel.text = NSLocalizedString(@"Hide Test ROMs", @"Hide Test ROMs section");
                cell.accessoryView = [self optionSwitchForKey:@"hideTestROMs"];
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
                   cell.textLabel.text = NSLocalizedString(@"Hide Clones", @"Filter option to hide clone games from the list");
                   cell.accessoryView = [self optionSwitchForKey:@"filterClones"];
                   break;
               }
               case 1:
               {
                   cell.textLabel.text = NSLocalizedString(@"Hide Not Working", @"Filter option to hide non-functional games from the list");
                   cell.accessoryView = [self optionSwitchForKey:@"filterNotWorking"];
                   break;
               }
               case 2:
               {
                   cell.textLabel.text = NSLocalizedString(@"Hide BIOS", @"Filter option to hide BIOS files from the list");
                   cell.accessoryView = [self optionSwitchForKey:@"filterBIOS"];
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
                    cell.textLabel.text = NSLocalizedString(@"Game Input", @"Menu option for configuring game input controls");
                    cell.imageView.image = [UIImage systemImageNamed:@"gamecontroller"];
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
                   cell.textLabel.text = NSLocalizedString(@"Import", @"Menu option to import games or files");
                   cell.imageView.image = [UIImage systemImageNamed:@"square.and.arrow.down.on.square"];
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
               case 1:
               {
                   cell.textLabel.text = NSLocalizedString(@"Export", @"Menu option to export games or files");
                   cell.imageView.image = [UIImage systemImageNamed:@"square.and.arrow.up.on.square"];
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
               case 2:
               {
                   cell.textLabel.text = NSLocalizedString(@"Start Web Server", @"Menu option to start the web server for file transfers");
                   cell.imageView.image = [UIImage systemImageNamed:@"arrow.up.arrow.down.circle"];
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
               case 3:
               {
                   cell.textLabel.text = NSLocalizedString(@"Show Files", @"Menu option to view files in the file manager");
                   cell.imageView.image = [UIImage systemImageNamed:@"folder"];
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   break;
               }
           }
           break;
        }
#if !TARGET_APPSTORE
        case kCloudImportSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Export to iCloud";
                    cell.imageView.image = [UIImage systemImageNamed:@"icloud.and.arrow.up"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Import from iCloud";
                    cell.imageView.image = [UIImage systemImageNamed:@"icloud.and.arrow.down"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = @"Sync with iCloud";
                    cell.imageView.image = [UIImage systemImageNamed:@"arrow.clockwise.icloud"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
                case 3:
                {
                    cell.textLabel.text = @"Erase iCloud";
                    cell.imageView.image = [UIImage systemImageNamed:@"xmark.icloud"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                }
            }
            break;
        }
#endif
        case kResetSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

                    cell.textLabel.text = NSLocalizedString(@"Reset to Defaults", @"Button to restore all settings to their default values");
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
       case kBenchmarkSection:
       {
           switch (indexPath.row)
           {
               case 0:
               {
                   cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                   cell.textLabel.text = NSLocalizedString(@"Benchmark", @"Menu option to run performance benchmark test");
                   cell.textLabel.textColor = [UIColor whiteColor];
                   cell.textLabel.shadowColor = [UIColor blackColor];
                   cell.textLabel.textAlignment = NSTextAlignmentCenter;
                   cell.textLabel.font = [UIFont boldSystemFontOfSize:24.0];
                   cell.backgroundColor = self.view.tintColor; // [UIColor systemBlueColor];
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
      case kFullscreenSection: return NSLocalizedString(@"Fullscreen", @"Section header for fullscreen display options");
      case kVideoSection: return NSLocalizedString(@"Video Options", @"Section header for video display settings");
      case kVectorSection: return NSLocalizedString(@"Vector Options", @"Section header for vector graphics settings");
      case kMiscSection: return NSLocalizedString(@"Options", @"Section header for miscellaneous settings");
      case kFilterSection: return NSLocalizedString(@"Game Filter", @"Section header for game filtering options");
      case kOtherSection: return @""; // @"Other";
      case kImportSection: return NSLocalizedString(@"Import and Export", @"Section header for import and export functions");
#if !TARGET_APPSTORE
        case kCloudImportSection: return @"iCloud";
#endif
        case kResetSection: return @"";
        case kBenchmarkSection: return @"";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
      switch (section)
      {
#if TARGET_APPSTORE
          // Don't show the support section for App Store version for now because of all the references to MAME
          case kSupportSection: return 0;
#else
          case kSupportSection: return 2;
#endif
          case kFullscreenSection: return 3;
          case kOtherSection: return 1;
          case kVideoSection: return 7;
          case kVectorSection: return 2;
          case kMiscSection: return 9;
          case kFilterSection: return 3;
          case kImportSection: return 4;
#if !TARGET_APPSTORE
          case kCloudImportSection:
              if (CloudSync.status == CloudSyncStatusAvailable)
                  return 4;
              else if (CloudSync.status == CloudSyncStatusEmpty)
                  return 1;
              else
                  return 0;
#endif
          case kResetSection: return 1;
          case kBenchmarkSection:
              return self.presentingViewController == self.emuController ? 1 : 0;
      }
    return -1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (section)
    {
        case kSupportSection:
        {
            if (row==0){
                HelpController *controller = [[HelpController alloc] init];
                [[self navigationController] pushViewController:controller animated:YES];
            }
            if (row==1){
                HelpController *controller = [[HelpController alloc] initWithName:@"WHATSNEW.html" title:@"What's New"];
                [[self navigationController] pushViewController:controller animated:YES];
            }
            break;
        }
        case kOtherSection:
        {
            if (row==0){
                InputOptionController *inputOptController = [[InputOptionController alloc] initWithEmuController:self.emuController];
                [[self navigationController] pushViewController:inputOptController animated:YES];
                [tableView reloadData];
            }
            break;
        }
        case kVideoSection:
        {
            if (row==0){
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"filter" list:Options.arrayFilter title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==1){
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"skin" list:Options.arraySkin title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==2){
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"screenShader" list:Options.arrayScreenShader title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==3){
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"lineShader" list:Options.arrayLineShader title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            break;
        }
        case kMiscSection:
        {
            if (row==6) {
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"emuspeed" list:Options.arrayEmuSpeed title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            if (row==7) {
                ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"soundValue" list:Options.arraySoundValue title:cell.textLabel.text];
                [[self navigationController] pushViewController:listController animated:YES];
            }
            break;
        }
        case kImportSection:
        {
            if (row==0) {
                [self.emuController runImport];
            }
            if (row==1) {
                [self.emuController runExport];
            }
            if (row==2) {
                [self.emuController runServer];
            }
            if (row==3) {
                [self.emuController runShowFiles];
            }
            break;
        }
#if !TARGET_APPSTORE
        case kCloudImportSection:
        {
            if (row==0) {
                [CloudSync export];
            }
            if (row==1) {
                [CloudSync import];
            }
            if (row==2) {
                [CloudSync sync];
            }
            if (row==3) {
                [self showAlertWithTitle:@"Erase iCloud?" message:nil buttons:@[@"Erase", @"Cancel"] handler:^(NSUInteger button) {
                    if (button == 0)
                        [CloudSync delete];
                }];
            }
            break;
        }
#endif
        case kResetSection:
        {
            if (row==0) {
                [self.emuController runReset];
            }
            break;
        }
        case kBenchmarkSection:
        {
            if (row==0) {
                [self.emuController runBenchmark];
            }
            break;
        }
    }
}

@end
