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

// Based on BTDevice.h by Matthias Ringwald on 3/30/09.


#import <Foundation/Foundation.h>
#include "btstack/utils.h"


typedef enum {
	kBluetoothDeviceTypeGeneric = 0,
    kBluetoothDeviceTypeWiiMote,
    kBluetoothDeviceTypeSixaxis
} BluetoothDeviceType;

typedef enum {
	kBluetoothConnectionNotConnected = 0,
	kBluetoothConnectionRemoteName,
	kBluetoothConnectionConnecting,
	kBluetoothConnectionConnected
} BluetoothConnectionState;

@interface BTDevice : NSObject {
	bd_addr_t address;
	NSString * name;
    NSString * label;
	uint8_t    pageScanRepetitionMode;
	uint16_t   clockOffset;
	uint32_t   classOfDevice;
	BluetoothConnectionState  connectionState;
}

- (void) setAddress:(bd_addr_t *)addr;
- (bd_addr_t *) address;
- (NSString *) toString;
+ (NSString *) stringForAddress:(bd_addr_t *) address;
- (NSString *) labelOrNameOrAddress;

@property (nonatomic, assign) BluetoothDeviceType deviceType;
@property (nonatomic, copy)   NSString *          name;
@property (nonatomic, copy)   NSString *          label;
@property (nonatomic, assign) uint16_t            clockOffset;
@property (nonatomic, assign) uint8_t             pageScanRepetitionMode;
@property (nonatomic, assign) BluetoothConnectionState connectionState;
@property (nonatomic, assign) uint16_t            c_source_cid;
@property (nonatomic, assign) uint16_t            i_source_cid;
@property (nonatomic, assign) uint8_t             unid;


@end
