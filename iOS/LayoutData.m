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

-(CGRect)getNewRect{
    return CGRectMake( rect.origin.x + ax, rect.origin.y + ay, rect.size.width, rect.size.height);
}

+(NSMutableArray *)createLayoutData: (EmulatorController *)emuController{
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    CGRect *rInputs = [emuController getInputRects];
    
    LayoutData *d = nil;
    
    //RECT Y,A,B,X
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_Y value:BTN_Y_RECT rect: rInputs[BTN_Y_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_A value:BTN_A_RECT rect: rInputs[BTN_A_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_B value:BTN_B_RECT rect: rInputs[BTN_B_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_X value:BTN_X_RECT rect: rInputs[BTN_X_RECT] ];
    [array addObject: d];
    
    //RECT SELECT,START
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_SELECT value:BTN_SELECT_RECT rect: rInputs[BTN_SELECT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_START value:BTN_START_RECT rect: rInputs[BTN_START_RECT] ];
    [array addObject: d];
    
    //RECT L1,L2,R1,R2
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_L1 value:BTN_L1_RECT rect: rInputs[BTN_L1_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_L2 value:BTN_L2_RECT rect: rInputs[BTN_L2_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_R1 value:BTN_R1_RECT rect: rInputs[BTN_R1_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_R2 value:BTN_R2_RECT rect: rInputs[BTN_R2_RECT] ];
    [array addObject: d];
    
    //RECT x + y
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_A_Y_RECT rect: rInputs[BTN_A_Y_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_X_A_RECT rect: rInputs[BTN_X_A_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_B_Y_RECT rect: rInputs[BTN_B_Y_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonRect subtype:kSubtype_NONE value:BTN_B_X_RECT rect: rInputs[BTN_B_X_RECT] ];
    [array addObject: d];
    
    //RECT DPAD
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_RECT rect: rInputs[DPAD_UP_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_LEFT_RECT rect: rInputs[DPAD_LEFT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_RECT rect: rInputs[DPAD_DOWN_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_RIGHT_RECT rect: rInputs[DPAD_RIGHT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_LEFT_RECT rect: rInputs[DPAD_UP_LEFT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_LEFT_RECT rect: rInputs[DPAD_DOWN_LEFT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_UP_RIGHT_RECT rect: rInputs[DPAD_UP_RIGHT_RECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_DPadRect subtype:kSubtype_CONTROLLER value:DPAD_DOWN_RIGHT_RECT rect: rInputs[DPAD_DOWN_RIGHT_RECT] ];
    [array addObject: d];
    
    //BTN img
    CGRect *rButtons = [emuController getButtonRects];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_Y value:BTN_Y rect: rButtons[BTN_Y] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_A value:BTN_A rect: rButtons[BTN_A] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_B value:BTN_B rect: rButtons[BTN_B] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_X value:BTN_X rect: rButtons[BTN_X] ];
    [array addObject: d];
    
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_SELECT value:BTN_SELECT rect: rButtons[BTN_SELECT] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_START value:BTN_START rect: rButtons[BTN_START] ];
    [array addObject: d];
    
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_L1 value:BTN_L1 rect: rButtons[BTN_L1] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_L2 value:BTN_L2 rect: rButtons[BTN_L2] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_R1 value:BTN_R1 rect: rButtons[BTN_R1] ];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_ButtonImgRect subtype:kSubtype_R2 value:BTN_R2 rect: rButtons[BTN_R2] ];
    [array addObject: d];
    
    //rest
    d = [[LayoutData alloc] initWithType:kType_DPadImgRect subtype:kSubtype_CONTROLLER value:-1 rect: emuController.rStickWindow];
    [array addObject: d];
    d = [[LayoutData alloc] initWithType:kType_StickRect subtype:kSubtype_CONTROLLER value:-1 rect: emuController.rStickWindow];
    [array addObject: d];
    
    
    return array;
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

+(void)saveLayoutData:(NSMutableArray *)layoutData {
//    [NSKeyedArchiver archiveRootObject:layoutData toFile:[LayoutData getLayoutFilePath]];
    NSError* error = nil;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:layoutData requiringSecureCoding:YES error:&error];
    [data writeToFile:[LayoutData getLayoutFilePath] atomically:NO];
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
                    break;
                case kType_StickRect:
                    emuController.rStickWindow = CGRectMake( [ld getNewRect].origin.x, [ld getNewRect].origin.y,
                                                            emuController.rStickWindow.size.width, emuController.rStickWindow.size.height) ;
                    break;
                default:
                    break;
            }
        }
        NSLog(@"---------- Printing layout for %@",[LayoutData getLayoutFilePath]);
        [self printAsTextFileFormat:data emuController:emuController];
        NSLog(@"---------- End Printing layout");
    }
}

+(void)printAsTextFileFormat:(NSArray*)data emuController:(EmulatorController*)emuController {
    NSMutableArray *layoutTextData = [[NSMutableArray alloc] init];
    NSArray<NSArray*> *fileDataLayoutElements = @[
                                     @[ @(kType_DPadRect), @(DPAD_DOWN_LEFT_RECT), @"//DownLeft"],    // 1
                                     @[ @(kType_DPadRect), @(DPAD_DOWN_RECT), @"//Down"],         // 2
                                     @[ @(kType_DPadRect), @(DPAD_DOWN_RIGHT_RECT), @"//DownRight "],   // 3
                                     @[ @(kType_DPadRect), @(DPAD_LEFT_RECT), @"//Left"],         // 4
                                     @[ @(kType_DPadRect), @(DPAD_RIGHT_RECT), @"//Right"],        // 5
                                     @[ @(kType_DPadRect), @(DPAD_UP_LEFT_RECT), @"//UpLeft"],      // 6
                                     @[ @(kType_DPadRect), @(DPAD_UP_RECT), @"//Up"],           // 7
                                     @[ @(kType_DPadRect), @(DPAD_UP_RIGHT_RECT), @"//UpRight"],     // 8
                                     @[ @(kType_ButtonRect), @(BTN_SELECT_RECT), @"//Select*"],        // 9
                                     @[ @(kType_ButtonRect), @(BTN_START_RECT), @"//Start*"],         // 10
                                     @[ @(kType_ButtonRect), @(BTN_L1_RECT), @"//LPad"],            // 11
                                     @[ @(kType_ButtonRect), @(BTN_R1_RECT), @"//Rpad"],            // 12
                                     @[ @(kType_ButtonRect), @(BTN_MENU_RECT), @"//menu"],          // 13
                                     @[ @(kType_ButtonRect), @(BTN_X_A_RECT), @"//ButtonDownLeft (X + A)"],           // 14
                                     @[ @(kType_ButtonRect), @(BTN_X_RECT), @"//ButtonDown X*"],             // 15
                                     @[ @(kType_ButtonRect), @(BTN_B_X_RECT), @"//ButtonDownRight (X + B)"],           // 16
                                     @[ @(kType_ButtonRect), @(BTN_A_RECT), @"//ButtonLeft A*"],             // 17
                                     @[ @(kType_ButtonRect), @(BTN_B_RECT), @"//ButtonRight B*"],             // 18
                                     @[ @(kType_ButtonRect), @(BTN_A_Y_RECT), @"//ButtonUpLeft (A + Y)"],           // 19
                                     @[ @(kType_ButtonRect), @(BTN_Y_RECT), @"//ButtonUp Y*"],             // 20
                                     @[ @(kType_ButtonRect), @(BTN_B_Y_RECT), @"//ButtonUpRight (B + Y)"],           // 21
                                     @[ @(kType_ButtonRect), @(BTN_L2_RECT), @"//L2*"],            // 22
                                     @[ @(kType_ButtonRect), @(BTN_R2_RECT), @"//R2*"],            // 23
                                     @[ @(-1), @(-1), @"//showkyboard"],                          // 24 not used (showkyboard)
                                     @[ @(kType_ButtonImgRect), @(BTN_B), @"//B img"],             // 25
                                     @[ @(kType_ButtonImgRect), @(BTN_X), @"//X img"],             // 26
                                     @[ @(kType_ButtonImgRect), @(BTN_A), @"//A img"],             // 27
                                     @[ @(kType_ButtonImgRect), @(BTN_Y), @"//Y img"],             // 28
                                     @[ @(kType_DPadImgRect), @(-1), @"//DPad img"],                  // 29
                                     @[ @(kType_ButtonImgRect), @(BTN_SELECT), @"//select img*"],        // 30
                                     @[ @(kType_ButtonImgRect), @(BTN_START), @"//start img*"],         // 31
                                     @[ @(kType_ButtonImgRect), @(BTN_L1), @"//L1 img"],            // 32
                                     @[ @(kType_ButtonImgRect), @(BTN_R1), @"//R1 img"],            // 33
                                     @[ @(kType_ButtonImgRect), @(BTN_L2), @"//L2 img"],            // 34
                                     @[ @(kType_ButtonImgRect), @(BTN_R2), @"//R2 img"],            // 35
                                     @[ @(kType_StickRect), @(-1), @"//StickWindow*"],                    // 36
                                     @[ @(kType_StickRect), @(-1), @"//StickArea*"],                    // 37 stick area
                                     @[ @(-2), @(60), @"//radio_stick"],                                 // 38 radio_stick - -2 means use int in index 1
                                     @[ @(-2), @(50), @""]                                  // 39 controller opacity: use 50
                                     ];

    for (NSArray *dataTypeArray in fileDataLayoutElements) {
        // find in data array
        NSInteger coordType = [(NSNumber*) [dataTypeArray objectAtIndex:0] intValue];
        NSInteger coordValue = [(NSNumber*) [dataTypeArray objectAtIndex:1] intValue];
        NSString *comment = (NSString*) [dataTypeArray objectAtIndex:2];
        
        // handle special fields
        // Unused fields?
        if ( [comment isEqualToString:@"//showkyboard"] ||
            [comment isEqualToString:@"//menu"] ) {
            [layoutTextData addObject:[NSString stringWithFormat:@"0,0,0,0%@",comment]];
            continue;
        }
        
        /*
        if ( [comment isEqualToString:@"//StickArea*"] ) {
            [layoutTextData addObject:[NSString stringWithFormat:@"%i,%i,%i,%i//StickArea*",
                                       (int)emuController.rStickArea.origin.x,
                                       (int)emuController.rStickArea.origin.y,
                                       (int)emuController.rStickArea.size.width,
                                       (int)emuController.rStickArea.size.height]];
            continue;
        }
        */
        
        if ( [comment isEqualToString:@"//DPad img"] ||
            [comment isEqualToString:@"//StickWindow*"] ||
            [comment isEqualToString:@"//StickArea*"]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %lu",(unsigned long)coordType,(unsigned long)coordValue];
            NSArray *results = [data filteredArrayUsingPredicate:predicate];
            if ( results.count == 0 ) {
                [layoutTextData addObject:[NSString stringWithFormat:@"Could not find layout data for type=%lu and value=%lu",(unsigned long)coordType,(unsigned long)coordValue]];
                continue;
            }
            LayoutData *layoutData = results.firstObject;
            [layoutTextData addObject:[NSString stringWithFormat:@"%i,%i,%i,%i%@",(int)layoutData.rect.origin.x + layoutData.ax,(int)layoutData.rect.origin.y + layoutData.ay,(int)layoutData.rect.size.width,(int)layoutData.rect.size.height,comment]];
            continue;
        }
        
        if ( coordType == -2 ) {
            [layoutTextData addObject:[NSString stringWithFormat:@"%lu%@",(unsigned long)coordValue,comment]];
            continue;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %lu AND value == %lu",(unsigned long)coordType,(unsigned long)coordValue];
        NSArray *results = [data filteredArrayUsingPredicate:predicate];
        if ( results.count == 0 ) {
            [layoutTextData addObject:[NSString stringWithFormat:@"Could not find layout data for type=%lu and value=%lu",(unsigned long)coordType,(unsigned long)coordValue]];
            continue;
        }
        LayoutData *layoutData = results.firstObject;
        [layoutTextData addObject:[NSString stringWithFormat:@"%i,%i,%i,%i%@",(int)layoutData.rect.origin.x + layoutData.ax,(int)layoutData.rect.origin.y + layoutData.ay,(int)layoutData.rect.size.width,(int)layoutData.rect.size.height,comment]];
    }
    NSLog(@"\n%@",[layoutTextData componentsJoinedByString:@"\n"]);
}

@end
