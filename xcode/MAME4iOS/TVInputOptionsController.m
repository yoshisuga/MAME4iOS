//
//  TVInputOptionsController.m
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/20/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "TVInputOptionsController.h"
#import "TVOptionsController.h"
#import "ListOptionController.h"

@implementation TVInputOptionsController

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Input Options", @"");
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
    
#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == 0 ) {
        // general
        return 2;
    } else if ( section == 1 ) {
        // turbo
        return 6;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) {
        // general
        return @"General";
    } else if ( section == 1 ) {
        // turbo
        return @"Turbo Mode Toggle";
    }
    return @"";
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    Options* op = [[Options alloc] init];
    
    if ( indexPath.section == 0 ) {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.textLabel.text   = @"P1 as P2,P3,P4";
                cell.accessoryView = [self optionSwitchForKey:@"p1aspx"];
                break;
            }
            case 1:
            {
                cell.textLabel.text   = @"External Controller";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.detailTextLabel.text = [Options.arrayControlType optionAtIndex:op.controltype];
                break;
            }
        }
    } else if ( indexPath.section == 1 ) {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.textLabel.text = @"X";
                cell.accessoryView = [self optionSwitchForKey:@"turboXEnabled"];
                break;
            }
            case 1:
            {
                cell.textLabel.text = @"Y";
                cell.accessoryView = [self optionSwitchForKey:@"turboYEnabled"];
                break;
            }
            case 2:
            {
                cell.textLabel.text = @"A";
                cell.accessoryView = [self optionSwitchForKey:@"turboAEnabled"];
                break;
            }
            case 3:
            {
                cell.textLabel.text = @"B";
                cell.accessoryView = [self optionSwitchForKey:@"turboBEnabled"];
                break;
            }
            case 4:
            {
                cell.textLabel.text = @"L";
                cell.accessoryView = [self optionSwitchForKey:@"turboLEnabled"];
                break;
            }
            case 5:
            {
                cell.textLabel.text = @"R";
                cell.accessoryView = [self optionSwitchForKey:@"turboREnabled"];
                break;
            }
        }
    }
    return cell;
}
 
#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self toggleOptionSwitch:cell.accessoryView];
    
    if ( indexPath.section == 0 ) {
        if ( indexPath.row == 1 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithType:kTypeControlType list:Options.arrayControlType];
            [[self navigationController] pushViewController:listController animated:YES];
        }
    } else if (indexPath.section == 1) {

    }
}
    
@end
