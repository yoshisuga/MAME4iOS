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

//  Based on BTDevice.m by Matthias Ringwald on 3/30/09.

#import "BTDevice.h"

@implementation BTDevice

@synthesize name;
@synthesize label;
@synthesize connectionState;
@synthesize pageScanRepetitionMode;
@synthesize clockOffset;
@synthesize c_source_cid;
@synthesize i_source_cid;
@synthesize unid;
@synthesize deviceType;

- (BTDevice *)init {
	name = NULL;
	bzero(&address, 6);
	connectionState = kBluetoothConnectionNotConnected;
	return self;
}

- (void) setAddress:(bd_addr_t *)newAddr{
	BD_ADDR_COPY( &address, newAddr);
}

- (bd_addr_t *) address{
	return &address;
}

+ (NSString *) stringForAddress:(bd_addr_t *) address {
	uint8_t * addr = (uint8_t*) address;
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr[0], addr[1], addr[2],
			addr[3], addr[4], addr[5]];
}

- (NSString *) labelOrNameOrAddress{
    if (label)return label;
	if (name) return name;
	return [BTDevice stringForAddress:&address];
}


- (NSString *) toString{
	return [NSString stringWithFormat:@"Device addr %@ name %@", [BTDevice stringForAddress:&address], name];
}

- (void)dealloc {
	[name release];
	[super dealloc];
}

@end
