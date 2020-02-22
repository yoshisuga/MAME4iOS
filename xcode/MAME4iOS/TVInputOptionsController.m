//
//  TVInputOptionsController.m
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/20/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "TVInputOptionsController.h"
#import "TVOptionsController.h"

@interface TVInputOptionsController ()
@property(nonatomic,retain) UITableView *tableView;
@property(nonatomic,retain) Options *options;
@end

@implementation TVInputOptionsController

- (id)init {
    if (self = [super init]) {
        arrayAutofireValue = [[NSArray alloc] initWithObjects:@"Disabled", @"Speed 1", @"Speed 2",@"Speed 3",
                              @"Speed 4", @"Speed 5",@"Speed 6",@"Speed 7",@"Speed 8",@"Speed 9",nil];
    }
    return self;
}
    
- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = UIColor.darkGrayColor;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target: self.emuController  action:  @selector(done:) ];
    self.navigationItem.rightBarButtonItem = backButton;
    self.title = NSLocalizedString(@"Input Options", @"");
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor] setActive:YES];
    [[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] setActive:YES];
    [[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    self.options = [[Options alloc] init];
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
    
#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == 0 ) {
        // general
        return 1;
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
        cell.textLabel.text   = @"P1 as P2,P3,P4";
        cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.p1aspx];
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
        self.options.p1aspx = self.options.p1aspx ? 0 : 1;
        [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.p1aspx];
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
