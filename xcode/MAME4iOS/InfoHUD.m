//
//  InfoHUD.m
//  Wombat
//
//  Created by Todd Laney on 6/4/20.
//  Copyright © 2020 Wombat. All rights reserved.
//

#import "InfoHUD.h"

@implementation InfoHUD {
    UIStackView* _stack;
    NSMutableDictionary* _views;
    NSMutableDictionary* _format;
    NSMutableDictionary* _step;
    CGFloat _width;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    self.insetsLayoutMarginsFromSafeArea = NO;
    
    _views = [[NSMutableDictionary alloc] init];
    _format = [[NSMutableDictionary alloc] init];
    _step = [[NSMutableDictionary alloc] init];

    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 4.0;
    _stack.distribution = UIStackViewDistributionEqualSpacing;
    _stack.alignment = UIStackViewAlignmentFill;
    
    self.font = nil;
    
    [self addSubview:_stack];
    self.backgroundColor = [UIColor.grayColor colorWithAlphaComponent:0.75];
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];

    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        [self addBlur:UIBlurEffectStyleSystemUltraThinMaterialDark withVibrancy:NO];
    }
    else {
        [self addBlur:UIBlurEffectStyleDark withVibrancy:NO];
    }

    return self;
}

- (void)setSpacing:(CGFloat)spacing {
    _stack.spacing = spacing;
}
- (CGFloat)spacing {
    return _stack.spacing;
}
- (void)setFont:(UIFont *)font {
    _font = font ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)addBlur:(UIBlurEffectStyle)style withVibrancy:(BOOL)vibrancy {
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.frame = self.bounds;

    // add vibrancy
    if (vibrancy) {
        UIVibrancyEffect* vibrancy;
        if (@available(iOS 13.0, *))
            vibrancy = [UIVibrancyEffect effectForBlurEffect:blur style:UIVibrancyEffectStyleLabel];
        else
            vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];

        UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        effectView.frame = self.bounds;
        [effectView.contentView addSubview:self.subviews.firstObject];
        [self addSubview:effectView];
    }

    [effectView.contentView addSubview:self.subviews.firstObject];
    [self addSubview:effectView];
    self.backgroundColor = UIColor.clearColor;
    effectView.backgroundColor = [self.tintColor colorWithAlphaComponent:0.2];
}

- (void)pan:(UIPanGestureRecognizer*)pan {
    CGPoint translation = [pan translationInView:self];
    [pan setTranslation:CGPointZero inView:self];
    
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
}
- (void)slide:(UISlider*)slider {
    NSString* key = (__bridge NSString*)(void*)slider.tag;
    [self setValue:@(slider.value) forKey:key];
    _changedKey = key;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins {
    [super setLayoutMargins:layoutMargins];
    self.layer.cornerRadius = MIN(self.layoutMargins.top, self.layoutMargins.left);
    self.layer.masksToBounds = self.layer.cornerRadius != 0.0;
}

- (NSArray<NSString*>*)allKeys {
    return [_views allKeys];
}

- (void)removeAll {
    [_views removeAllObjects];
    for (UIView* view in _stack.subviews)
        [view removeFromSuperview];
    _width = 0.0;
    [self sizeToFit];
}

- (UIImage*)dotWithColor:(UIColor*)color size:(CGSize)size
{
    return [[[UIGraphicsImageRenderer alloc] initWithSize:size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
        [color setFill];
        CGContextFillEllipseInRect(context.CGContext, CGRectMake(0, 0, size.width, size.height));
    }];
}

- (UIView*)separatorViewWithHeight:(CGFloat)height color:(UIColor*)color {
    UIView* view = [[UIView alloc] init];
    view.backgroundColor = color;
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height]];
    return view;
}

- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format min:(id)min max:(id)max step:(id)step {

    key = key ?: @"";
    
    if (format.length == 0) {
        if ([step floatValue] >= 1)
            format = @"%0.0f";
        else if ([step floatValue] >= 0.1)
            format = @"%0.1f";
        else if ([step floatValue] >= 0.01)
            format = @"%0.2f";
        else
            format = @"%0.3f";
    }
    if ([format componentsSeparatedByString:@"%"].count == 2)
        format = [@"%2$@: " stringByAppendingString:format];

    if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"---"]) {
        value = [self separatorViewWithHeight:1.0 color:UIColor.grayColor];
    }

    if ([value isKindOfClass:[UIView class]]) {
        _views[key] = value;
        [_stack addArrangedSubview:value];
        return;
    }

    UILabel* label = [[UILabel alloc] init];
    label.font = _font;
    label.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.75];
    _views[key] = label;
    _format[key] = format;
    _step[key] = step;
    [_stack addArrangedSubview:label];

    if ([value isKindOfClass:[NSString class]] && [value hasPrefix:@"**"] && [value hasSuffix:@"**"]) {
        value = [value substringWithRange:NSMakeRange(2, [value length]-4)];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        //label.textAlignment = NSTextAlignmentCenter;
    }
    
    if ([value isKindOfClass:[NSString class]])
        _width = MAX(_width, ceil([value sizeWithAttributes:@{NSFontAttributeName:label.font}].width));

    if ([value isKindOfClass:[NSNumber class]] && min != nil && max != nil) {
        UISlider* slider = [[UISlider alloc] init];
        [slider setThumbImage:[self dotWithColor:UIColor.whiteColor size:CGSizeMake(8,8)] forState:UIControlStateNormal];
        [slider addConstraint:[NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:24.0]];
        [slider addTarget:self action:@selector(slide:) forControlEvents:UIControlEventValueChanged];
        slider.minimumValue = [min floatValue];
        slider.maximumValue = [max floatValue];
        slider.tag = (NSUInteger)(__bridge void*)key;
        label.tag = (NSUInteger)(__bridge void*)slider;
         [_stack addArrangedSubview:slider];
        
        for (NSNumber* num in @[min,max,value])
            _width = MAX(_width, ceil([[NSString stringWithFormat:format, [num floatValue], key] sizeWithAttributes:@{NSFontAttributeName:label.font}].width));
        
        if ([key hasSuffix:@"_r"] || [key hasSuffix:@"_red"]   || [key hasSuffix:@"-r"] || [key hasSuffix:@"-red"])
            slider.tintColor = UIColor.systemRedColor;
        if ([key hasSuffix:@"_g"] || [key hasSuffix:@"_green"] || [key hasSuffix:@"-g"] || [key hasSuffix:@"-green"])
            slider.tintColor = UIColor.systemGreenColor;
        if ([key hasSuffix:@"_b"] || [key hasSuffix:@"_blue"]  || [key hasSuffix:@"-b"] || [key hasSuffix:@"-blue"])
            slider.tintColor = UIColor.systemBlueColor;
        if ([key hasSuffix:@"_a"] || [key hasSuffix:@"_alpha"]  || [key hasSuffix:@"-a"] || [key hasSuffix:@"-alpha"])
            slider.minimumTrackTintColor = UIColor.darkGrayColor;
    }
    
    [self setValue:value forKey:key];
    [self sizeToFit];
}
- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format min:(id)min max:(id)max {
    [self addValue:value forKey:key format:format min:min max:max step:nil];
}
- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format {
    [self addValue:value forKey:key format:format min:nil max:nil];
}
- (void)addValue:(id)value forKey:(NSString *)key {
    [self addValue:value forKey:key format:nil min:nil max:nil];
}
- (void)addValue:(id)value {
    [self addValue:value forKey:nil format:nil min:nil max:nil];
}
- (void)addValues:(NSDictionary*)values {
    for (NSString* key in [values allKeys])
        [self addValue:values[key] forKey:key];
}
- (void)addText:(NSString*)str {
    [self addValue:str];
}
- (void)addView:(UIView*)view {
    [self addValue:view];
}
- (void)addSeparator {
    [self addValue:@"---"];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    UILabel* label = _views[key];
    
    if (![label isKindOfClass:[UILabel class]])
        return;

    if ([value isKindOfClass:[NSNumber class]]) {
        float val = [value floatValue];
        NSString* format = _format[key];
        float step = [_step[key] floatValue];
        if (step != 0.0)
            val = round(val / step) * step;
        label.text = [NSString stringWithFormat:format, val, key];
        UISlider* slider = (__bridge UISlider*)(void*)label.tag;
        if ([slider isKindOfClass:[UISlider class]] && !slider.isTracking)
            slider.value = val;
    }
    else if ([value isKindOfClass:[NSString class]]) {
        label.text = value;
    }
    else {
        label.text = [value description];
    }
}
- (void)setValues:(NSDictionary*)values {
    for (NSString* key in [values allKeys])
        [self setValue:values[key] forKey:key];
}
- (id)valueForKey:(NSString *)key {
    if ([key length] == 0)
        return nil;
    UILabel* label = _views[key];
    if (![label isKindOfClass:[UILabel class]])
        return label;
    UISlider* slider = (__bridge UISlider*)(void*)label.tag;
    float step = [_step[key] floatValue];
    if (([slider isKindOfClass:[UISlider class]]))
        return @((step != 0.0) ? round(slider.value / step) * step : slider.value);
    else if ([label.text containsString:@": "])
        return @([label.text componentsSeparatedByString:@": "].lastObject.floatValue);
    else
        return label.text;
}
- (NSDictionary*)getValues {
    NSMutableDictionary* values = [[NSMutableDictionary alloc] init];
    for (NSString* key in self.allKeys)
        values[key] = [self valueForKey:key];
    return values;
}

- (CGSize)sizeThatFits:(CGSize)size {
    size = [_stack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    size.width = MAX(_width, size.width);
    if (size.width != 0 && size.height != 0) {
        size.width = ceil(size.width) + self.layoutMargins.left + self.layoutMargins.right;
        size.height = ceil(size.height) + self.layoutMargins.top + self.layoutMargins.bottom;
    }
    return size;
}

- (void)layoutSubviews {
    _stack.frame = UIEdgeInsetsInsetRect(self.bounds, self.layoutMargins);
}


@end
