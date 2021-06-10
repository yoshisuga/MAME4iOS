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

#import "ListOptionController.h"
#import "Options.h"

@implementation ListOptionController {
    NSString* key;
    NSArray<NSString*> *list;
    NSInteger value;
}

- (instancetype)initWithKey:(NSString*)keyValue list:(NSArray<NSString*>*)listValue {
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        NSAssert([[[Options alloc] init] valueForKey:keyValue] != nil, @"bad key");
        key = keyValue;
        list = listValue;
    }
    return self;
}
- (instancetype)initWithKey:(NSString*)keyValue list:(NSArray<NSString*>*)listValue title:(NSString *)titleValue {
    self = [self initWithKey:keyValue list:listValue];
    self.title = titleValue;
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    Options *op = [[Options alloc] init];
    
    id val = [op valueForKey:key];
    
    if ([val isKindOfClass:[NSString class]])
        value = [list indexOfOption:val];
    else if ([val isKindOfClass:[NSNumber class]])
        value = [val intValue];
    else
        value = 0;
    
    if (value == NSNotFound || value >= [list count]) {
        NSLog(@"list value out of range, setting to 0");
        value = 0;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (value > 10) {
        NSIndexPath *scrollIndexPath=nil;
        scrollIndexPath = [NSIndexPath indexPathForRow:(value) inSection:0];
        [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    Options *op = [[Options alloc] init];
    int value = (int)self->value;
    
    id val = [op valueForKey:key];

    if ([val isKindOfClass:[NSString class]])
        [op setValue:[list optionAtIndex:value] forKey:key];
    else if ([val isKindOfClass:[NSNumber class]])
        [op setValue:@(value) forKey:key];
    
    //NSLog(@"LIST SELECT: %@ = %@", key, [op valueForKey:key]);
    [op saveOptions];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [list count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CheckMarkCellIdentifier = @"CheckMarkCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CheckMarkCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CheckMarkCellIdentifier];
    }
    
    NSUInteger row = [indexPath row];
    cell.textLabel.text = [list objectAtIndex:row];
    cell.accessoryType = (row == value) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = (uint32_t)[indexPath row];
    if (row != value) {
        value = row;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadData];
}

@end
