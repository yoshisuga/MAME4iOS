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
#import "SystemImage.h"

@implementation TVOptionsController

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Settings", @"");
    
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
    [self.tableView reloadData];
}
    
#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == kFilterSection ) {
        return 2;
    } else if ( section == kScreenSection ) {
        return 9;
    } else if ( section == kMiscSection ) {
        return 7;
    } else if ( section == kDefaultsSection ) {
        return 1;
    } else if ( section == kInputSection ) {
        return 1;
    } else if ( section == kImportSection ) {
        return TRUE ? 4 : 1;
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
    if ( section == kImportSection ) {
        return @"Import / Export";
    }

    return @"";
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.textLabel.textColor = nil;
    cell.detailTextLabel.text = nil;
    cell.contentView.backgroundColor = nil;
    
    Options* op = [[Options alloc] init];
    
    CGFloat size = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize;

    if ( indexPath.section == kFilterSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text   = @"Hide Clones";
            cell.accessoryView = [self optionSwitchForKey:@"filterClones"];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text   = @"Hide Not Working";
            cell.accessoryView = [self optionSwitchForKey:@"filterNotWorking"];
        }
    } else if ( indexPath.section == kImportSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text = @"Start Server";
            cell.imageView.image = [UIImage systemImageNamed:@"arrow.up.arrow.down.circle" withPointSize:size];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if ( indexPath.row == 1 ) {
            cell.textLabel.text = @"Import from iCloud";
            cell.imageView.image = [UIImage systemImageNamed:@"icloud.and.arrow.down" withPointSize:size];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if ( indexPath.row == 2 ) {
            cell.textLabel.text = @"Export to iCloud";
            cell.imageView.image = [UIImage systemImageNamed:@"icloud.and.arrow.up" withPointSize:size];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if ( indexPath.row == 3 ) {
            cell.textLabel.text = @"Sync with iCloud";
            cell.imageView.image = [UIImage systemImageNamed:@"arrow.clockwise.icloud" withPointSize:size];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if ( indexPath.section == kScreenSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text = @"Filter";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayFilter optionName:op.filter];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text   = @"Skin";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arraySkin optionName:op.skin];
        } else if ( indexPath.row == 2 ) {
            cell.textLabel.text   = @"Screen Shader";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayScreenShader optionName:op.screenShader];
        } else if ( indexPath.row == 3 ) {
            cell.textLabel.text   = @"Vector Shader";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayLineShader optionName:op.lineShader];
        } else if ( indexPath.row == 4 ) {
            cell.textLabel.text   = @"ColorSpace";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayColorSpace optionName:op.colorSpace];
        } else if ( indexPath.row == 5 ) {
            cell.textLabel.text =  @"Use Metal";
            cell.accessoryView = [self optionSwitchForKey:@"useMetal"];
        } else if ( indexPath.row == 6 ) {
            cell.textLabel.text = @"Keep Aspect Ratio";
            cell.accessoryView = [self optionSwitchForKey:@"keepAspectRatio"];
        } else if ( indexPath.row == 7 ) {
            cell.textLabel.text = @"Integer Scaling Only";
            cell.accessoryView = [self optionSwitchForKey:@"integerScalingOnly"];
        } else if ( indexPath.row == 8 ) {
            cell.textLabel.text   = @"Force Pixel Aspect";
            cell.accessoryView = [self optionSwitchForKey:@"forcepxa"];
        }
    } else if ( indexPath.section == kMiscSection ) {
        if ( indexPath.row == 0 ) {
            cell.textLabel.text   = @"Show FPS";
            cell.accessoryView = [self optionSwitchForKey:@"showFPS"];
        } else if ( indexPath.row == 1 ) {
            cell.textLabel.text   = @"Show Info/Warnings";
            cell.accessoryView = [self optionSwitchForKey:@"showINFO"];
        } else if ( indexPath.row == 2 ) {
            cell.textLabel.text   = @"Emulated Resolution";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayEmuRes optionAtIndex:op.emures];
        } else if ( indexPath.row == 3 ) {
            cell.textLabel.text   = @"Emulated Speed";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayEmuSpeed optionAtIndex:op.emuspeed];
        } else if ( indexPath.row == 4 ) {
            cell.textLabel.text = @"Throttle";
            cell.accessoryView = [self optionSwitchForKey:@"throttle"];
        } else if ( indexPath.row == 5 ) {
            cell.textLabel.text = @"Frame Skip";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [Options.arrayFSValue optionAtIndex:op.fsvalue];
        } else if ( indexPath.row == 6 ) {
            cell.textLabel.text = @"Low Latency Audio";
            cell.accessoryView = [self optionSwitchForKey:@"lowlsound"];
        }
    } else if ( indexPath.section == kDefaultsSection ) {
        cell.textLabel.text = @"Defaults";
        cell.imageView.image = [UIImage systemImageNamed:@"slider.horizontal.3" withPointSize:size];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ( indexPath.section == kInputSection ) {
        cell.textLabel.text = @"Game Input";
        cell.imageView.image = [UIImage systemImageNamed:@"gamecontroller" withPointSize:size];
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
    
    [self toggleOptionSwitch:cell.accessoryView];
    
    if ( indexPath.section == kFilterSection ) {

    } else if ( indexPath.section == kImportSection ) {
        if ( indexPath.row == 0 ) {
            [self.emuController runServer];
        }
        if ( indexPath.row == 1 ) {
            [self.emuController runServer];
        }
        if ( indexPath.row == 2 ) {
            [self.emuController runServer];
        }
        if ( indexPath.row == 3 ) {
            [self.emuController runServer];
        }
    } else if ( indexPath.section == kScreenSection ) {
        if ( indexPath.row == 0 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"filter" list:Options.arrayFilter title:cell.textLabel.text];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 1 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"skin" list:Options.arraySkin title:cell.textLabel.text];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 2 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"screenShader" list:Options.arrayScreenShader title:cell.textLabel.text];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 3 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"lineShader" list:Options.arrayLineShader title:cell.textLabel.text];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 4 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"colorSpace" list:Options.arrayColorSpace title:cell.textLabel.text];
            [[self navigationController] pushViewController:listController animated:YES];
        }
    } else if ( indexPath.section == kMiscSection ) {
        if ( indexPath.row == 2 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithType:kTypeEmuRes list:Options.arrayEmuRes];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 3 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithType:kTypeEmuSpeed list:Options.arrayEmuSpeed];
            [[self navigationController] pushViewController:listController animated:YES];
        } else if ( indexPath.row == 5 ) {
            ListOptionController *listController = [[ListOptionController alloc] initWithType:kTypeFSValue list:Options.arrayFSValue];
            [[self navigationController] pushViewController:listController animated:YES];
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
}

@end
