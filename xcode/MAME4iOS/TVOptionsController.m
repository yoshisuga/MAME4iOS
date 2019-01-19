//
//  TVOptionsController.m
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/17/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "TVOptionsController.h"
#import "ListOptionController.h"

@interface TVOptionsController ()

@property(nonatomic,retain) UITableView *tableView;
@property(nonatomic,retain) Options *options;
    
@end

@implementation TVOptionsController

@synthesize emuController;

- (id)init {
    if (self = [super init]) {
        arrayEmuRes = [[NSArray alloc] initWithObjects:@"Auto",@"320x200",@"320x240",@"400x300",@"480x300",@"512x384",@"640x400",@"640x480",@"800x600",@"1024x768", nil];
        arrayFSValue = [[NSArray alloc] initWithObjects:@"Auto",@"None", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10",nil];
        arrayOverscanValue = [[NSArray alloc] initWithObjects:@"None",@"1", @"2", @"3",@"4", @"5", @"6", nil];
        arrayEmuSpeed = [[NSArray alloc] initWithObjects: @"Default",
                         @"50%", @"60%", @"70%", @"80%", @"85%",@"90%",@"95%",@"100%",
                         @"105%", @"110%", @"115%", @"120%", @"130%",@"140%",@"150%",
                         nil];
    }
    return self;
}

- (void)loadView {
    self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.view.backgroundColor = UIColor.darkGrayColor;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target: emuController  action:  @selector(done:) ];
    self.navigationItem.rightBarButtonItem = backButton;
    [backButton release];
    self.title = NSLocalizedString(@"Settings", @"");
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
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
    
-(void)dealloc {
    [self.tableView release];
    [self.options release];
    [super dealloc];
}

+(UILabel*)labelForOnOffValue:(int)optionValue {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 50.0)];
    label.text = optionValue ? @"On" : @"Off";
    label.textColor = UIColor.whiteColor;
    [label sizeToFit];
    return [label autorelease];
}
    
+(void)setOnOffValueForCell:(UITableViewCell*)cell optionValue:(int)optionValue {
    UILabel *valueLabel = (UILabel*) cell.accessoryView;
    valueLabel.text = optionValue ? @"On" : @"Off";
    [valueLabel sizeToFit];
}
    
#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == kFilterSection ) {
        return 1;
    } else if ( section == kScreenSection ) {
        return 4;
    } else if ( section == kMiscSection ) {
        return 8;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section == kScreenSection ) {
        return @"Display Options";
    }
    return @"";
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( cell == nil ) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.backgroundColor = UIColor.grayColor;
    if ( indexPath.section == kFilterSection ) {
        cell.textLabel.text = @"Game Filter";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ( indexPath.section == kScreenSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text  = @"Smoothed Image";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:[self.options smoothedLand]];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text = @"CRT Effect";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:[self.options tvFilterLand]];
        } else if ( indexPath.row == 2 ) {
            cell.textLabel.text = @"Scanline Effect";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:[self.options scanlineFilterLand]];
        } else if ( indexPath.row == 3 ) {
            cell.textLabel.text = @"Keep Aspect Ratio";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.keepAspectRatioLand];
        }
    } else if ( indexPath.section == kMiscSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text   = @"Show FPS";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.showFPS];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text   = @"Emulated Resolution";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if ( indexPath.row == 2 ) {
            cell.textLabel.text   = @"Emulated Speed";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [arrayEmuSpeed objectAtIndex:self.options.emuspeed];
        } else if ( indexPath.row == 3 ) {
            cell.textLabel.text = @"Throttle";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.throttle];
        } else if ( indexPath.row == 4 ) {
            cell.textLabel.text = @"Frame Skip";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [arrayFSValue objectAtIndex:self.options.fsvalue];
        } else if ( indexPath.row == 5 ) {
            cell.textLabel.text   = @"Force Pixel Aspect";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.forcepxa];
        } else if ( indexPath.row == 6 ) {
            cell.textLabel.text   = @"Show Info/Warnings";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.showINFO];
        } else if ( indexPath.row == 7 ) {
            cell.textLabel.text = @"Low Latency Audio";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.lowlsound];
        }
    }
    return cell;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ( indexPath.section == kFilterSection ) {
        // todo: show filter option controller
    } else if ( indexPath.section == kScreenSection ) {
        if ( indexPath.row == 0 ) {
            // Smoothed Image
            self.options.smoothedLand = self.options.smoothedLand ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.smoothedLand];
        } else if ( indexPath.row == 1 ) {
            self.options.tvFilterLand = self.options.tvFilterLand ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.tvFilterLand];
        } else if ( indexPath.row == 2 ) {
            self.options.scanlineFilterLand = self.options.scanlineFilterLand ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.scanlineFilterLand];
        } else if ( indexPath.row == 3 ) {
            self.options.keepAspectRatioLand = self.options.keepAspectRatioLand ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.keepAspectRatioLand];
        }
    } else if ( indexPath.section == kMiscSection ) {
        if ( indexPath.row == 0 ) {
            self.options.showFPS = self.options.showFPS ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.showFPS];
        } else if ( indexPath.row == 1 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped                                                                                          type:kTypeEmuRes list:arrayEmuRes];
            [[self navigationController] pushViewController:listController animated:YES];
            [listController release];
        } else if ( indexPath.row == 2 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped                                                                                          type:kTypeEmuSpeed list:arrayEmuSpeed];
            [[self navigationController] pushViewController:listController animated:YES];
            [listController release];
        } else if ( indexPath.row == 3 ) {
            self.options.throttle = self.options.throttle ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.throttle];
        } else if ( indexPath.row == 4 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped                                                                                          type:kTypeFSValue list:arrayFSValue];
            [[self navigationController] pushViewController:listController animated:YES];
            [listController release];
        } else if ( indexPath.row == 5 ) {
            self.options.forcepxa = self.options.forcepxa ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.forcepxa];
        } else if ( indexPath.row == 6 ) {
            self.options.showINFO = self.options.showINFO ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.showINFO];
        } else if ( indexPath.row == 7 ) {
            self.options.lowlsound = self.options.lowlsound ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.lowlsound];
        }
    }
    [self.options saveOptions];
}

#pragma mark UIEvent handling for button presses
- (void)pressesBegan:(NSSet<UIPress *> *)presses
           withEvent:(UIPressesEvent *)event; {
    BOOL menuPressed = NO;
    for (UIPress *press in presses) {
        if ( press.type == UIPressTypeMenu ) {
            menuPressed = YES;
        }
    }
    NSLog(@"Presses began - was it a menu press? %@",menuPressed ? @"YES" : @"NO");
    if ( menuPressed && self.emuController != nil ) {
        [self.emuController done:nil];
        return;
    }
    // not a menu press, delegate to UIKit responder handling
    [super pressesBegan:presses withEvent:event];
}
    
@end
