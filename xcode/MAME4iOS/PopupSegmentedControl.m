//
//  PopupSegmentedControl.m
//  TestGame
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//

#import "PopupSegmentedControl.h"

//
// PopupSegmentedControl
//
// a subclass of UISegmentedControl that only shows the currently selected item, and lets the user change
// the currently selected item in a popup window on iPhone or iPad, and in a UIAlertController on tvOS.
//
// if you pass UISegmentedControlNoSegment as the index to setImage/Title:forSegmentAtIndex: you can
// change the item that is displayed instead of the currently selected item.
//
// changing the list of items after init is currently not supported.
//
@implementation PopupSegmentedControl {
    NSArray* _items;
    NSInteger _selectedSegmentIndex;
    BOOL _momentary;
    id _topItem;
}

#pragma mark - init

- (instancetype)initWithItems:(NSArray *)items {
    _items = items;
    _selectedSegmentIndex = UISegmentedControlNoSegment;
    self = [super initWithItems:@[items.firstObject]];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    return self;
}

#pragma mark - UISegmentedControl stuff

-(NSUInteger)numberOfSegments {
    return _items.count;
}

- (void)setMomentary:(BOOL)momentary {
    _momentary = momentary;     // dont pass on
}

-(NSInteger)selectedSegmentIndex {
    return _selectedSegmentIndex;
}

-(void)setSelectedSegmentIndex:(NSInteger)index {
    _selectedSegmentIndex = index;
    [self update];
}

- (void)setTitle:(NSString*)title forSegmentAtIndex:(NSUInteger)index {
    if (index == UISegmentedControlNoSegment) {
        _topItem = title;
        [self update];
    }
    else
        NSParameterAssert(FALSE);   // NOT IMPL
}
- (NSString *)titleForSegmentAtIndex:(NSUInteger)index {
    if (index < 0 || index >= _items.count || ![_items[index] isKindOfClass:[NSString class]])
        return nil;
    return _items[index];
}

- (void)setImage:(UIImage*)image forSegmentAtIndex:(NSUInteger)index {
    if (index == UISegmentedControlNoSegment) {
        _topItem = image;
        [self update];
    }
    else
        NSParameterAssert(FALSE);   // NOT IMPL
}
- (UIImage *)imageForSegmentAtIndex:(NSUInteger)index {
    if (index < 0 || index >= _items.count || ![_items[index] isKindOfClass:[UIImage class]])
        return nil;
    return _items[index];
}

- (void)insertSegmentWithTitle:(NSString*)title atIndex:(NSUInteger)segment animated:(BOOL)animated {
    NSParameterAssert(FALSE);   // NOT IMPL
}
- (void)insertSegmentWithImage:(UIImage *)image  atIndex:(NSUInteger)segment animated:(BOOL)animated {
    NSParameterAssert(FALSE);   // NOT IMPL
}
- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated {
    NSParameterAssert(FALSE);   // NOT IMPL
}
- (void)removeAllSegments {
    _items = @[];
}

#pragma mark - PopupSegmentedControl stuff

// update the UISegmentedControll to show what is currently selected, and nothing else!
-(void)update {
    id item;
    
    if (_topItem != nil)
        item = _topItem;
    else if (_selectedSegmentIndex < 0)
        item = _items.firstObject;
    else if (_selectedSegmentIndex >= _items.count)
        item = _items.lastObject;
    else
        item = _items[_selectedSegmentIndex];

    if ([item isKindOfClass:[UIImage class]])
        [super setImage:item forSegmentAtIndex:0];
    else
        [super setTitle:item forSegmentAtIndex:0];
    
    if (_selectedSegmentIndex < 0 || _momentary)
        super.selectedSegmentIndex = UISegmentedControlNoSegment;
    else
        super.selectedSegmentIndex = 0;
    
    [self sizeToFit];
}

-(void)showAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    for (NSInteger index=0; index < self.numberOfSegments; index++) {
        NSString* title = [self titleForSegmentAtIndex:index] ?: @"";
        UIImage* image = [self imageForSegmentAtIndex:index];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            self.selectedSegmentIndex = index;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }]];
        if (image != nil)
            [alert.actions.lastObject setValue:image forKey:@"image"];
        if (index == self.selectedSegmentIndex)
            alert.preferredAction = alert.actions.lastObject;
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        [self update];
    }]];
    
    UIViewController* vc = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}
-(void)showPopup {
    
}

-(void)tap:(UITapGestureRecognizer*)tap {
    if (_momentary)
        super.selectedSegmentIndex = 0;

    [self showAlert];
}


@end
