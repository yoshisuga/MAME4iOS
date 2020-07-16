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

#import <UIKit/UIKit.h>


enum LayoutType
{
    kType_DPadRect = 0,
    kType_ButtonRect = 1,
    kType_DPadImgRect = 2,
    kType_ButtonImgRect = 3,
    kType_StickRect = 4
};

enum LayoutSubtype
{
    kSubtype_A = 0,
    kSubtype_B = 1,
    kSubtype_X = 2,
    kSubtype_Y = 3,
    kSubtype_L1 = 4,
    kSubtype_L2 = 5,
    kSubtype_R1 = 6,
    kSubtype_R2 = 7,
    kSubtype_SELECT = 8,
    kSubtype_START = 9,
    kSubtype_CONTROLLER = 10,
    kSubtype_NONE = -1,
};

@class EmulatorController;

@interface LayoutData : NSObject <NSSecureCoding> 
{
   @public  int type;
   @public  int subtype;
   @public  int value;
   @public  int ax;
   @public  int ay;
   @public  CGRect rect;

}

+(NSMutableArray *)createLayoutData: (EmulatorController *)emuController;
+(NSString *)getLayoutFilePath;
+(void)removeLayoutData;
+(void)saveLayoutData:(NSMutableArray *)data;
+(void)loadLayoutData:(EmulatorController *)emuController;
    
-(CGRect)getNewRect;


@property (readwrite,assign) int type;
@property (readwrite,assign) int subtype;
@property (readwrite,assign) int value;
@property (readwrite,assign) int ax;
@property (readwrite,assign) int ay;
@property (readwrite,assign) CGRect rect;


@end
