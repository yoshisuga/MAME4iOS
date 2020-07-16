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
#import "LayoutData.h"
#import "Alert.h"

@implementation LayoutView

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
    layoutDataArray = [LayoutData createLayoutData:emuController];
    rFinish =  CGRectMake( (self.bounds.size.width / 2) - 125, (self.bounds.size.height / 4) - 20, 250, 40);
}

- (void)drawRect:(CGRect)rect {
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor* color = [UIColor.whiteColor colorWithAlphaComponent:0.2];
    UIFont* font = [UIFont boldSystemFontOfSize:24];

    [color setFill];
    CGContextFillRect(context, rFinish);
    [self drawString:@"Touch Here to Finish" withFont:font inRect:rFinish];
    
    for(int i=0; i<layoutDataArray.count ; i++)
    {
        LayoutData *ld = (LayoutData *)[layoutDataArray objectAtIndex:i];
        if(ld.type == kType_ButtonRect ||
           (ld.type == kType_DPadImgRect && g_pref_input_touch_type == TOUCH_INPUT_DPAD) ||
           (ld.type == kType_StickRect && g_pref_input_touch_type != TOUCH_INPUT_DPAD)
           )
        {
            CGRect rect = [ld getNewRect];
            
            [color setFill];
            CGContextFillRect(context, rect);
            
            if(ld.type == kType_ButtonRect && ld.value == BTN_B_X_RECT)
                [self drawString:@"B+X" withFont:font inRect:rect];
            else if(ld.type == kType_ButtonRect && ld.value == BTN_A_Y_RECT)
                [self drawString:@"A+Y" withFont:font inRect:rect];
            else if(ld.type == kType_ButtonRect && ld.value == BTN_X_A_RECT)
                [self drawString:@"X+A" withFont:font inRect:rect];
            else if(ld.type == kType_ButtonRect && ld.value == BTN_B_Y_RECT)
                [self drawString:@"Y+B" withFont:font inRect:rect];
        }
    }
}

- (void) drawString: (NSString*) s withFont: (UIFont*) font inRect: (CGRect) rect {

    CGSize size = [s sizeWithAttributes:@{NSFontAttributeName:font}];
    CGPoint pt = CGPointMake(rect.origin.x + (rect.size.width - size.width)/2, rect.origin.y + (rect.size.height - size.height)/2);
    [s drawAtPoint:pt withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:UIColor.whiteColor}];
}

- (void)updateRelated:(LayoutData *)moved x:(int)ax y:(int)ay
{
    if(moved.subtype == kSubtype_NONE)
        return;
    
    if(moved.type == kType_DPadImgRect)
    {
        UIView *v = [emuController getDPADView];
        v.frame = [moved getNewRect];
    }
    
    if(moved.type == kType_StickRect)
    {
        UIView *v = [emuController getStickView];
        v.frame = [moved getNewRect];
    }
    
    for(int i=0; i<layoutDataArray.count ; i++)
    {
        LayoutData *ld = (LayoutData *)[layoutDataArray objectAtIndex:i];
        
        if(ld==moved || moved.subtype != ld.subtype) continue;
        
        ld.ax = moved.ax;
        ld.ay = moved.ay;
        
        if (ld.type == kType_ButtonImgRect)
        {
            UIView *v = [emuController getButtonView:ld.value];
            v.frame = [ld getNewRect];
        }
        
    }
}

- (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    static int ax = 0;
    static int ay = 0;
    static int old_ax = 0;
    static int old_ay = 0;
    static int prev_ax = 0;
    static int prev_ay = 0;
    static CGFloat pinch_distance = 0.0;
    static LayoutData *moved = nil;
    static LayoutData *moved_last = nil;
    static NSTimeInterval moved_last_time = 0;

    int i = 0;
    
    NSArray* allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count == 2) {
        CGPoint a = [allTouches.firstObject locationInView:self];
        CGPoint b = [allTouches.lastObject locationInView:self];
        CGPoint c = CGPointMake((a.x+b.x)/2, (a.y+b.y)/2);
        CGFloat d = sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y));
        
        if (pinch_distance == 0.0)
            pinch_distance = d;
        
        CGFloat pinch_scale = d / pinch_distance;
        
        if (MyCGRectContainsPoint(emuController.getStickView.frame, c))
            NSLog(@"STICK SCALE: %f", pinch_scale);
        else
            NSLog(@"BUTTON SCALE: %f", pinch_scale);

        return;
    }
    pinch_distance = 0.0;
    
    UITouch *touch = allTouches.firstObject;
    
    CGPoint pt = [touch locationInView:self];
    
  	if( touch.phase == UITouchPhaseBegan		||
       touch.phase == UITouchPhaseMoved		||
       touch.phase == UITouchPhaseStationary	)
	{
	     if(moved == nil)
         {
             for(i=0; i<layoutDataArray.count ; i++)
             {
                 LayoutData *ld = (LayoutData *)[layoutDataArray objectAtIndex:i];
                 
                 if(ld.type == kType_ButtonRect ||
                    (ld.type == kType_DPadImgRect && g_pref_input_touch_type == TOUCH_INPUT_DPAD) ||
                    (ld.type == kType_StickRect && g_pref_input_touch_type != TOUCH_INPUT_DPAD))
                 {
                     if (MyCGRectContainsPoint([ld getNewRect], pt))
                     {
                         old_ax = ld.ax;
                         old_ay = ld.ay;
                         ax = pt.x;
                         ay = pt.y;
                         prev_ax = 0;
                         prev_ay = 0;
                         moved = ld;
                         break;
                     }
                 }
             }
             
             // check for a dbl tap
             if(moved!=nil && moved==moved_last && [NSDate timeIntervalSinceReferenceDate]-moved_last_time<0.250)
             {
                 NSLog(@"DBL TAP");
             }
             if (moved!=nil)
             {
                 moved_last = moved;
                 moved_last_time = [NSDate timeIntervalSinceReferenceDate];
             }
             
             if(moved==nil && MyCGRectContainsPoint(rFinish, pt))
             {
                 [emuController showAlertWithTitle:nil message:@"Do you want to save changes?" buttons:@[@"Yes",@"No"] handler:^(NSUInteger buttonIndex) {
                     if(buttonIndex == 0 )
                     {
                         [LayoutData saveLayoutData:self->layoutDataArray];
                     }
                     [self->emuController finishCustomizeCurrentLayout];
                 }];
             }
         }
         else
         {
             int new_ax = pt.x - ax;
             int new_ay = pt.y - ay;
             if(new_ax  != 0 || new_ay !=0)
             {
                 prev_ax = new_ax!=0 ? new_ax : prev_ax;
                 prev_ay = new_ay!=0 ? new_ay : prev_ay;
                 moved.ax = prev_ax + old_ax;
                 moved.ay = prev_ay + old_ay;
                 [self updateRelated:moved x:moved.ax y:moved.ay];
                 [self setNeedsDisplay];
             }
         }
    }
    else
    {
        moved = nil;
    }
    
}

@end
