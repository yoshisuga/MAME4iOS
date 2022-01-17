//
//  TVOptionsController.h
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/17/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Options.h"
#import "Globals.h"
#import "EmulatorController.h"
#import "OptionsTableViewController.h"

enum OptionSections
{
    kImportSection,
    kInputSection,
    kScreenSection,
    kVectorSection,
    kMiscSection,
    kFilterSection,
    kBenchmarkSection,
    kResetSection,
    kNumSections
};

@interface TVOptionsController : OptionsTableViewController

@end
