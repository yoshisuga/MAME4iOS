/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */

#import "LayoutView.h"
#import "Alert.h"

// scale a CGRect but dont move the center
static CGRect CGRectScale(CGRect rect, CGFloat scale) {
    return CGRectInset(rect, -0.5 * rect.size.width * (scale - 1.0), -0.5 * rect.size.height * (scale - 1.0));
}

@implementation LayoutView {
    EmulatorController      *emuController;
    CGRect                  rLayout[NUM_BUTTONS];
    CGRect                  rFinish;
    BOOL                    isDirty;
    CGFloat                 buttonSize;
    CGFloat                 stickSize;
    CGFloat                 commandSize;
}


- (id)initWithFrame:(CGRect)frame withEmuController:(EmulatorController*)emulatorController{
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.multipleTouchEnabled = NO;
	    self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
        
	    emuController = emulatorController;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    rFinish =  CGRectMake( (self.bounds.size.width / 2) - 125, 150, 250, 40);
    for (int i=0; i<NUM_BUTTONS; i++)
        rLayout[i] = [emuController getButtonRect:i];
    [self getButtonDefaultSize];
}

// find out the button sizes, used to hide/show a button.
- (void)getButtonDefaultSize {
    CGFloat maxSize;
    
    maxSize = 0;
    for (int i = BTN_A; i < BTN_SELECT; i++)
        maxSize = MAX(maxSize, rLayout[i].size.width);
    if (maxSize != 0)
        buttonSize = maxSize;
    else if (buttonSize == 0)
        buttonSize = floor(MIN(self.bounds.size.width, self.bounds.size.height) / 4.0);
    
    maxSize = 0.0;
    for (int i = BTN_SELECT; i < BTN_STICK; i++)
        maxSize = MAX(maxSize, rLayout[i].size.width);
    if (maxSize != 0)
        commandSize = maxSize;
    else if (commandSize == 0)
        commandSize = buttonSize;
    
    if (rLayout[BTN_STICK].size.width != 0)
        stickSize = rLayout[BTN_STICK].size.width;
    else if (stickSize == 0)
        stickSize = buttonSize * 2.0;
}


- (CGRect)getDisplayRect:(int)i {
    CGRect rect = rLayout[i];

    if (CGRectIsEmpty(rect)) {
        if (rect.origin.x == 0 && rect.origin.y == 0)
            rect.origin = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        if (i < BTN_SELECT)
            rect = CGRectInset(rect, -buttonSize/2, -buttonSize/2);
        else if (i <= BTN_OPTION)
            rect = CGRectInset(rect, -commandSize/2, -commandSize/2);
        else if (i == BTN_STICK)
            rect = CGRectInset(rect, -stickSize/2, -stickSize/2);
    }
    
    return rect;
}

- (void)drawRect:(CGRect)rect {
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor* color = [UIColor.whiteColor colorWithAlphaComponent:0.2];
    UIFont* font = [UIFont boldSystemFontOfSize:24];

    [color setFill];
    CGContextFillRect(context, rFinish);
    [self drawString:isDirty ? @"Touch Here to Finish" :  @"Touch Here to Exit"
            withFont:font withColor:UIColor.whiteColor inRect:rFinish];
    CGRect rHelp = CGRectOffset(rFinish, 0, -75);
    rHelp.size.height = 3*20;
    [self drawString:@"Drag button to move\nDouble tap to hide/show\nPinch to scale."
            withFont:[UIFont systemFontOfSize:20] withColor:UIColor.lightGrayColor inRect:rHelp];
    
    for(int i=0; i<NUM_BUTTONS; i++)
    {
        CGRect rect = [self getDisplayRect:i];

        if (CGRectIsEmpty(rLayout[i]))
            [[UIColor.redColor colorWithAlphaComponent:0.2] setFill];
        else
            [color setFill];

        CGContextFillRect(context, rect);
        
        NSString* name = [emuController getButtonName:i];
        if (name != nil)
            [self drawString:name withFont:font withColor:[color colorWithAlphaComponent:0.5] inRect:rect];
    }
}

- (void) drawString:(NSString*)s withFont:(UIFont*)font withColor:(UIColor*)color inRect:(CGRect)rect {

    CGSize size = [s sizeWithAttributes:@{NSFontAttributeName:font}];
    CGPoint pt = CGPointMake(rect.origin.x + (rect.size.width - size.width)/2, rect.origin.y + (rect.size.height - size.height)/2);
    [s drawAtPoint:pt withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:color}];
}

- (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    static CGPoint grab_point;
    static CGFloat pinch_distance = 0.0;
    static int moved = -1;
    static int moved_last = -1;
    static NSTimeInterval moved_last_time = 0;

    NSArray* allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count == 2) {
        CGPoint a = [allTouches.firstObject locationInView:self];
        CGPoint b = [allTouches.lastObject locationInView:self];
        CGPoint c = CGPointMake((a.x+b.x)/2, (a.y+b.y)/2);
        CGFloat d = sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y));
        
        if (pinch_distance == 0.0)
            pinch_distance = d;
        
        CGFloat pinch_scale = d / pinch_distance;
        
        if ((floor(pinch_scale * 1000.0) / 1000.0) != 1.0) {
            CGRect rButtons = CGRectNull;
            for (int i=BTN_A; i<=BTN_R1; i++) {
                if (!CGRectIsEmpty(rLayout[i]))
                    rButtons = CGRectUnion(rButtons, rLayout[i]);
            }

            if (MyCGRectContainsPoint(rLayout[BTN_STICK], c)) {
                rLayout[BTN_STICK] = CGRectScale(rLayout[BTN_STICK], pinch_scale);
                [emuController setButtonRect:BTN_STICK rect:rLayout[BTN_STICK]];
            }
            else if (MyCGRectContainsPoint(rButtons, c)) {
                for (int i=BTN_A; i<BTN_SELECT; i++) {
                    rLayout[i] = CGRectScale(rLayout[i], pinch_scale);
                    [emuController setButtonRect:i rect:rLayout[i]];
                }
            }
            else {
                for (int i=BTN_SELECT; i<BTN_STICK; i++) {
                    rLayout[i] = CGRectScale(rLayout[i], pinch_scale);
                    [emuController setButtonRect:i rect:rLayout[i]];
                }
            }
            pinch_distance = d;
            [self getButtonDefaultSize];
            [self setNeedsDisplay];
            isDirty = TRUE;
        }
        moved = -1;
        return;
    }
    pinch_distance = 0.0;
    
    UITouch *touch = allTouches.firstObject;
    
    CGPoint pt = [touch locationInView:self];
    
  	if( touch.phase == UITouchPhaseBegan		||
       touch.phase == UITouchPhaseMoved		||
       touch.phase == UITouchPhaseStationary	)
	{
	     if(moved == -1)
         {
             for(int i=0; i<NUM_BUTTONS; i++)
             {
                 CGRect rect = [self getDisplayRect:i];
                 if (MyCGRectContainsPoint(rect, pt))
                 {
                     grab_point.x = pt.x - CGRectGetMidX(rect);
                     grab_point.y = pt.y - CGRectGetMidY(rect);
                     moved = i;
                     break;
                 }
             }
             
             // check for a dbl tap
             if(moved != -1 && moved == moved_last && (NSDate.timeIntervalSinceReferenceDate - moved_last_time) < 0.250)
             {
                 NSLog(@"DBL TAP: %@", [emuController getButtonName:moved]);
                 
                 if (CGRectIsEmpty(rLayout[moved]))
                     rLayout[moved] = [self getDisplayRect:moved];
                 else
                     rLayout[moved] = CGRectScale(rLayout[moved], 0.0);
                 
                 [emuController setButtonRect:moved rect:rLayout[moved]];
                 [self setNeedsDisplay];
                 isDirty = TRUE;
             }
             if (moved != -1)
             {
                 moved_last = moved;
                 moved_last_time = NSDate.timeIntervalSinceReferenceDate;
             }
             
             if(moved == -1 && MyCGRectContainsPoint(rFinish, pt))
             {
                 if (isDirty) {
                     [emuController showAlertWithTitle:nil message:@"Do you want to save changes?" buttons:@[@"Yes",@"No"] handler:^(NSUInteger buttonIndex) {
                         if(buttonIndex == 0 )
                         {
                             [self->emuController saveCurrentLayout];
                         }
                         [self->emuController finishCustomizeCurrentLayout];
                     }];
                 }
                 else {
                     [self->emuController finishCustomizeCurrentLayout];
                 }
             }
         }
         else
         {
             rLayout[moved].origin.x = floor(pt.x - grab_point.x - rLayout[moved].size.width/2);
             rLayout[moved].origin.y = floor(pt.y - grab_point.y - rLayout[moved].size.height/2);
             [emuController setButtonRect:moved rect:rLayout[moved]];
             [self setNeedsDisplay];
             isDirty = TRUE;
         }
    }
    else
    {
        moved = -1;
    }
    
}

@end
