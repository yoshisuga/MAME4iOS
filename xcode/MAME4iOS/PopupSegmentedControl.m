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
    BOOL _dismissPopupAfterChange;
    UIViewController* _popup;
    id _topItem;
}

#pragma mark - init

- (instancetype)initWithItems:(NSArray *)items {
    _items = items;
    _selectedSegmentIndex = UISegmentedControlNoSegment;
    _dismissPopupAfterChange = TRUE;
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
    if (super.numberOfSegments > 1)
        return super.selectedSegmentIndex;
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
    
    if (_popup != nil)
        super.selectedSegmentIndex = 0;
    else if (_selectedSegmentIndex < 0 || _momentary)
        super.selectedSegmentIndex = UISegmentedControlNoSegment;
    else
        super.selectedSegmentIndex = 0;
    
    [self sizeToFit];
}

#if TARGET_OS_TV
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    if (context.previouslyFocusedItem == self)
        [self shrink];
}
-(void)grow {
    if (super.numberOfSegments > 1)
        return;
    [super removeAllSegments];
    for (id item in _items) {
        if ([item isKindOfClass:[UIImage class]])
            [super insertSegmentWithImage:item atIndex:self.numberOfSegments animated:NO];
        else
            [super insertSegmentWithTitle:item atIndex:self.numberOfSegments animated:NO];
    }
    super.selectedSegmentIndex = _selectedSegmentIndex;
    [self sizeToFit];
}
-(void)shrink {
    if (super.numberOfSegments <= 1)
        return;
    _selectedSegmentIndex = super.selectedSegmentIndex;
    [super removeAllSegments];
    [super insertSegmentWithTitle:@"" atIndex:0 animated:NO];
    [self update];
}
#endif

#if TARGET_OS_IOS
// create a clone of the segmented controll and present it in a popup
-(void)showMenu {
    if (_popup != nil)
        return;

    UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:_items];
    seg.apportionsSegmentWidthsByContent = YES;
    [seg addTarget:self action:@selector(popupChange:) forControlEvents:UIControlEventValueChanged];
    
    UIViewController* menu = [[UIViewController alloc] init];
    [seg sizeToFit];
    seg.selectedSegmentIndex = _selectedSegmentIndex;
    menu.preferredContentSize = seg.bounds.size;
    [menu.view addSubview:seg];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    [seg.bottomAnchor constraintEqualToAnchor:menu.view.bottomAnchor].active = TRUE;

    if (@available(iOS 13.0, *)) {
        seg.selectedSegmentTintColor = self.selectedSegmentTintColor;
        // TODO: dont hardcode these colors! figure out how to query the UIBarButtonItem or UINavBar, etc.
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        menu.view.backgroundColor = [UIColor colorWithWhite:0.165 alpha:1.0];
    }

    menu.modalPresentationStyle = UIModalPresentationPopover;
    menu.popoverPresentationController.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
    menu.popoverPresentationController.sourceView = self;
    menu.popoverPresentationController.sourceRect = self.bounds;
    menu.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

    _popup = menu;
    [self update];

    UIViewController* vc = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    [vc presentViewController:menu animated:YES completion:nil];
}
-(void)popupChange:(UISegmentedControl*)sender {
    self.selectedSegmentIndex = sender.selectedSegmentIndex;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    if (_dismissPopupAfterChange) {
        [_popup.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        [self popoverPresentationControllerDidDismissPopover:_popup.popoverPresentationController];
    }
}
// Returning UIModalPresentationNone will indicate that an adaptation should not happen.
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}
// Called on the delegate when the user has taken action to dismiss the popover. This is not called when the popover is dimissed programatically.
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
     _popup = nil;
     [self update];
}
#endif

-(void)tap:(UITapGestureRecognizer*)tap {
#if TARGET_OS_IOS
    [self showMenu];
#else
    if (super.numberOfSegments <= 1)
        [self grow];
    else
        [self shrink];
#endif
}
@end
