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
#import "ScreenView.h"
#import "Globals.h"

//static
unsigned short img_buffer [1024 * 768 * 4];//max driver res?


@interface ScreenLayer : CALayer
@end

@implementation ScreenLayer {
    CGContextRef bitmapContext;
}

+ (id) defaultActionForKey:(NSString *)key
{
    return nil;
}

- (id)init {
    //printf("Crean layer %ld\n",self);
	if (self = [super init])
	{
        bitmapContext = nil;
        
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapContext = CGBitmapContextCreate(
                                              img_buffer,
                                              myosd_video_width,//512,//320,
                                              myosd_video_height,//480,//240,
                                              /*8*/5, // bitsPerComponent
                                              2*myosd_video_width,//2*512,///*4*320*/2*320, // bytesPerRow
                                              colorSpace,
                                              kCGImageAlphaNoneSkipFirst  | kCGBitmapByteOrder16Little/*kCGImageAlphaNoneSkipLast */);
        
        CFRelease(colorSpace);
        
		if((g_pref_smooth_land && g_device_is_landscape) || (g_pref_smooth_port && !g_device_is_landscape))
		{
            [self setMagnificationFilter:kCAFilterLinear];
            [self setMinificationFilter:kCAFilterLinear];
		}
		else
		{
            [self setMagnificationFilter:kCAFilterNearest];
            [self setMinificationFilter:kCAFilterNearest];
  	    }
        
	}
	return self;
}

- (void)display {
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    
    self.contents = (__bridge id)cgImage;
    
    CFRelease(cgImage);
}

- (void)dealloc {
        
    if(bitmapContext!=nil)
    {
        CFRelease(bitmapContext);
        bitmapContext=nil;
    }
}
@end

@implementation ScreenView

+ (Class) layerClass
{
    return [ScreenLayer class];
}


- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])!=nil) {
        
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
#if TARGET_OS_IOS
        self.multipleTouchEnabled = NO;
#endif
        self.userInteractionEnabled = NO;
	}
    
	return self;
}

- (void)drawRect:(CGRect)rect
{
    //printf("Draw rect\n");
    // UIView uses the existence of -drawRect: to determine if should allow its CALayer
    // to be invalidated, which would then lead to the layer creating a backing store and
    // -drawLayer:inContext: being called.
    // By implementing an empty -drawRect: method, we allow UIKit to continue to implement
    // this logic, while doing our real drawing work inside of -drawLayer:inContext:
    
}

@end
