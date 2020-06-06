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

#import "FilterOptionController.h"
#import "Options.h"
#if TARGET_OS_IOS
#import "OptionsController.h"
#elif TARGET_OS_TV
#import "TVOptionsController.h"
#endif
#import "ListOptionController.h"
#include "myosd.h"

@implementation FilterOptionController

- (id)init {
    if (self = [super init]) {

        arrayManufacturerValue = [[NSMutableArray  alloc] initWithObjects:@"# All",nil];
        arrayYearGTEValue = [[NSMutableArray  alloc] initWithObjects:@"Any",nil];
        arrayYearLTEValue = [[NSMutableArray  alloc] initWithObjects:@"Any",nil];
        arrayDriverSourceValue = [[NSMutableArray  alloc] initWithObjects:@"# All",nil];
        arrayCategoryValue = [[NSMutableArray  alloc] initWithObjects:@"# All",nil];
        
        int i = 0;
        
        while(myosd_array_years[i][0]!='\0'){
            [arrayYearGTEValue addObject:[NSString stringWithUTF8String: myosd_array_years[i]]];
            [arrayYearLTEValue addObject:[NSString stringWithUTF8String: myosd_array_years[i]]];
            i++;
        }
        i=0;
        while(myosd_array_main_manufacturers[i][0]!='\0'){
            [arrayManufacturerValue addObject:[NSString stringWithUTF8String: myosd_array_main_manufacturers[i]]];
            i++;
        }
        i=0;
        while(myosd_array_main_driver_source[i][0]!='\0'){
            [arrayDriverSourceValue addObject:[NSString stringWithUTF8String: myosd_array_main_driver_source[i]]];
            i++;
        }
        [arrayManufacturerValue replaceObjectAtIndex:[arrayManufacturerValue indexOfObject:@"Other"] withObject: @"# Other / Unknow"];
        [arrayDriverSourceValue replaceObjectAtIndex:[arrayDriverSourceValue indexOfObject:@"Other"] withObject: @"# Other / Unknow"];
        i=0;
        while(myosd_array_categories[i][0]!='\0'){
            [arrayCategoryValue addObject:[NSString stringWithUTF8String: myosd_array_categories[i]]];
            i++;
        }
        
        self.title = @"Filter Options";
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return 3;
        case 1: return 1;
        case 2: return 2;
        case 3: return 3;
        case 4: return 1;
    }
    return -1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat: @"%lu:%lu", (unsigned long)[indexPath indexAtPosition:0], (unsigned long)[indexPath indexAtPosition:1]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        
        UITableViewCellStyle style;
        
        if(indexPath.section==4 && indexPath.row==0)
            style = UITableViewCellStyleDefault;
        else
            style = UITableViewCellStyleValue1;
        
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:@"CellIdentifier"];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryView = nil;
    Options *op = [[Options alloc] init];
    
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Hide Non-Favorites";
                    cell.accessoryView = [self optionSwitchForKey:@"filterFavorites"];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = @"Hide Clones";
                    cell.accessoryView = [self optionSwitchForKey:@"filterClones"];
                    break;
                }
                case 2:
                {
                    cell.textLabel.text = @"Hide Not Working";
                    cell.accessoryView = [self optionSwitchForKey:@"filterNotWorking"];
                    break;
                }
            }
            break;
        }
        case 1:
        {
            cell.textLabel.text   = @"Keyword";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 40, 185, 25)] ;
            textField.placeholder = @"Empty Text";
            textField.text =  op.filterKeyword;
            textField.tag = 1;
            textField.returnKeyType = UIReturnKeyDone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.clearButtonMode = UITextFieldViewModeNever;
            textField.textAlignment = NSTextAlignmentRight;
            textField.keyboardType = UIKeyboardTypeASCIICapable;
            textField.clearsOnBeginEditing = YES;
            textField.delegate = self;
            cell.accessoryView = textField;
            break;
        }
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text   = @"Year >=";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayYearGTEValue objectAtIndex:op.yearGTEValue];
                    break;
                }
                case 1:
                {
                    cell.textLabel.text   = @"Year <=";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayYearLTEValue objectAtIndex:op.yearLTEValue];
                    break;
                }
            }
            break;
        }
        case 3:
        {
            switch (indexPath.row)
            {   case 0:
                {
                    cell.textLabel.text   = @"Manufacturer";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [[arrayManufacturerValue objectAtIndex:op.manufacturerValue] stringByReplacingOccurrencesOfString:@"#" withString:@""];
                    break;
                }
                    
                case 1:
                {
                    
                    cell.textLabel.text   = @"Driver Source";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [[arrayDriverSourceValue objectAtIndex:op.driverSourceValue]
                                                 stringByReplacingOccurrencesOfString:@"#" withString:@""];
                    break;
                }
                case 2:
                {
                    
                    cell.textLabel.text   = @"Category";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [[arrayCategoryValue objectAtIndex:op.categoryValue]
                                                 stringByReplacingOccurrencesOfString:@"#" withString:@""];
                    break;
                }
            }
            break;
        }
        case 4:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = @"Reset Filters to Default";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self toggleOptionSwitch:cell.accessoryView];
    
    if(section==1 && row==0)
    {
        [(UITextField *)cell.accessoryView  becomeFirstResponder];
    }
    
    if (section==2 && row==0){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStylePlain
                                                                                      type:kTypeYearGTEValue list:arrayYearGTEValue];
        
        [[self navigationController] pushViewController:listController animated:YES];
    }
    if (section==2 && row==1){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStylePlain
                                                                                      type:kTypeYearLTEValue list:arrayYearLTEValue];
        
        [[self navigationController] pushViewController:listController animated:YES];
    }
    
    if (section==3 && row==0){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStylePlain
                                                                                      type:kTypeManufacturerValue list:arrayManufacturerValue];
        
        [[self navigationController] pushViewController:listController animated:YES];
    }
    
    if (section==3 && row==1){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStylePlain
                                                                                      type:kTypeDriverSourceValue list:arrayDriverSourceValue];
        
        [[self navigationController] pushViewController:listController animated:YES];
    }
    
    if (section==3 && row==2){
        ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStylePlain
                                                                                      type:kTypeCategoryValue list:arrayCategoryValue];
        
        [[self navigationController] pushViewController:listController animated:YES];
    }
    
    if (section==4 && row==0){
        Options *op = [[Options alloc] init];
        
        op.filterClones=0;
        op.filterFavorites=0;
        op.filterNotWorking=1;
        op.yearLTEValue =0;
        op.yearGTEValue =0;
        op.manufacturerValue =0;
        op.driverSourceValue =0;
        op.categoryValue =0;
        op.filterKeyword = nil;
        
        [op saveOptions];
        [tableView reloadData];
    }

}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell*) [textField superview];
    UITableView *tableView = (UITableView *)self.view;
    [tableView scrollToRowAtIndexPath:[tableView indexPathForCell:cell] atScrollPosition:/*UITableViewScrollPositionMiddle*/UITableViewScrollPositionTop animated:YES];
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    
    if(textField.tag == 1)
    {
        Options *op = [[Options alloc] init];
        if(textField.text == nil ||  textField.text.length==0)
            op.filterKeyword = nil;
        else
            op.filterKeyword = [textField.text substringToIndex:MIN(MAX_FILTER_KEYWORD-1,textField.text.length)];
        [op saveOptions];
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField {
    Options *op = [[Options alloc] init];
    op.filterKeyword = nil;
    [op saveOptions];
    return YES;
}

@end
