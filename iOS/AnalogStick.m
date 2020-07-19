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
 
#import "AnalogStick.h"
#import "Globals.h"

#include "myosd.h"

@implementation AnalogStickView

- (void) updateAnalog
{
    switch(g_pref_analog_DZ_value)
    {
      case 0: deadZone = 0.01f;break;
      case 1: deadZone = 0.05f;break;
      case 2: deadZone = 0.1f;break;
      case 3: deadZone = 0.15f;break;
      case 4: deadZone = 0.2f;break;
      case 5: deadZone = 0.3f;break;
    }

	if(mag >= deadZone)
	{
		float v = ang;
		
		if(STICK2WAY)
		{
            if ( v < 180  ){
				myosd_pad_status |= MYOSD_RIGHT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;						
			}
			else if ( v >= 180  ){
				myosd_pad_status |= MYOSD_LEFT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}
		}
		else if(STICK4WAY)
		{
			if( v >= 315 || v < 45){
				myosd_pad_status |= MYOSD_DOWN;

                myosd_pad_status &= ~MYOSD_UP;					        
		        myosd_pad_status &= ~MYOSD_LEFT;
		        myosd_pad_status &= ~MYOSD_RIGHT;						
			}
			else if ( v >= 45 && v < 135){
				myosd_pad_status |= MYOSD_RIGHT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;						
			}
			else if ( v >= 135 && v < 225){
				myosd_pad_status |= MYOSD_UP;

		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}
			else if ( v >= 225 && v < 315 ){
				myosd_pad_status |= MYOSD_LEFT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}						
		}
        else
        {
			if( v >= 330 || v < 30){
				myosd_pad_status |= MYOSD_DOWN;

                myosd_pad_status &= ~MYOSD_UP;					        
		        myosd_pad_status &= ~MYOSD_LEFT;
		        myosd_pad_status &= ~MYOSD_RIGHT;						
			}
			else if ( v >= 30 && v <60  )  {
				myosd_pad_status |= MYOSD_DOWN;
				myosd_pad_status |= MYOSD_RIGHT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_LEFT;						
			}
			else if ( v >= 60 && v < 120  ){
				myosd_pad_status |= MYOSD_RIGHT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;						
			}
			else if ( v >= 120 && v < 150  ){
				myosd_pad_status |= MYOSD_RIGHT;
				myosd_pad_status |= MYOSD_UP;

		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;
			}
			else if ( v >= 150 && v < 210  ){
				myosd_pad_status |= MYOSD_UP;

		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_LEFT;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}
			else if ( v >= 210 && v < 240  ){
				myosd_pad_status |= MYOSD_UP;
				myosd_pad_status |= MYOSD_LEFT;

		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_RIGHT;						
			}
			else if ( v >= 240 && v < 300  ){
				myosd_pad_status |= MYOSD_LEFT;

                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_DOWN;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}
			else if ( v >= 300 && v < 330  ){
				myosd_pad_status |= MYOSD_LEFT;
				myosd_pad_status |= MYOSD_DOWN;
				
                myosd_pad_status &= ~MYOSD_UP;
		        myosd_pad_status &= ~MYOSD_RIGHT;
			}
		}
        
        if(g_pref_input_touch_type==TOUCH_INPUT_ANALOG)
        {
           joy_analog_x[0][0] = rx;
           if(!STICK2WAY)
              joy_analog_y[0][0] = ry * -1.0f;
           else
              joy_analog_y[0][0] = 0;
           //printf("Sending analog %f, %f...\n",joy_analog_x[0],joy_analog_y[0] );
        }
        else
        {
            // emulate a analog joystick, and a dpad so games that require analog will work with dpad, and viz viz
            joy_analog_y[0][0] = (myosd_pad_status & MYOSD_UP)    ? +1.0 : (myosd_pad_status & MYOSD_DOWN) ? -1.0 : 0.0;
            joy_analog_x[0][0] = (myosd_pad_status & MYOSD_RIGHT) ? +1.0 : (myosd_pad_status & MYOSD_LEFT) ? -1.0 : 0.0;
        }
	}
	else
	{
	    joy_analog_x[0][0]=0.0f;
	    joy_analog_y[0][0]=0.0f;
        //printf("Sending analog %f, %f...\n",joy_analog_x[0],joy_analog_y[0] );
	     
	    myosd_pad_status &= ~MYOSD_UP;
	    myosd_pad_status &= ~MYOSD_DOWN;
	    myosd_pad_status &= ~MYOSD_LEFT;
	    myosd_pad_status &= ~MYOSD_RIGHT;		    	    				    
	}
					
}

// get the image to use for the stick based on the position.
- (UIImage*)getStickImage {
    NSString* base = @"stick-";
    NSString* zero = @"inner.png";

    if (g_pref_input_touch_type == TOUCH_INPUT_DPAD) {
        base = @"DPad_";
        zero = @"NotPressed.png";
    }
    
    NSString* ext = zero;
    switch ((myosd_pad_status | myosd_joy_status[0]) & (MYOSD_UP|MYOSD_DOWN|MYOSD_LEFT|MYOSD_RIGHT))
    {
        case MYOSD_UP:    ext = @"U.png"; break;
        case MYOSD_DOWN:  ext = @"D.png"; break;
        case MYOSD_LEFT:  ext = @"L.png"; break;
        case MYOSD_RIGHT: ext = @"R.png"; break;
            
        case MYOSD_UP | MYOSD_LEFT:  ext = @"UL.png"; break;
        case MYOSD_UP | MYOSD_RIGHT: ext = @"UR.png"; break;
        case MYOSD_DOWN | MYOSD_LEFT:  ext = @"DL.png"; break;
        case MYOSD_DOWN | MYOSD_RIGHT: ext = @"DR.png"; break;
    }
                         
    return [emuController loadImage:[base stringByAppendingString:ext]] ?: [emuController loadImage:[base stringByAppendingString:zero]];
}

- (id)initWithFrame:(CGRect)frame withEmuController:(EmulatorController*)emulatorController{
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
        
        emuController = emulatorController;
        
        innerView = [ [ UIImageView alloc ] initWithImage:[self getStickImage]];
        [self addSubview: innerView];
        
        if (g_device_is_fullscreen)
        {
            outerView = [ [ UIImageView alloc ] initWithImage:[emuController loadImage:@"stick-outer.png"]];
            [self insertSubview:outerView belowSubview:innerView];

            [outerView setAlpha:((float)g_controller_opacity / 100.0f)];
            [innerView setAlpha:((float)g_controller_opacity / 100.0f)];
        }
        
        self.multipleTouchEnabled = YES;
    }
    
    return self;    
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect = self.bounds;
    ptMin = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    ptMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    ptCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    int stick_radio = emuController.stick_radio;
    stickWidth =  rect.size.width * (stick_radio/100.0f);//0.60;
    stickHeight = rect.size.height * (stick_radio/100.0f);//0.60;

    innerView.frame = CGRectMake(ptCenter.x - stickWidth/2, ptCenter.y - stickHeight/2, stickWidth, stickHeight);
    outerView.frame = rect;
}

- (void)calculateStickState:(CGPoint)pt min:(CGPoint)min max:(CGPoint)max center:(CGPoint)center{

    if(pt.x > max.x)pt.x=max.x;
    if(pt.x < min.x)pt.x=min.x;
    if(pt.y > max.y)pt.y=max.y;
    if(pt.y < min.y)pt.y=min.y;

	if (pt.x == center.x)
		rx = 0;
	else if (pt.x >= center.x)
		rx = ((float)(pt.x - center.x) / (float)(max.x - center.x));
	else
		rx = ((float)(pt.x - min.x) / (float)(center.x - min.x)) - 1.0f;

	if (pt.y == center.y)
		ry = 0;
	else if (pt.y >= center.y)
		ry = ((float)(pt.y - center.y) / (float)(max.y - center.y));
	else
		ry = ((float)(pt.y - min.y) / (float)(center.y - min.y)) - 1.0f;

	/* calculate the joystick angle and magnitude */
	ang = RAD_TO_DEGREE(atanf(ry / rx));
	ang -= 90.0f;
	if (rx < 0.0f)
		ang -= 180.0f;
	ang = absf(ang);
	mag = (float) sqrt((rx * rx) + (ry * ry));
}

- (void)analogTouches:(UITouch *)touch withEvent:(UIEvent *)event
{
    static float oldRx;
    static float oldRy;

    CGPoint pt = [touch locationInView:self];
    
  	if( touch.phase == UITouchPhaseBegan		||
       touch.phase == UITouchPhaseMoved		||
       touch.phase == UITouchPhaseStationary	)
	{
	    [self calculateStickState:pt min:ptMin max:ptMax center:ptCenter];
    }
    else
    {
        rx=0;
        ry=0;
        mag=0;
        oldRx = oldRy = -999;
    }
    
    unsigned long pad_status = myosd_pad_status;
    
    [self updateAnalog];
    
    if (g_pref_animated_DPad && pad_status != myosd_pad_status && g_pref_input_touch_type != TOUCH_INPUT_ANALOG)
    {
#ifdef DEBUG
        if (myosd_pad_status & (MYOSD_UP|MYOSD_DOWN|MYOSD_LEFT|MYOSD_RIGHT))
            NSLog(@"****** BUZZ! *******: %s%s%s%s",
                  (myosd_pad_status & MYOSD_UP) ?   "U" : "-", (myosd_pad_status & MYOSD_DOWN) ?  "D" : "-",
                  (myosd_pad_status & MYOSD_LEFT) ? "L" : "-", (myosd_pad_status & MYOSD_RIGHT) ? "R" : "-");
        else
            NSLog(@"****** BONK! *******");
#endif

        if (myosd_pad_status & (MYOSD_UP|MYOSD_DOWN|MYOSD_LEFT|MYOSD_RIGHT))
            [emuController.impactFeedback impactOccurred];
        else
            [emuController.selectionFeedback selectionChanged];
    }
}

// update the position of the stick image from the joy stick state
-(void)update {
    CGFloat x,y;
    
    if (joy_analog_x[0][0] != 0.0 || joy_analog_y[0][0] != 0.0)
    {
        x = joy_analog_x[0][0];
        y = joy_analog_y[0][0];
    }
    else
    {
        unsigned long pad_status = myosd_pad_status | myosd_joy_status[0];
        x = (pad_status & MYOSD_RIGHT) ? +1.0 : (pad_status & MYOSD_LEFT) ? -1.0 : 0.0;
        y = (pad_status & MYOSD_UP)    ? +1.0 : (pad_status & MYOSD_DOWN) ? -1.0 : 0.0;
    }

    // update the stick position, and the dpad/stick image 
    if (g_pref_input_touch_type != TOUCH_INPUT_DPAD)
    {
        //NSLog(@"AnalogStick UPDATE: [%f,%f]", x, y);
        CGRect stickPos;
        stickPos.origin.x = ptCenter.x + x * (ptMax.x - ptCenter.x - stickWidth/2) - (stickWidth/2);
        stickPos.origin.y = ptCenter.y - y * (ptMax.y - ptCenter.y - stickHeight/2) - (stickHeight/2);
        stickPos.size.width = stickWidth;
        stickPos.size.height = stickHeight;
        innerView.frame = stickPos;
    }
    innerView.image = [self getStickImage];
}

@end
