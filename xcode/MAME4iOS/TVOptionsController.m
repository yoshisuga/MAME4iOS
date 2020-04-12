//
//  TVOptionsController.m
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/17/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import "TVOptionsController.h"
#import "ListOptionController.h"
#import "FilterOptionController.h"
#import "DefaultOptionController.h"
#import "TVInputOptionsController.h"

@interface TVOptionsController ()
@property(nonatomic,retain) Options *options;
@end

@implementation TVOptionsController

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

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Settings", @"");
    self.options = [[Options alloc] init];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuPress)];
    tap.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.view addGestureRecognizer:tap];
}

-(void)menuPress {
    NSLog(@"MENU PRESS");
    [self.emuController done:nil];
}
    
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}
    
-(void)refresh {
    if ( self.options != nil ) {
        self.options = nil;
    }
    self.options = [[Options alloc] init];
    [self.tableView reloadData];
}

+(UILabel*)labelForOnOffValue:(int)optionValue {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 50.0)];
    label.text = optionValue ? @"On" : @"Off";
    [label sizeToFit];
    return label;
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
        return 2;
    } else if ( section == kScreenSection ) {
        return 4;
    } else if ( section == kMiscSection ) {
        return 8;
    } else if ( section == kDefaultsSection ) {
        return 1;
    } else if ( section == kInputSection ) {
        return 1;
    } else if ( section == kServerSection ) {
        return 1;
    } else if ( section == kResetSection ) {
        return 1;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section == kScreenSection ) {
        return @"Display Options";
    }
    if ( section == kFilterSection ) {
        return @"ROM Options";
    }
    if ( section == kResetSection ) {
        return @"Reset";
    }

    return @"";
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.textLabel.textColor = nil;
    cell.detailTextLabel.text = nil;
    cell.contentView.backgroundColor = nil;

    if ( indexPath.section == kFilterSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text   = @"Hide Clones";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.filterClones];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text   = @"Hide Not Working";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.filterNotWorking];
        }
    } else if ( indexPath.section == kServerSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text = @"Start Server";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
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
            cell.textLabel.text   = @"Fill Screen";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.forcepxa];
        } else if ( indexPath.row == 6 ) {
            cell.textLabel.text   = @"Show Info/Warnings";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.showINFO];
        } else if ( indexPath.row == 7 ) {
            cell.textLabel.text = @"Low Latency Audio";
            cell.accessoryView = [TVOptionsController labelForOnOffValue:self.options.lowlsound];
        }
    } else if ( indexPath.section == kDefaultsSection ) {
        cell.textLabel.text = @"Defaults";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ( indexPath.section == kInputSection ) {
        cell.textLabel.text = @"Game Input";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ( indexPath.section == kResetSection ) {
        cell.textLabel.text = @"Reset to Defaults";
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.contentView.backgroundColor = [UIColor systemRedColor];
    }
    return cell;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ( indexPath.section == kFilterSection ) {
        if ( indexPath.row == 0 ) {
            self.options.filterClones = self.options.filterClones ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.filterClones];
        } else if ( indexPath.row == 1 ) {
            self.options.filterNotWorking = self.options.filterNotWorking ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.filterNotWorking];
        }
    } else if ( indexPath.section == kServerSection ) {
        if ( indexPath.row == 0 ) {
            [self.emuController runServer];
        }
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
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped type:kTypeEmuRes list:arrayEmuRes];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 2 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped type:kTypeEmuSpeed list:arrayEmuSpeed];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 3 ) {
            self.options.throttle = self.options.throttle ? 0 : 1;
            [TVOptionsController setOnOffValueForCell:cell optionValue:self.options.throttle];
        } else if ( indexPath.row == 4 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithStyle:UITableViewStyleGrouped type:kTypeFSValue list:arrayFSValue];
            [[self navigationController] pushViewController:listController animated:YES];
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
    } else if ( indexPath.section == kDefaultsSection ) {
        DefaultOptionController *defaultOptController = [[DefaultOptionController alloc] initWithEmuController:self.emuController];
        [[self navigationController] pushViewController:defaultOptController animated:YES];
    } else if ( indexPath.section == kInputSection ) {
        TVInputOptionsController *inputController = [[TVInputOptionsController alloc] initWithEmuController:self.emuController];
        [self.navigationController pushViewController:inputController animated:YES];
    } else if ( indexPath.section == kResetSection ) {
        [self.emuController runReset];
    }
    [self.options saveOptions];
}

@end
