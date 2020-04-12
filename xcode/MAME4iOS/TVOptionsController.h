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
    kInputSection = 0,
    kServerSection,
    kScreenSection,
    kMiscSection,
    kDefaultsSection,
    kFilterSection,
    kResetSection,
    kNumSections
};

enum ListOptionType
{
    kTypeNumButtons,
    kTypeEmuRes,
    kTypeStickType,
    kTypeTouchType,
    kTypeControlType,
    kTypeAnalogDZValue,
    kTypeBTDZValue,
    kTypeSoundValue,
    kTypeFSValue,
    kTypeOverscanValue,
    kTypeSkinValue,
    kTypeManufacturerValue,
    kTypeYearGTEValue,
    kTypeYearLTEValue,
    kTypeDriverSourceValue,
    kTypeCategoryValue,
    kTypeVideoPriorityValue,
    kTypeMainPriorityValue,
    kTypeAutofireValue,
    kTypeStickSizeValue,
    kTypeButtonSizeValue,
    kTypeArrayWPANtype,
    kTypeWFframeSync,
    kTypeBTlatency,
    kTypeEmuSpeed,
    kTypeVideoThreadTypeValue,
    kTypeMainThreadTypeValue
};

NS_ASSUME_NONNULL_BEGIN

@interface TVOptionsController : OptionsTableViewController {
    NSArray *arrayEmuRes;
    NSArray *arrayFSValue;
    NSArray *arrayOverscanValue;
    NSArray *arrayEmuSpeed;
}

+(UILabel*)labelForOnOffValue:(int)optionValue;
+(void)setOnOffValueForCell:(UITableViewCell*)cell optionValue:(int)optionValue;

@end

NS_ASSUME_NONNULL_END
