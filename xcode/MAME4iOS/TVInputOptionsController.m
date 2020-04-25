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

@interface TVInputOptionsController ()
@property(nonatomic,retain) Options *options;
@end

@implementation TVInputOptionsController {
    NSArray  *arrayControlType;
}

- (id)init {
    if (self = [super init]) {
        arrayControlType = @[@"Keyboard or 8BitDo",@"iCade or compatible",@"iCP, Gametel",@"iMpulse"];
    }
    return self;
}
    
- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Input Options", @"");
    self.options = [[Options alloc] init];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.options = [[Options alloc] init];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ( indexPath.section == 0 ) {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.textLabel.text   = @"P1 as P2,P3,P4";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.p1aspx];
                break;
            }
            case 1:
            {
                cell.textLabel.text   = @"External Controller";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.detailTextLabel.text = [arrayControlType objectAtIndex:self.options.controltype];
                break;
            }
        }
    } else if ( indexPath.section == 1 ) {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.textLabel.text = @"X";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboXEnabled];
                break;
            }
            case 1:
            {
                cell.textLabel.text = @"Y";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboYEnabled];
                break;
            }
            case 2:
            {
                cell.textLabel.text = @"A";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboAEnabled];
                break;
            }
            case 3:
            {
                cell.textLabel.text = @"B";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboBEnabled];
                break;
            }
            case 4:
            {
                cell.textLabel.text = @"L";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboLEnabled];
                break;
            }
            case 5:
            {
                cell.textLabel.text = @"R";
                cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.turboREnabled];
                break;
            }
        }
    }
    return cell;
}
 
#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ( indexPath.section == 0 ) {
        if ( indexPath.row == 0 ) {
            self.options.p1aspx = self.options.p1aspx ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.p1aspx];
        } else if ( indexPath.row == 1 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                          type:kTypeControlType list:arrayControlType];
            [[self navigationController] pushViewController:listController animated:YES];
        }
    } else if (indexPath.section == 1) {
        if ( indexPath.row == 0 ) {
            self.options.turboXEnabled = self.options.turboXEnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboXEnabled];
        } else if ( indexPath.row == 1 ) {
            self.options.turboYEnabled = self.options.turboYEnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboYEnabled];
        } else if ( indexPath.row == 2 ) {
            self.options.turboAEnabled = self.options.turboAEnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboAEnabled];
        } else if ( indexPath.row == 3 )  {
            self.options.turboBEnabled = self.options.turboBEnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboBEnabled];
        } else if ( indexPath.row == 4 ) {
            self.options.turboLEnabled = self.options.turboLEnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboLEnabled];
        } else if ( indexPath.row == 5 ) {
            self.options.turboREnabled = self.options.turboREnabled ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.turboREnabled];
        }
    }
    [self.options saveOptions];
}
    
@end
