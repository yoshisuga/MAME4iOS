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

#import "DefaultOptionController.h"
#import "Globals.h"
#import "OptionsController.h"
#import "ListOptionController.h"
#import "EmulatorController.h"

#include "myosd.h"

@implementation DefaultOptionController

@synthesize emuController;

- (id)init {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        
        switchTvoutNative = nil;
        switchCheats = nil;
        arraySoundValue = [[NSArray alloc] initWithObjects:@"Off", @"On (11 KHz)", @"On (22 KHz)",@"On (33 KHz)", @"On (44 KHz)", @"On (48 KHz)", nil];
        arrayMainPriorityValue = [[NSArray alloc] initWithObjects:@"0", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10",nil];
        arrayVideoPriorityValue = [[NSArray alloc] initWithObjects:@"0", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10",nil];
        switchVsync = nil;
        switchThreaded = nil;
        switchDblbuff = nil;
        switchHiscore = nil;
        
        switchVAntialias = nil;
        switchVBean2x = nil;
        switchVFlicker = nil;
        
        arrayMainThreadTypeValue = [[NSArray alloc] initWithObjects:@"Normal", @"Real Time RR", @"Real Time FIFO",nil];
        arrayVideoThreadTypeValue = [[NSArray alloc] initWithObjects:@"Normal", @"Real Time RR", @"Real Time FIFO",nil];
        
        self.title = @"Default Options";
    }
    return self;
}

- (void)dealloc {
    
    [switchTvoutNative release];
    [switchCheats release];
    [arraySoundValue release];
    [switchVsync release];
    [switchThreaded release];
    [switchDblbuff release];
    
    [arrayMainPriorityValue release];
    [arrayVideoPriorityValue release];
    
    [switchHiscore release];
    
    [switchVBean2x release];
    [switchVAntialias release];
    [switchVFlicker release];
    
    [arrayVideoThreadTypeValue release];
    [arrayMainThreadTypeValue release];
    
    [super dealloc];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UITableView *tableView = (UITableView *)self.view;
    [tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 3;
}

- (void)loadView {
    
    [super loadView];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                               style:UIBarButtonItemStyleBordered
                                                              target: emuController  action:  @selector(done:) ];
    self.navigationItem.rightBarButtonItem = button;
    [button release];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return 3;
        case 1: return 4;
        case 2: return 7;
    }
    return -1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section)
    {
        case 0: return @"Vector Defaults";
        case 1: return @"Game Defaults";
        case 2: return @"App Defaults";
    }
    return @"Error!";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat: @"%d:%d", [indexPath indexAtPosition:0], [indexPath indexAtPosition:1]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        
        UITableViewCellStyle style;
        
        style = UITableViewCellStyleValue1;
        
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
            switch (indexPath.row)
            {   case 0:
                {
                    cell.textLabel.text  = @"Beam 2x";
                    [switchVBean2x release];
                    switchVBean2x = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchVBean2x;
                    [switchVBean2x setOn:[op vbean2x] animated:NO];
                    [switchVBean2x addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text   = @"Antialias";
                    [switchVAntialias release];
                    switchVAntialias  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchVAntialias ;
                    [switchVAntialias setOn:[op vantialias] animated:NO];
                    [switchVAntialias addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text   = @"Flicker";
                    [switchVFlicker release];
                    switchVFlicker  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchVFlicker ;
                    [switchVFlicker setOn:[op vflicker] animated:NO];
                    [switchVFlicker addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        }
        case 1:
        {
            switch (indexPath.row)
            {   case 0:
                {
                    cell.textLabel.text   = @"Sound";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arraySoundValue objectAtIndex:op.soundValue];
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text   = @"Cheats";
                    [switchCheats release];
                    switchCheats  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchCheats ;
                    [switchCheats setOn:[op cheats] animated:NO];
                    [switchCheats addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text   = @"Force 60Hz Sync";
                    [switchVsync release];
                    switchVsync  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchVsync ;
                    [switchVsync setOn:[op vsync] animated:NO];
                    [switchVsync addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 3:
                {
                    cell.textLabel.text   = @"Save Hiscores";
                    [switchHiscore release];
                    switchHiscore  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchHiscore ;
                    [switchHiscore setOn:[op hiscore] animated:NO];
                    [switchHiscore addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
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
                    cell.textLabel.text   = @"Native TV-OUT";
                    [switchTvoutNative release];
                    switchTvoutNative  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchTvoutNative ;
                    [switchTvoutNative setOn:[op tvoutNative] animated:NO];
                    [switchTvoutNative addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text   = @"Threaded Video";
                    [switchThreaded release];
                    switchThreaded  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchThreaded ;
                    [switchThreaded setOn:[op threaded] animated:NO];
                    [switchThreaded addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text   = @"Video Thread Priority";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayVideoPriorityValue objectAtIndex:op.videoPriority];
                    break;
                }
                case 3:
                {
                    cell.textLabel.text   = @"Video Thread Type";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayVideoThreadTypeValue objectAtIndex:op.videoThreadType];
                    break;
                }
                case 4:
                {
                    cell.textLabel.text   = @"Double Buffer";
                    [switchDblbuff release];
                    switchDblbuff  = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchDblbuff ;
                    [switchDblbuff setOn:[op dblbuff] animated:NO];
                    [switchDblbuff addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 5:
                {
                    cell.textLabel.text   = @"Main Thread Priority";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayMainPriorityValue objectAtIndex:op.mainPriority];
                    break;
                }
                case 6:
                {
                    cell.textLabel.text   = @"Main Thread Type";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayMainThreadTypeValue objectAtIndex:op.mainThreadType];
                    break;
                }
            }
            break;
        }
    }
    
    [op release];
    
    return cell;
}

- (void)optionChanged:(id)sender
{
    Options *op = [[Options alloc] init];
    
	if(sender == switchTvoutNative)
        op.tvoutNative = [switchTvoutNative isOn];
    
    if(sender == switchCheats)
        op.cheats = [switchCheats isOn];
    
    if(sender == switchVsync)
        op.vsync = [switchVsync isOn];
    
    if(sender == switchThreaded)
        op.threaded = [switchThreaded isOn];
    
    if(sender == switchDblbuff)
        op.dblbuff = [switchDblbuff isOn];
    
    if(sender == switchHiscore)
        op.hiscore = [switchHiscore isOn];
    
    if(sender == switchVBean2x)
        op.vbean2x = [switchVBean2x isOn];
    
    if(sender == switchVAntialias)
        op.vantialias = [switchVAntialias isOn];
    
    if(sender == switchVFlicker)
        op.vflicker = [switchVFlicker isOn];
    
    [op saveOptions];
	[op release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    
    if(section==1 && row==0)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeSoundValue list:arraySoundValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if (section==2 && row==2){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeVideoPriorityValue list:arrayVideoPriorityValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if (section==2 && row==3){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeVideoThreadTypeValue list:arrayVideoThreadTypeValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if (section==2 && row==5){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeMainPriorityValue list:arrayMainPriorityValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }
    if (section==2 && row==6){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                      type:kTypeMainThreadTypeValue list:arrayMainThreadTypeValue];
        [[self navigationController] pushViewController:listController animated:YES];
        [listController release];
    }

}


@end
