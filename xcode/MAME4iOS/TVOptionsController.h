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

enum OptionSections
{
    kFilterSection = 0,
    kInputSection = 1,
    kScreenSection = 2,
    kMiscSection = 3,
    kDefaultsSection = 4,
    kNumSections = 5
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

@interface TVOptionsController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    EmulatorController*  emuController;
    NSArray *arrayEmuRes;
    NSArray *arrayFSValue;
    NSArray *arrayOverscanValue;
    NSArray *arrayEmuSpeed;
}

@property (nonatomic, assign) EmulatorController *emuController;

+(UILabel*)labelForOnOffValue:(int)optionValue;
+(void)setOnOffValueForCell:(UITableViewCell*)cell optionValue:(int)optionValue;

@end

NS_ASSUME_NONNULL_END
