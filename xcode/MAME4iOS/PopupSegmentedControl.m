//
//  PopupSegmentedControl.m
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//
#import "PopupSegmentedControl.h"

@implementation PopupSegmentedControl {
    NSArray* _items;
    NSInteger _selectedSegmentIndex;
    BOOL _momentary;
    UIEdgeInsets _popupMargin;
    CGSize _fullSize;
    UIViewController* _popup;
    id _topItem;
}

#pragma mark - init

- (instancetype)initWithItems:(NSArray *)items {
    _items = items;
    _selectedSegmentIndex = UISegmentedControlNoSegment;
    _popupMargin = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0);
    self = [super initWithItems:items];
    self.apportionsSegmentWidthsByContent = YES;
    _fullSize = [self sizeThatFits:CGSizeZero];
    [super removeAllSegments];
    [super insertSegmentWithTitle:items.firstObject atIndex:0 animated:NO];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [self update];
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
    
    if (_popup != nil && !_momentary)
        super.selectedSegmentIndex = 0;
    else
        super.selectedSegmentIndex = UISegmentedControlNoSegment;
    
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
UIColor* getBackgroundColor(UIView* view) {
    if (view == nil)
        return nil;
    else if (view.backgroundColor != nil)
        return view.backgroundColor;
    else if ([view respondsToSelector:@selector(barTintColor)] && [(id)view barTintColor] != nil)
        return [(id)view barTintColor];
    else
        return getBackgroundColor(view.superview);
}
-(void)showPopup:(UIView*)view {
    
    if (_popup != nil)
        return;
    
    UIViewController* popup = [[UIViewController alloc] init];

    CGSize size = [view sizeThatFits:CGSizeZero];
    size.width += _popupMargin.left + _popupMargin.right;
    size.height += _popupMargin.top + _popupMargin.bottom;
    popup.preferredContentSize = size;
    
    [popup.view addSubview:view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view.centerXAnchor constraintEqualToAnchor:popup.view.safeAreaLayoutGuide.centerXAnchor].active = TRUE;
    [view.centerYAnchor constraintEqualToAnchor:popup.view.safeAreaLayoutGuide.centerYAnchor].active = TRUE;

    popup.view.backgroundColor = getBackgroundColor(self);
    popup.modalPresentationStyle = UIModalPresentationPopover;

    UIPopoverPresentationController* ppc = popup.popoverPresentationController;
    if (ppc != nil) {
        ppc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        ppc.sourceView = self;
        ppc.sourceRect = self.bounds;
        ppc.backgroundColor = popup.view.backgroundColor;
        
        CGRect rect = [self convertRect:self.bounds toCoordinateSpace:self.window];
        CGRect safe = UIEdgeInsetsInsetRect(self.window.bounds, self.window.safeAreaInsets);

        if (CGRectGetMaxY(safe) - CGRectGetMaxY(rect) > size.height + 16)
            ppc.permittedArrowDirections = UIPopoverArrowDirectionUp;
        else if (CGRectGetMinY(rect) - CGRectGetMinY(safe) > size.height + 16)
            ppc.permittedArrowDirections = UIPopoverArrowDirectionDown;
        else
            ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    _popup = popup;
    [self update];

    UIViewController* vc = self.window.rootViewController;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    if (@available(iOS 13.0, *)) {
        if (self.overrideUserInterfaceStyle != UIUserInterfaceStyleUnspecified)
            _popup.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle;
        else
            _popup.overrideUserInterfaceStyle = vc.overrideUserInterfaceStyle;
    }
    [vc presentViewController:_popup animated:YES completion:nil];
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
-(UISegmentedControl*)cloneWithItems:(NSArray*)items {
    
    UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:items];
    seg.apportionsSegmentWidthsByContent = YES;
    
    [seg addTarget:self action:@selector(popupChange:) forControlEvents:UIControlEventValueChanged];
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popupTap:)];
    tap.cancelsTouchesInView = NO;
    [seg addGestureRecognizer:tap];

    [seg setTitleTextAttributes:[self titleTextAttributesForState:UIControlStateNormal] forState:UIControlStateNormal];
    [seg setTitleTextAttributes:[self titleTextAttributesForState:UIControlStateSelected] forState:UIControlStateSelected];
    if (@available(iOS 13.0, *))
        seg.selectedSegmentTintColor = self.selectedSegmentTintColor;

    [seg sizeToFit];
    
    return seg;
}
// create a clone of the segmented controll and present it in a popup
-(void)showMenuHorz {
    UISegmentedControl* seg = [self cloneWithItems:_items];
    if (!_momentary)
        seg.selectedSegmentIndex = _selectedSegmentIndex;
    [self showPopup:seg];
}
// create a vertical stack view with all items in it, and present it in a popup
-(void)showMenuVert {
    UIStackView* stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.distribution = UIStackViewDistributionEqualSpacing;
    stack.spacing = 2.0;
    CGSize size = CGSizeZero;
    for (NSInteger i=0; i<_items.count; i++) {
        UISegmentedControl* seg = [self cloneWithItems:@[_items[i]]];
        seg.tag = i;
        if (_selectedSegmentIndex == i && !_momentary)
            seg.selectedSegmentIndex = 0;
        [stack addArrangedSubview:seg];
        size.height += seg.bounds.size.height + stack.spacing;
        size.width = MAX(size.width, seg.bounds.size.width);
    }

    stack.frame = CGRectMake(0, 0, size.width, size.height);
    [self showPopup:stack];
}
-(void)popupChange:(UISegmentedControl*)sender {
    self.selectedSegmentIndex = sender.tag ?: sender.selectedSegmentIndex;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
-(void)popupTap:(UITapGestureRecognizer*)tap {
    [_popup.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self popoverPresentationControllerDidDismissPopover:self->_popup.popoverPresentationController];
    }];
}
#endif

-(void)tap:(UITapGestureRecognizer*)tap {
#if TARGET_OS_IOS
    if ((self.autoresizingMask & UIViewAutoresizingFlexibleHeight) || _fullSize.width >= (self.window.bounds.size.width * 0.5))
        [self showMenuVert];
    else
        [self showMenuHorz];
#else
    if (super.numberOfSegments <= 1)
        [self grow];
    else
        [self shrink];
#endif
}
@end
