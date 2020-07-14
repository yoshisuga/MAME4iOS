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
    rFinish =  CGRectMake( (self.bounds.size.width / 2) - 100, (self.bounds.size.height / 4) - 20, 200, 40);
}

- (void)drawRect:(CGRect)rect {
    
    int i = 0;
    
    //Get the CGContext from this view
	CGContextRef context = UIGraphicsGetCurrentContext();
   	
    //Set the width of the pen mark
	CGContextSetLineWidth(context, 2.0);
    
    [[UIColor.whiteColor colorWithAlphaComponent:0.2] setFill];
    [UIColor.redColor setStroke];
    
    CGContextFillRect(context, rFinish);
    [self drawString:@"Touch Here to Finish" withFont:[UIFont boldSystemFontOfSize:16] inRect:rFinish];
    
    for(i=0; i<layoutDataArray.count ; i++)
    {
        LayoutData *ld = (LayoutData *)[layoutDataArray objectAtIndex:i];
        if(ld.type == kType_ButtonRect ||
           (ld.type == kType_DPadImgRect && g_pref_input_touch_type == TOUCH_INPUT_DPAD) ||
           (ld.type == kType_StickRect && g_pref_input_touch_type != TOUCH_INPUT_DPAD)
           )
        {
            CGContextFillRect(context, [ld getNewRect ]);
            
            if(ld.type == kType_ButtonRect && ld.value == BTN_B_X_RECT)
            {
                [self drawString:@"B+X" withFont:[UIFont boldSystemFontOfSize:16] inRect:[ld getNewRect]];
            }
            else if(ld.type == kType_ButtonRect && ld.value == BTN_A_Y_RECT)
            {
                [self drawString:@"A+Y" withFont:[UIFont boldSystemFontOfSize:16] inRect:[ld getNewRect]];
            }
            else if(ld.type == kType_ButtonRect && ld.value == BTN_X_A_RECT)
            {
                [self drawString:@"X+A" withFont:[UIFont boldSystemFontOfSize:16] inRect:[ld getNewRect]];
            }
            else if(ld.type == kType_ButtonRect && ld.value == BTN_B_Y_RECT)
            {
                [self drawString:@"Y+B" withFont:[UIFont boldSystemFontOfSize:16] inRect:[ld getNewRect]];
            }

                
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void) drawString: (NSString*) s withFont: (UIFont*) font inRect: (CGRect) contextRect {
    
    
    //CGFloat fontHeight = font.pointSize;
    CGFloat fontHeight = [s sizeWithFont:font].height;
    
    CGFloat yOffset = (contextRect.size.height - fontHeight) / 2.0;
    
    CGRect textRect = CGRectMake(contextRect.origin.x, contextRect.origin.y + yOffset, contextRect.size.width, fontHeight);
    
    [s drawInRect: textRect withFont: font lineBreakMode: NSLineBreakByClipping alignment: NSTextAlignmentCenter];
}

#pragma clang diagnostic pop

- (void)updateRelated:(LayoutData *)moved x:(int)ax y:(int)ay
{
    int i = 0;
    
    if(moved.subtype == kSubtype_NONE)
        return;
    
    if(moved.type == kType_DPadImgRect)
    {
        UIView *v = [emuController getDPADView];
        v.frame = [moved getNewRect];
        [v setNeedsDisplay];
    }
    
    if(moved.type == kType_StickRect)
    {
        UIView *v = [emuController getStickView];
        v.frame = [moved getNewRect];
        [v setNeedsDisplay];
    }
    
    for(i=0; i<layoutDataArray.count ; i++)
    {
        LayoutData *ld = (LayoutData *)[layoutDataArray objectAtIndex:i];
        
        if(ld==moved || moved.subtype != ld.subtype) continue;
        
        ld.ax = moved.ax;
        ld.ay = moved.ay;
        
        if (ld.type == kType_ButtonImgRect)
        {
            UIView *v = [emuController getButtonView:ld.value];
            v.frame = [ld getNewRect];
            [v setNeedsDisplay];
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
    static LayoutData *moved = nil;
    
    int i = 0;
    
    
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
    
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
