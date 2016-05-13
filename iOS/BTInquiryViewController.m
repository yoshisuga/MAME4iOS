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

//  Based on BTInquiryViewController.m by Matthias Ringwald on 10/8/09.


#import "BTInquiryViewController.h"
#import "BTDevice.h"
#import <UIKit/UIToolbar.h>

#include "btstack/btstack.h"
#include "myosd.h"
#include "bt_joy.h"

#define INQUIRY_INTERVAL 3

static BTInquiryViewController *inqView; 
static btstack_packet_handler_t clientHandler;
static uint8_t remoteNameIndex;

@interface BTInquiryViewController (Private) 
- (void) handlePacket:(uint8_t) packet_type channel:(uint16_t) channel packet:(uint8_t*) packet size:(uint16_t) size;
- (void) getNextRemoteName;
- (void) startInquiry;
@end

static void packet_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size){
	if (inqView) {
		[inqView handlePacket:packet_type channel:channel packet:packet size:size];
	}
}

@implementation BTInquiryViewController


@synthesize devices;

- (id) init {
	self = [super initWithStyle:UITableViewStyleGrouped];
	bluetoothState = HCI_STATE_OFF;
	inquiryState = kInquiryInactive;

	connectingDevice = nil;
	restartInquiry = true;
	
	macAddressFont = [UIFont fontWithName:@"Courier New" size:[UIFont labelFontSize]];
	deviceNameFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		
	devices = [[NSMutableArray alloc] init];
	inqView = self;
	return self;
}

- (void) myStartInquiry{
	if (inquiryState != kInquiryInactive) {
		NSLog(@"Inquiry already active");
		return;
	}
	NSLog(@"Inquiry started");

	stopRemoteNameGathering = false;
	restartInquiry = true;

	inquiryState = kInquiryActive;
	[[self tableView] reloadData];
	
	bt_send_cmd(&hci_inquiry, HCI_INQUIRY_LAP, INQUIRY_INTERVAL, 0);
}

- (void) handlePacket:(uint8_t) packet_type channel:(uint16_t) channel packet:(uint8_t*) packet size:(uint16_t) size {
	bd_addr_t event_addr;
	switch (packet_type) {
			
		case HCI_EVENT_PACKET:
			
			switch (packet[0]){
					
				case BTSTACK_EVENT_STATE: 
				{
					// bt stack activated
					bluetoothState = (HCI_STATE)packet[2];
					[[self tableView] reloadData];
					
					// set BT state				
					if (bluetoothState == HCI_STATE_WORKING) {
                        NSLog(@"Registering service PSM_HID_CONTROL" );
                        bt_send_cmd(&l2cap_register_service, PSM_HID_CONTROL, 672);
					}
                    
					break;
				}
                case L2CAP_EVENT_SERVICE_REGISTERED:
                {
                    if (READ_BT_16(packet, 3) == PSM_HID_CONTROL)
                    {
                        NSLog(@"Registered service PSM_HID_CONTROL" );
                        NSLog(@"Registering service PSM_HID_INTERRUPT" );
                        bt_send_cmd(&l2cap_register_service, PSM_HID_INTERRUPT, 672);
                    }
                    if (READ_BT_16(packet, 3) == PSM_HID_INTERRUPT)
                    {
                        NSLog(@"Registered service PSM_HID_INTERRUPT" );
                    }
                    break;
                }
                case L2CAP_EVENT_INCOMING_CONNECTION:
                {
                    const uint32_t psm = READ_BT_16(packet, 10);
                    const unsigned interrupt = (psm == PSM_HID_INTERRUPT) ? 1 : 0;
                    NSLog(@"INCOMING_CONNECTION %@", interrupt==1 ? @"PSM_HID_INTERRUPT" : @"PSM_HID_CONTROL" );
                    
                    uint16_t source_cid = READ_BT_16(packet, 12);
                    
                    bd_addr_t addr;
                    bt_flip_addr(addr, &packet[2]);
                    
                    if(!interrupt)
                    {
                        if(inquiryState == kInquiryInactive)
                        {
                            NSLog(@"kInquiryInactive... decline connection" );
                            bt_send_cmd(&l2cap_decline_connection, source_cid);
                        }
                        else if ([inqView getDeviceForAddress:&addr]) {
							NSLog(@"Device %@ already in list", [BTDevice stringForAddress:&addr]);
						}
                        else
                        {
                         
                           BTDevice *dev = [[BTDevice alloc] init];
                           [dev setAddress:&addr];
                           dev.deviceType = kBluetoothDeviceTypeGeneric;
                           dev.c_source_cid = source_cid;
                           NSLog(@"--> adding %@", [dev toString] );
                           [devices addObject:dev];
                           [dev release];
                           [[inqView tableView] reloadData];
                           
                           NSLog(@"remote name request %@", [dev toString] );
                           bt_send_cmd(&hci_remote_name_request, addr, 0, 0, 0);
                           
                        }
                    }
                    else
                    {
                        BTDevice *dev = [inqView getDeviceForAddress:&addr];
                        if (dev != nil) {
                            NSLog(@"accept connection" );
                            
                            dev.i_source_cid = source_cid;
                            [[inqView tableView] reloadData];
                        
                            bt_send_cmd(&l2cap_accept_connection, source_cid);
                            //usleep(500000);
                        }
                        else
                        {
                            NSLog(@"decline connection" );
                            bt_send_cmd(&l2cap_decline_connection,source_cid);
                        }
                    }
                    
                    break;
                }
				case BTSTACK_EVENT_POWERON_FAILED:
				{
					bluetoothState = HCI_STATE_OFF;
					[[self tableView] reloadData];
					
					UIAlertView* alertView = [[[UIAlertView alloc] init] autorelease];
					alertView.title = @"Bluetooth not accessible!";
					alertView.message = @"Hardware initialization failed!\n"
					"Make sure you have turned off Bluetooth in the System Settings.";
					NSLog(@"Alert: %@ - %@", alertView.title, alertView.message);
					[alertView addButtonWithTitle:@"Dismiss"];
					[alertView show];
					break;
				}	
				case HCI_EVENT_INQUIRY_RESULT:
				case HCI_EVENT_INQUIRY_RESULT_WITH_RSSI:
				{
                    NSLog(@"HCI_EVENT_INQUIRY_RESULT" );
                    int numResponses = packet[2];
					int i;
					for (i=0; i<numResponses;i++){
						bd_addr_t addr;
						bt_flip_addr(addr, &packet[3+i*6]);
						if ([inqView getDeviceForAddress:&addr]) {
							NSLog(@"Device %@ already in list", [BTDevice stringForAddress:&addr]);
							continue;
						}
						BTDevice *dev = [[BTDevice alloc] init];
						[dev setAddress:&addr];
						[dev setPageScanRepetitionMode:packet[3 + numResponses*6 + i]];
						[dev setClockOffset:(READ_BT_16(packet, 3 + numResponses*(6+1+1+1+3) + i*2) & 0x7fff)];
                        dev.deviceType = kBluetoothDeviceTypeGeneric;
                        dev.c_source_cid = 0;
						// hexdump(packet, size);
						NSLog(@"--> adding %@", [dev toString] );
						[devices addObject:dev];
                        [dev release];
					}
				  
					[[inqView tableView] reloadData];
					NSLog(@"bye" );
					break;
				}	
				case HCI_EVENT_REMOTE_NAME_REQUEST_COMPLETE:
				{
					NSLog(@"HCI_EVENT_REMOTE_NAME_REQUEST_COMPLETE" );
                    
                    bt_flip_addr(event_addr, &packet[3]);
					BTDevice *dev = [inqView getDeviceForAddress:&event_addr];
					if (!dev) break;
					[dev setConnectionState:kBluetoothConnectionNotConnected];
					if (packet[2] == 0) {
						[dev setName:[NSString stringWithUTF8String:(const char *) &packet[9]]];

                        bool found = false;
                        if ([[dev name] hasPrefix:@"Nintendo RVL-CNT-01"]){
                            found=true;
                            NSLog(@"WiiMote found with address %@", [BTDevice stringForAddress:[dev address]]);
                            [self stopInquiry];

                            dev.deviceType = kBluetoothDeviceTypeWiiMote;
                            [dev setConnectionState:kBluetoothConnectionConnecting];
                            [self setConnectingDevice:dev];
                            
                            NSLog(@"write authentication enable" );
                            bt_send_cmd(&hci_write_authentication_enable, 0);
                            NSLog(@"done authentication enable" );
                        }
                        else if([[dev name] hasPrefix:@"PLAYSTATION(R)3"]){
                            found = true;
                            NSLog(@"Sixaxis found with address %@", [BTDevice stringForAddress:[dev address]]);
                            [self stopInquiry];
                            
                            dev.deviceType = kBluetoothDeviceTypeSixaxis;
                            [dev setConnectionState:kBluetoothConnectionConnecting];
                            [self setConnectingDevice:dev];
                            
                            NSLog(@"accept connection" );
                            bt_send_cmd(&l2cap_accept_connection, dev.c_source_cid);
                            NSLog(@"done accept connection" );
                        }
                        if(!found)
                        {
                            if(dev.c_source_cid != 0)
                               bt_send_cmd(&l2cap_decline_connection, dev.c_source_cid);
                        }
					}
					[[self tableView] reloadData];
					remoteNameIndex++;
					[self getNextRemoteName];
					break;
				}							
				case HCI_EVENT_COMMAND_COMPLETE:
				{
					if (COMMAND_COMPLETE_EVENT(packet, hci_inquiry_cancel)){
						// inquiry canceled
						NSLog(@"Inquiry cancelled successfully");
						inquiryState = kInquiryInactive;
						[[self tableView] reloadData];

					}
					if (COMMAND_COMPLETE_EVENT(packet, hci_remote_name_request_cancel)){
						// inquiry canceled
						NSLog(@"Remote name request cancelled successfully");
						inquiryState = kInquiryInactive;
						[[self tableView] reloadData];
					}
					
					break;
				}	
				case HCI_EVENT_INQUIRY_COMPLETE:
				{
					NSLog(@"Inquiry complete");
					// reset name check
					remoteNameIndex = 0;
					[self getNextRemoteName];
					break;
				}	
				default:
					break;
					
					// hexdump(packet, size);
					//break;
			}
			
		default:
			break;
	}
	// forward to client app
	(*clientHandler)(packet_type, channel, packet, size);
}

- (BTDevice *) getDeviceForAddress:(bd_addr_t *)addr {
	uint8_t j;
	for (j=0; j<[devices count]; j++){
		BTDevice *dev = [devices objectAtIndex:j];
		if (BD_ADDR_CMP(addr, [dev address]) == 0){
			return dev;
		}
	}
	return nil;
}

- (void) removeAllDevices {
    [devices removeAllObjects];
    [[self tableView] reloadData];
}

- (void) removeAllDevicesNotConnected {
    uint8_t j;
    NSMutableArray *discardedItems = [NSMutableArray array];
    
	for (j=0; j<[devices count]; j++){
		BTDevice *dev = [devices objectAtIndex:j];
		if (dev.connectionState != kBluetoothConnectionConnected){
		    NSLog(@"-->add to be removed %@", [dev toString] );
			[discardedItems addObject:dev];
		}
	}
    [devices removeObjectsInArray:discardedItems];
    [[self tableView] reloadData];
}

- (void) removeDeviceForAddress:(bd_addr_t *)addr {
	uint8_t j;
	for (j=0; j<[devices count]; j++){
		BTDevice *dev = [devices objectAtIndex:j];
		if (BD_ADDR_CMP(addr, [dev address]) == 0){
		    NSLog(@"--> removed %@", [dev toString] );
			[devices removeObject:dev];
			[[self tableView] reloadData];
			return;
		}
	}
}

- (void) getNextRemoteName{
	
	// stopped?
	if (stopRemoteNameGathering) {
		inquiryState = kInquiryInactive;
		[[self tableView] reloadData];
		return;
	}
	
	remoteNameDevice = nil;
		
	for (remoteNameIndex = 0; remoteNameIndex < [devices count]; remoteNameIndex++){
		BTDevice *dev = [devices objectAtIndex:remoteNameIndex];
        printf("c_source_cid %d\n",dev.c_source_cid);
		if (![dev name] && dev.c_source_cid==0){
			remoteNameDevice = dev;
			break;
		}
	}
	if (remoteNameDevice) {
		inquiryState = kInquiryRemoteName;
		[remoteNameDevice setConnectionState:kBluetoothConnectionRemoteName];
        NSLog(@"remote name request%@", [remoteNameDevice toString] );
		bt_send_cmd(&hci_remote_name_request, [remoteNameDevice address], [remoteNameDevice pageScanRepetitionMode], 0, [remoteNameDevice clockOffset] | 0x8000);
	} else  {
		inquiryState = kInquiryInactive;
		// inquiry done.
		if (restartInquiry) {
			[self myStartInquiry];
		}
	}

	[[self tableView] reloadData];
    
}

- (void) startInquiry {

	clientHandler = bt_register_packet_handler(packet_handler);

	bluetoothState = HCI_STATE_INITIALIZING;
	[[self tableView] reloadData];

	stopRemoteNameGathering = false;
	restartInquiry = true;
	
	bt_send_cmd(&btstack_set_power_mode, HCI_POWER_ON );

}

- (void) stopInquiry {
	
	NSLog(@"stop inquiry called, state %u", inquiryState);
	restartInquiry = false;
	stopRemoteNameGathering = true;
	bool immediateNotify = true;
	
	switch (inquiryState) {
		case kInquiryActive:
			// just stop inquiry 
			immediateNotify = false;
			bt_send_cmd(&hci_inquiry_cancel);
			break;
		case kInquiryInactive:
			NSLog(@"stop inquiry called although inquiry inactive?");
			break;
		case kInquiryRemoteName:
			if (remoteNameDevice) {
				// just stop remote name request 
				immediateNotify = false;
				bt_send_cmd(&hci_remote_name_request_cancel, [remoteNameDevice address]);
			}
			break;
		default:
			break;
	}
}

- (BTDevice *)getConnectingDevice{
    return connectingDevice;
}

- (void) setConnectingDevice:(BTDevice *) device {
	connectingDevice = device;
	[[self tableView] reloadData];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
	//return NO;
	//return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	// unregister self
	bt_register_packet_handler(clientHandler);
	// done

    [devices release];
    
    [super dealloc];
}


#pragma mark Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return @"Devices";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int rows = 1;  // 1 for status line 
	if (bluetoothState == HCI_STATE_WORKING) {
		rows += [devices count];
	}
	return rows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		//cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spin.hidesWhenStopped = true;
        cell.accessoryView = spin;
        [spin release];
    }
    
    // Set up the cell...
	NSString *label = nil;
	int idx = [indexPath indexAtPosition:1];
    
	if (bluetoothState != HCI_STATE_WORKING || idx >= [devices count]) {
        cell.textLabel.font = deviceNameFont;
		if (bluetoothState == HCI_STATE_INITIALIZING){
			label = @"Activating BTstack...";
            [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
		} else if (bluetoothState == HCI_STATE_OFF){
			label = @"Bluetooth not accessible!";
             [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
		} else {
			if (connectingDevice) {
				label = @"Connecting...";
                [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
			} else {
				switch (inquiryState){
					case kInquiryInactive:
					    if (myosd_num_of_joys==4)
					    {
					       label = @"Maximun devices connected!";
					    }
						else if ([devices count] > 0){
							label = @"Press here to find more devices...";
						} else {
							label = @"Press here to find first device...";
                                    
						}
                        [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
						break;
					case kInquiryActive:
						//label = @"Searching...";
						label = @"Press PS(Sixaxis) or 1+2(WiiMote)";
                        [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
						break;
					case kInquiryRemoteName:
						label = @"Query device names...";
                        [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
						break;
				}
			}
		}
	} else {
		BTDevice *dev = [devices objectAtIndex:idx];
        label = [dev labelOrNameOrAddress];
                  
		if ([dev name]){
			cell.textLabel.font = deviceNameFont;
		} else {
			cell.textLabel.font = macAddressFont;
		}

		switch ([dev connectionState]) {
			case kBluetoothConnectionNotConnected:
			case kBluetoothConnectionConnected:
                [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
				break;
			case kBluetoothConnectionConnecting:
			case kBluetoothConnectionRemoteName:
                [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
				break;
		}

	}

	cell.textLabel.text = label;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"didSelectRowAtIndexPath %@", indexPath);

	int idx = [indexPath indexAtPosition:1];
	if (bluetoothState == HCI_STATE_WORKING) {
		
			if (idx < [devices count]){
               /* nothing */
			} else if (idx == [devices count]) {
				if (myosd_num_of_joys<4){
					[self myStartInquiry];
				}
			}
		
	} else {
		[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
	}
}


@end

