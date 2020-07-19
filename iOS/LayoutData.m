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

#import "LayoutData.h"
#import "Globals.h"
#import "EmulatorController.h"

//
// *NOTE* this file is only used to load old layout data, not to create new ones
//
// loadLayoutData should be called to load, and removeLayoutData to delete
// eventualy this file can just be removed.
//
@implementation LayoutData

@synthesize type;
@synthesize subtype;
@synthesize value;
@synthesize ax;
@synthesize ay;
@synthesize rect;

-(id)initWithType:(int)type_ subtype:(int)subtype_ value:(int)value_ rect:(CGRect)rect_
{
    self = [super init];
    if (self) {
        self.type = type_;
        self.subtype = subtype_;
        self.value = value_;
        self.rect = rect_;
        self.ax = 0;
        self.ay = 0;
        
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.type = [decoder decodeIntForKey:@"type"];
        self.subtype = [decoder decodeIntForKey:@"subtype"];
        self.value = [decoder decodeIntForKey:@"value"];
        self.rect = [decoder decodeCGRectForKey:@"rect"];
        self.ax = [decoder decodeIntForKey:@"ax"];
        self.ay = [decoder decodeIntForKey:@"ay"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:type forKey:@"type"];
    [encoder encodeInt:subtype forKey:@"subtype"];
    [encoder encodeInt:value forKey:@"value"];
    [encoder encodeCGRect:rect forKey:@"rect"];
    [encoder encodeInt:ax forKey:@"ax"];
    [encoder encodeInt:ay forKey:@"ay"];
}

+(NSString *)getLayoutFilePath{
    NSString *name = nil;
    NSString *path = nil;
    int g_skin_data = 1;    // always use skin 1
    if(g_device_is_landscape)
        if(g_device_is_fullscreen)
           name = [NSString stringWithFormat:@"landscape_full_custom_layout_skin_%d.dat", g_skin_data];
        else
           name = [NSString stringWithFormat:@"landscape_no_full_custom_layout_skin_%d.dat", g_skin_data];  
    else
        if(g_device_is_fullscreen)
           name = [NSString stringWithFormat:@"portrait_full_custom_layout_skin_%d.dat", g_skin_data];
        else
           name = [NSString stringWithFormat:@"portrait_no_full_custom_layout_skin_%d.dat", g_skin_data];
    
    path=[NSString stringWithUTF8String:get_documents_path((char *)[name UTF8String])];
    return path;
}

+(void)removeLayoutData{
    NSFileManager *filemgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    [filemgr removeItemAtPath:[LayoutData getLayoutFilePath] error:&error];
}

+(void)loadLayoutData:(EmulatorController *)emuController{
    NSArray *data = nil;
    NSError* error = nil;
    int i = 0;
    
    data = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [LayoutData class]]]
                                               fromData:[NSData dataWithContentsOfFile:[LayoutData getLayoutFilePath]]
                                                  error:&error];
        
    if(data != nil) {
        for(i=0; i<data.count ; i++)
        {
            LayoutData *ld = (LayoutData *)[data objectAtIndex:i];
            int btn = -1;
            
            switch (ld.type) {
                case kType_ButtonRect:
                    /* convert from old enum value to button index.
                    BTN_A_Y_RECT=4,
                    BTN_X_A_RECT=5,
                    BTN_B_Y_RECT=6,
                    BTN_B_X_RECT=7,
                    */
                    if (ld.value == 4) btn = BTN_A_X;
                    if (ld.value == 5) btn = BTN_A_Y;
                    if (ld.value == 6) btn = BTN_B_Y;
                    if (ld.value == 7) btn = BTN_B_X;
                    break;
                case kType_ButtonImgRect:
                    // convert from old enum value to button index.
                    // enum { BTN_B=0,BTN_X=1,BTN_A=2,BTN_Y=3,BTN_SELECT=4,BTN_START=5,BTN_L1=6,BTN_R1=7,BTN_EXIT=8,BTN_OPTION=9,NUM_BUTTONS=10};
                    if (ld.value == 2) btn = BTN_A;
                    if (ld.value == 0) btn = BTN_B;
                    if (ld.value == 3) btn = BTN_Y;
                    if (ld.value == 1) btn = BTN_X;
                    if (ld.value == 6) btn = BTN_L1;
                    if (ld.value == 7) btn = BTN_R1;
                    if (ld.value == 4) btn = BTN_SELECT;
                    if (ld.value == 5) btn = BTN_START;
                    if (ld.value == 8) btn = BTN_EXIT;
                    if (ld.value == 9) btn = BTN_OPTION;
                    break;
                case kType_StickRect:
                    btn = BTN_STICK;
                    break;
                default:
                    break;
            }
            
            if (btn != -1) {
                // update the rect relative to the center
                CGRect rect = [emuController getButtonRect:btn];
                CGRect new = CGRectOffset(ld.rect, ld.ax, ld.ay);
                rect.origin.x = CGRectGetMidX(new) - CGRectGetWidth(rect)/2;
                rect.origin.y = CGRectGetMidY(new) - CGRectGetHeight(rect)/2;
                [emuController setButtonRect:btn rect:rect];
            }
        }
    }
}

@end
