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

-(CGRect)getNewRect{
    return CGRectMake( rect.origin.x + ax, rect.origin.y + ay, rect.size.width, rect.size.height);
}

+(NSMutableArray *)createLayoutData: (EmulatorController *)emuController{
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    CGRect *rInputs = [emuController getInputRects];
    
    LayoutData *d = nil;
    
    //RECT Y,A,B,X
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_Y value:BTN_Y_RECT rect: rInputs[BTN_Y_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubype_A value:BTN_A_RECT rect: rInputs[BTN_A_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_B value:BTN_B_RECT rect: rInputs[BTN_B_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_X value:BTN_X_RECT rect: rInputs[BTN_X_RECT] ] autorelease];
    [array addObject: d];
    
    //RECT SELECT,START
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_SELECT value:BTN_SELECT_RECT rect: rInputs[BTN_SELECT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_START value:BTN_START_RECT rect: rInputs[BTN_START_RECT] ] autorelease];
    [array addObject: d];
    
    //RECT L1,L2,R1,R2
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_L1 value:BTN_L1_RECT rect: rInputs[BTN_L1_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_L2 value:BTN_L2_RECT rect: rInputs[BTN_L2_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_R1 value:BTN_R1_RECT rect: rInputs[BTN_R1_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_R2 value:BTN_R2_RECT rect: rInputs[BTN_R2_RECT] ] autorelease];
    [array addObject: d];
    
    //RECT x + y
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_A_Y_RECT rect: rInputs[BTN_A_Y_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_X_A_RECT rect: rInputs[BTN_X_A_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_B_Y_RECT rect: rInputs[BTN_B_Y_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_B_X_RECT rect: rInputs[BTN_B_X_RECT] ] autorelease];
    [array addObject: d];
    
    //RECT DPAD
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_RECT rect: rInputs[DPAD_UP_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_LEFT_RECT rect: rInputs[DPAD_LEFT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_RECT rect: rInputs[DPAD_DOWN_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_RIGHT_RECT rect: rInputs[DPAD_RIGHT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_LEFT_RECT rect: rInputs[DPAD_UP_LEFT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_LEFT_RECT rect: rInputs[DPAD_DOWN_LEFT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_RIGHT_RECT rect: rInputs[DPAD_UP_RIGHT_RECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_RIGHT_RECT rect: rInputs[DPAD_DOWN_RIGHT_RECT] ] autorelease];
    [array addObject: d];
    
    //BTN img
    CGRect *rButtons = [emuController getButtonRects];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_Y value:BTN_Y rect: rButtons[BTN_Y] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubype_A value:BTN_A rect: rButtons[BTN_A] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_B value:BTN_B rect: rButtons[BTN_B] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_X value:BTN_X rect: rButtons[BTN_X] ] autorelease];
    [array addObject: d];
    
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_SELECT value:BTN_SELECT rect: rButtons[BTN_SELECT] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_START value:BTN_START rect: rButtons[BTN_START] ] autorelease];
    [array addObject: d];
    
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_L1 value:BTN_L1 rect: rButtons[BTN_L1] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_L2 value:BTN_L2 rect: rButtons[BTN_L2] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_R1 value:BTN_R1 rect: rButtons[BTN_R1] ] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_R2 value:BTN_R2 rect: rButtons[BTN_R2] ] autorelease];
    [array addObject: d];
    
    //rest
    d = [[[LayoutData alloc] initWithType:kType_DPadImgRect subtype:kSubtype_CONTROLLER value:-1 rect: emuController.rDPadImage] autorelease];
    [array addObject: d];
    d = [[[LayoutData alloc] initWithType:kType_StickRect subtype:kSubtype_CONTROLLER value:-1 rect: emuController.rStickWindow] autorelease];
    [array addObject: d];
    
    
    return array;
}

+(NSString *)getLayoutFilePath{
    NSString *name = nil;
    NSString *path = nil;
    if(g_device_is_landscape)
        if(g_pref_full_screen_land)
           name = [NSString stringWithFormat:@"landscape_full_custom_layout_skin_%d.dat", g_skin_data];
        else
           name = [NSString stringWithFormat:@"landscape_no_full_custom_layout_skin_%d.dat", g_skin_data];  
    else
        if(g_pref_full_screen_port)
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
    [filemgr release];
}

+(void)saveLayoutData:(NSMutableArray *)data {
    
    [NSKeyedArchiver archiveRootObject:data toFile:[LayoutData getLayoutFilePath]];
}


+(void)loadLayoutData:(EmulatorController *)emuController{
    NSMutableArray *data = nil;
    int i = 0;
        
    data = [NSKeyedUnarchiver unarchiveObjectWithFile:[LayoutData getLayoutFilePath]]; //devuelve un autorelease
    
    if(data != nil)
    for(i=0; i<data.count ; i++)
    {
        LayoutData *ld = (LayoutData *)[data objectAtIndex:i];
        
        switch (ld.type) {
            case kType_ButtonRect:
                [emuController getInputRects][ld.value].origin.x = [ld getNewRect].origin.x ;
                [emuController getInputRects][ld.value].origin.y = [ld getNewRect].origin.y ;
                break;
            case kType_ButtonImgRect:
                [emuController getButtonRects][ld.value].origin.x = [ld getNewRect].origin.x;
                [emuController getButtonRects][ld.value].origin.y = [ld getNewRect].origin.y;
                break;
            case kType_DPadRect:
                [emuController getInputRects][ld.value].origin.x = [ld getNewRect].origin.x;
                [emuController getInputRects][ld.value].origin.y = [ld getNewRect].origin.y;
                break;
            case kType_DPadImgRect:
                emuController.rDPadImage = [ld getNewRect];
                break;
            case kType_StickRect:
                emuController.rStickWindow = CGRectMake( [ld getNewRect].origin.x, [ld getNewRect].origin.y, 
                                                        emuController.rStickWindow.size.width, emuController.rStickWindow.size.height) ;
                break;
            default:
                break;
        }
    }
    
}

@end
