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

#import "InputOptionController.h"
#import "Globals.h"
#import "Options.h"
#import "OptionsController.h"
#import "ListOptionController.h"
#import "EmulatorController.h"

#include "myosd.h"

@implementation InputOptionController

@synthesize emuController;

- (id)init {
    UITableViewStyle style = UITableViewStyleGrouped;
#if TARGET_OS_IOS
    if (@available(iOS 13.0, *)) {
        style = UITableViewStyleInsetGrouped;
    }
#endif
    if (self = [super initWithStyle:style]) {
        
        switchAnimatedButtons=nil;

        arrayTouchType = [[NSArray alloc] initWithObjects:@"Digital DPAD",@"Digital Stick",@"Analog Stick", nil];
        arrayStickType = [[NSArray alloc] initWithObjects:@"Auto",@"2-Way",@"4-Way",@"8-Way", nil];
        arrayStickSizeValue = [[NSArray alloc] initWithObjects:@"Smaller", @"Small", @"Normal", @"Big", @"Bigger",nil];
        
        arrayNumbuttons = [[NSArray alloc] initWithObjects:@"Auto",@"0 Buttons",@"1 Buttons",@"2 Buttons",@"3 Buttons",@"4 Buttons",@"All Buttons", nil];
        switchAplusB = nil;
        arrayAutofireValue = [[NSArray alloc] initWithObjects:@"Disabled", @"Speed 1", @"Speed 2",@"Speed 3",
                              @"Speed 4", @"Speed 5",@"Speed 6",@"Speed 7",@"Speed 8",@"Speed 9",nil];
        arrayButtonSizeValue = [[NSArray alloc] initWithObjects:@"Smaller", @"Small", @"Normal", @"Big", @"Bigger",nil];
        
        arrayControlType = [[NSArray alloc] initWithObjects:@"None",@"iCade",@"iCP, Gametel",@"iMpulse", nil];
        
        switchP1aspx = nil;
        
        switchTouchDeadZone = nil;
        arrayAnalogDZValue = [[NSArray alloc] initWithObjects:@"1", @"2", @"3",@"4", @"5", @"6", nil];
        arrayBTDZValue = [[NSArray alloc] initWithObjects:@"1", @"2", @"3",@"4", @"5", @"6", nil];
        
        switchLightgunEnabled = nil;
        switchLightgunBottomScreenReload = nil;
        
        switchTurboAButtonEnabled = nil;
        switchTurboBButtonEnabled = nil;
        switchTurboXButtonEnabled = nil;
        switchTurboYButtonEnabled = nil;
        switchTurboLButtonEnabled = nil;
        switchTurboRButtonEnabled = nil;
        
        switchTouchAnalogEnabled = nil;
        switchTouchAnalogHideTouchButtons = nil;
        switchTouchAnalogHideTouchDirectionalPad = nil;
        sliderTouchAnalogSensitivity = nil;
        
        switchTouchDirectionalEnabled = nil;
        
        sliderTouchControlsOpacity = nil;
        
        self.title = @"Input Options";
    }
    return self;
}

- (void)dealloc {
    
    [switchAnimatedButtons release];
    [switchTouchDeadZone release];
    [switchAplusB release];
    [switchP1aspx release];
    [arrayNumbuttons release];
    [arrayStickType release];
    [arrayTouchType release];
    [arrayControlType release];
    [arrayAnalogDZValue release];
    [arrayBTDZValue release];
    [arrayAutofireValue release];
    [arrayButtonSizeValue release];
    [arrayStickSizeValue release];
    [switchLightgunEnabled release];
    [switchTurboAButtonEnabled release];
    [switchTurboBButtonEnabled release];
    [switchTurboXButtonEnabled release];
    [switchTurboYButtonEnabled release];
    [switchTurboLButtonEnabled release];
    [switchTurboRButtonEnabled release];
    [switchLightgunBottomScreenReload release];
    [switchTouchAnalogEnabled release];
    [switchTouchAnalogHideTouchDirectionalPad release];
    [switchTouchAnalogHideTouchButtons release];
    [sliderTouchAnalogSensitivity release];
    [switchTouchDirectionalEnabled release];
    [sliderTouchControlsOpacity release];
    
    [super dealloc];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UITableView *tableView = (UITableView *)self.view;
    [tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 11;
}

- (void)loadView {
    
    [super loadView];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                               style:UIBarButtonItemStylePlain
                                                              target: emuController  action:  @selector(done:) ];
    self.navigationItem.rightBarButtonItem = button;
    [button release];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return 2;
        case 1: return 3;
        case 2: return 4;
        case 3: return 1;
        case 4: return 2;
        case 5: return 1;
        case 6: return 3-!g_btjoy_available;
        case 7: return 2;
        case 8: return 6;
        case 9: return 4;
        case 10: return 1;
    }
    return -1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section)
    {
        case 0: return @"";
        case 1: return @"Stick & DPAD";
        case 2: return @"Buttons";
        case 3: return @"";
        case 4: return @"Touch Layout";
        case 5: return @"";
        case 6: return @"Dead Zone";
        case 7: return @"Touch Lightgun";
        case 8: return @"Turbo Mode Toggle";
        case 9: return @"Touch Analog";
        case 10: return @"Touch Directional Input";
    }
    return @"Error!";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat: @"%lu:%lu", (unsigned long)[indexPath indexAtPosition:0], (unsigned long)[indexPath indexAtPosition:1]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        
        UITableViewCellStyle style;
        
        if(indexPath.section==4)
            style = UITableViewCellStyleDefault;
        else
            style = UITableViewCellStyleValue1;
        
        if (indexPath.section == 7 && indexPath.row == 1 )
            style = UITableViewCellStyleSubtitle;
        
        cell = [[[UITableViewCell alloc] initWithStyle:style
                                       reuseIdentifier:@"CellIdentifier"] autorelease];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Options *op = [[Options alloc] init];
    
    switch (indexPath.section)
    {
        case 0:
        {
            if ( indexPath.row == 0 ) {
                cell.textLabel.text   = @"Animated";
                [switchAnimatedButtons release];
                switchAnimatedButtons  = [[UISwitch alloc] initWithFrame:CGRectZero];
                cell.accessoryView = switchAnimatedButtons ;
                [switchAnimatedButtons setOn:[op animatedButtons] animated:NO];
                [switchAnimatedButtons addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                break;
            } else if (indexPath.row == 1 ) {
                cell.textLabel.text = @"Opacity (Full Screen)";
                [sliderTouchControlsOpacity release];
                sliderTouchControlsOpacity = [[UISlider alloc] initWithFrame:CGRectZero];
                [sliderTouchControlsOpacity setMinimumValue:0.0];
                [sliderTouchControlsOpacity setMaximumValue:100.0];
                [sliderTouchControlsOpacity setValue:[op touchControlsOpacity]];
                [sliderTouchControlsOpacity addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                sliderTouchControlsOpacity.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:sliderTouchControlsOpacity];
                UIView *cellContentView = cell.contentView;
                NSDictionary *viewBindings = NSDictionaryOfVariableBindings(cellContentView,sliderTouchControlsOpacity);
                [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[sliderTouchControlsOpacity]-8@750-|" options:0 metrics:nil views:viewBindings]];
                [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:sliderTouchControlsOpacity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
                [sliderTouchControlsOpacity addConstraint:[NSLayoutConstraint constraintWithItem:sliderTouchControlsOpacity attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100.0]];
                break;
            }
        }
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text   = @"Touch Type";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayTouchType objectAtIndex:op.touchtype];
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text   = @"Ways";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayStickType objectAtIndex:op.sticktype];
                    break;
                }
                    
                case 2:
                {
                    cell.textLabel.text   = @"Fullscreen Stick Size";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayStickSizeValue objectAtIndex:op.stickSize];
                    break;
                }
            }
            break;
        }
        case 2:
        {
            switch (indexPath.row)
            {   case 0:
                {
                    cell.textLabel.text   = @"Fullscreen Buttons";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayNumbuttons objectAtIndex:op.numbuttons];
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text   = @"Button A = B + X";
                    [switchAplusB release];
                    switchAplusB  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchAplusB ;
                    [switchAplusB setOn:[op aplusb] animated:NO];
                    [switchAplusB addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2:
                {
                    
                    cell.textLabel.text   = @"Button A as Autofire";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayAutofireValue objectAtIndex:op.autofire];
                    break;
                }
                case 3:
                {
                    cell.textLabel.text   = @"Buttons Size";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayButtonSizeValue objectAtIndex:op.buttonSize];
                    break;
                }
            }
            break;
        }
        case 3:
        {
            cell.textLabel.text   = @"External Controller";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [arrayControlType objectAtIndex:op.controltype];
            break;
        }
            break;
        case 4:
        {
            switch (indexPath.row)
            {   case 0:
                {
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.text = @"Change Current Layout";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    break;
                }
                case 1:
                {
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.text = @"Reset Current Layout to Default";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    break;
                }
            }
            break;
        }
        case 5:
        {
            cell.textLabel.text   = @"P1 as P2,P3,P4";
            [switchP1aspx release];
            switchP1aspx  = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchP1aspx ;
            [switchP1aspx setOn:[op p1aspx] animated:NO];
            [switchP1aspx addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 6:
        {
            switch (indexPath.row)
            {   case 0:
                {
                    cell.textLabel.text   = @"Touch DPAD";
                    [switchTouchDeadZone release];
                    switchTouchDeadZone  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchTouchDeadZone ;
                    [switchTouchDeadZone setOn:[op touchDeadZone] animated:NO];
                    [switchTouchDeadZone addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text   = @"Touch Stick";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayAnalogDZValue objectAtIndex:op.analogDeadZoneValue];
                    break;
                }
                case 2:
                {
                    if(g_btjoy_available)
                    {
                        cell.textLabel.text   = @"BT Analog";
                        
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.detailTextLabel.text = [arrayBTDZValue objectAtIndex:op.btDeadZoneValue];
                    }
                    break;
                }
            }
            break;
        }
        case 7:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Enabled";
                    [switchLightgunEnabled release];
                    switchLightgunEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchLightgunEnabled setOn:[op lightgunEnabled]];
                    [switchLightgunEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchLightgunEnabled;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Bottom Screen Reload";
                    cell.detailTextLabel.text = @"Some games require shooting offscreen to reload";
                    [switchLightgunBottomScreenReload release];
                    switchLightgunBottomScreenReload = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchLightgunBottomScreenReload setOn:[op lightgunBottomScreenReload]];
                    [switchLightgunBottomScreenReload addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchLightgunBottomScreenReload;
                    break;
                }
            }
            break;
        }
        case 8:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"X";
                    [switchTurboXButtonEnabled release];
                    switchTurboXButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboXButtonEnabled setOn:[op turboXEnabled]];
                    [switchTurboXButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboXButtonEnabled;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Y";
                    [switchTurboYButtonEnabled release];
                    switchTurboYButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboYButtonEnabled setOn:[op turboYEnabled]];
                    [switchTurboYButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboYButtonEnabled;
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = @"A";
                    [switchTurboAButtonEnabled release];
                    switchTurboAButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboAButtonEnabled setOn:[op turboAEnabled]];
                    [switchTurboAButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboAButtonEnabled;
                    break;
                }
                case 3:
                {
                    cell.textLabel.text = @"B";
                    [switchTurboBButtonEnabled release];
                    switchTurboBButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboBButtonEnabled setOn:[op turboBEnabled]];
                    [switchTurboBButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboBButtonEnabled;
                    break;
                }
                case 4:
                {
                    cell.textLabel.text = @"L";
                    [switchTurboLButtonEnabled release];
                    switchTurboLButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboLButtonEnabled setOn:[op turboLEnabled]];
                    [switchTurboLButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboLButtonEnabled;
                    break;
                }
                case 5:
                {
                    cell.textLabel.text = @"R";
                    [switchTurboRButtonEnabled release];
                    switchTurboRButtonEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTurboRButtonEnabled setOn:[op turboREnabled]];
                    [switchTurboRButtonEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTurboRButtonEnabled;
                    break;
                }
            }
            break;
        }
        case 9:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Enabled";
                    [switchTouchAnalogEnabled release];
                    switchTouchAnalogEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTouchAnalogEnabled setOn:[op touchAnalogEnabled]];
                    [switchTouchAnalogEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTouchAnalogEnabled;
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Sensitivity";
                    [sliderTouchAnalogSensitivity release];
                    sliderTouchAnalogSensitivity = [[UISlider alloc] initWithFrame:CGRectZero];
                    [sliderTouchAnalogSensitivity setMinimumValue:100.0];
                    [sliderTouchAnalogSensitivity setMaximumValue:1000.0];
                    [sliderTouchAnalogSensitivity setValue:[op touchAnalogSensitivity]];
                    [sliderTouchAnalogSensitivity addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    sliderTouchAnalogSensitivity.translatesAutoresizingMaskIntoConstraints = NO;
                    [cell.contentView addSubview:sliderTouchAnalogSensitivity];
                    UIView *cellContentView = cell.contentView;
                    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(cellContentView,sliderTouchAnalogSensitivity);
                    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[sliderTouchAnalogSensitivity]-8@750-|" options:0 metrics:nil views:viewBindings]];
                    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:sliderTouchAnalogSensitivity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
                    [sliderTouchAnalogSensitivity addConstraint:[NSLayoutConstraint constraintWithItem:sliderTouchAnalogSensitivity attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100.0]];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = @"Hide Touch D-Pad";
                    [switchTouchAnalogHideTouchDirectionalPad release];
                    switchTouchAnalogHideTouchDirectionalPad = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTouchAnalogHideTouchDirectionalPad setOn:[op touchAnalogHideTouchDirectionalPad]];
                    [switchTouchAnalogHideTouchDirectionalPad addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTouchAnalogHideTouchDirectionalPad;
                    break;
                }
                case 3:
                {
                    cell.textLabel.text = @"Hide Touch Buttons";
                    [switchTouchAnalogHideTouchButtons release];
                    switchTouchAnalogHideTouchButtons = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchTouchAnalogHideTouchButtons setOn:[op touchAnalogHideTouchButtons]];
                    [switchTouchAnalogHideTouchButtons addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = switchTouchAnalogHideTouchButtons;
                    break;
                }
                break;
            }
            break;
        }
        case 10:
        {
            cell.textLabel.text = @"Enabled";
            [switchTouchDirectionalEnabled release];
            switchTouchDirectionalEnabled = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchTouchDirectionalEnabled setOn:[op touchDirectionalEnabled]];
            [switchTouchDirectionalEnabled addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchTouchDirectionalEnabled;
            break;
        }
    }
    
    [op release];
    
    return cell;
}

- (void)optionChanged:(id)sender
{
    Options *op = [[Options alloc] init];
    
	if(sender == switchAnimatedButtons)
        op.animatedButtons=  [switchAnimatedButtons isOn];
	if(sender == switchTouchDeadZone)
        op.touchDeadZone = [switchTouchDeadZone isOn];
    if(sender == switchAplusB)
        op.aplusb = [switchAplusB isOn];
    if(sender == switchP1aspx)
        op.p1aspx = [switchP1aspx isOn];
    if(sender == switchLightgunEnabled)
        op.lightgunEnabled = [switchLightgunEnabled isOn];
    if(sender == switchLightgunBottomScreenReload)
        op.lightgunBottomScreenReload = [switchLightgunBottomScreenReload isOn];
    if(sender == switchTurboXButtonEnabled)
        op.turboXEnabled = [switchTurboXButtonEnabled isOn];
    if(sender == switchTurboYButtonEnabled)
        op.turboYEnabled = [switchTurboYButtonEnabled isOn];
    if(sender == switchTurboAButtonEnabled)
        op.turboAEnabled = [switchTurboAButtonEnabled isOn];
    if(sender == switchTurboBButtonEnabled)
        op.turboBEnabled = [switchTurboBButtonEnabled isOn];
    if(sender == switchTurboLButtonEnabled)
        op.turboLEnabled = [switchTurboLButtonEnabled isOn];
    if(sender == switchTurboRButtonEnabled)
        op.turboREnabled = [switchTurboRButtonEnabled isOn];
    if (sender == switchTouchAnalogEnabled)
        op.touchAnalogEnabled = [switchTouchAnalogEnabled isOn];
    if(sender == sliderTouchAnalogSensitivity)
        op.touchAnalogSensitivity = [sliderTouchAnalogSensitivity value];
    if (sender == switchTouchAnalogHideTouchButtons)
        op.touchAnalogHideTouchButtons = [switchTouchAnalogHideTouchButtons isOn];
    if (sender == switchTouchAnalogHideTouchDirectionalPad)
        op.touchAnalogHideTouchDirectionalPad = [switchTouchAnalogHideTouchDirectionalPad isOn];
    if (sender == switchTouchDirectionalEnabled)
        op.touchDirectionalEnabled = [switchTouchDirectionalEnabled isOn];
    if ( sender == sliderTouchControlsOpacity )
        op.touchControlsOpacity = [sliderTouchControlsOpacity value];

    [op saveOptions];
	[op release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    
    if(section==1 && row==0)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped type:kTypeTouchType list:arrayTouchType];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if(section==1 && row==1)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                    type:kTypeStickType list:arrayStickType];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if(section==1 && row==2)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeStickSizeValue list:arrayStickSizeValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    
    
    if(section==2 && row==0)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeNumButtons list:arrayNumbuttons];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if(section==2 && row==2)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeAutofireValue list:arrayAutofireValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    
    if(section==2 && row==3)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeButtonSizeValue list:arrayButtonSizeValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }

    if(section==3 && row==0)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeControlType list:arrayControlType];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    
    if(section==4 && row==0)
    {
        [emuController beginCustomizeCurrentLayout];
        [tableView reloadData];
    }
    if(section==4 && row==1)
    {
        [emuController resetCurrentLayout];
        [tableView reloadData];
    }

    if(section==6 && row==1)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeAnalogDZValue list:arrayAnalogDZValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if(section==6 && row==2)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeBTDZValue list:arrayBTDZValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }

    
}
    

@end
