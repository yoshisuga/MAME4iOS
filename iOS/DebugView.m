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
#import "DebugView.h"

@implementation DebugView


- (id)initWithFrame:(CGRect)frame withEmuController:(EmulatorController*)emulatorController{
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.multipleTouchEnabled = NO;
	    self.userInteractionEnabled = NO;
	
	    emuController = emulatorController;
    }
    return self;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)drawRect:(CGRect)rect {
	//printf("draw dview\n");
	
    
   // printf("Drawing Rect");
    
    //Get the CGContext from this view
	CGContextRef context = UIGraphicsGetCurrentContext();
	 
   	//Set the stroke (pen) color
	CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
	//Set the width of the pen mark
	CGContextSetLineWidth(context, 2.0);
	
    int i=0;
    int ndrects = [emuController num_debug_rects];
    CGRect *drects = [emuController getDebugRects];
    
	for(i=0; i<ndrects;i++)
	  CGContextStrokeRect(context, drects[i]);
    
	
	//CGContextAddRect(context, drects[1]);
	//Draw it
	CGContextFillPath(context);
	       
    CGContextSelectFont(context, "Helvetica", 16, kCGEncodingMacRoman); 
    CGContextSetTextDrawingMode (context, kCGTextFillStroke);
    CGContextSetRGBFillColor (context, 0, 5, 0, .5);
    CGRect viewBounds = self.bounds;
    CGContextTranslateCTM(context, 0, viewBounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextSetRGBStrokeColor (context, 0, 1, 1, 1);
 
   if(!g_isIpad)
   {
 //     CGContextShowTextAtPoint(context, 10, 10, "Es un iPhone",12 );
   }
   else
   {
      //CGContextShowTextAtPoint(context, 10, 10, "Es un iPad",10 );
   }
		
}

#pragma clang diagnostic pop




@end
