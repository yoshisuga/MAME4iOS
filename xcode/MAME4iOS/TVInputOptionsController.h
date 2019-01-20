//
//  TVInputOptionsController.h
//  MAME tvOS
//
//  Created by Yoshi Sugawara on 1/20/19.
//  Copyright © 2019 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Options.h"
#import "Globals.h"
#import "EmulatorController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVInputOptionsController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    NSArray  *arrayAutofireValue;
}

@property (nonatomic, assign) EmulatorController *emuController;

@end

NS_ASSUME_NONNULL_END
