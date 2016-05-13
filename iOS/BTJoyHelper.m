/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2012 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * In addition, as a special exception, Seleuco
 * gives permission to link the code of this program with
 * the MAME library (or with modified versions of MAME that use the
 * same license as MAME), and distribute linked combinations including
 * the two.  You must obey the GNU General Public License in all
 * respects for all of the code used other than MAME.  If you modify
 * this file, you may extend this exception to your version of the
 * file, but you are not obligated to do so.  If you do not wish to
 * do so, delete this exception statement from your version.
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <dlfcn.h>

#include "bt_joy.h"
#include "wiimote.h"
#include "sixaxis.h"

#import "BTJoyHelper.h"
#import "Globals.h"

#import "EmulatorController.h"

#import "BTDevice.h"
#import "BTInquiryViewController.h"

#import "btstack/btstack.h"
#import "btstack/run_loop.h"
#import "btstack/hci_cmds.h"

#include "myosd.h"

static bool activated = false;
static bool btOK = false;
static bool initLoop = false;

//bool conected = false;

static BTInquiryViewController *inqViewControl;

void connection_callback(struct bt_joy_t *btjoy) {
    BTDevice *device = [inqViewControl getDeviceForAddress:&btjoy->addr];
    if(device!=nil && device.connectionState!=kBluetoothConnectionConnected)
    {
        [device setConnectionState:kBluetoothConnectionConnected];
        NSString *label = @"??";
        if(btjoy->type == SIXAXIS_TYPE)
            label = @"Sixaxis";
        else if(btjoy->type == WIIMOTE_TYPE)
        {
           label = btjoy->joy_data.wm.exp.type != EXP_NONE ? @"Classic Controller" : @"WiiMote";
        }
        
        [device setLabel:[NSString stringWithFormat:@"Connected P%d: %@.",(btjoy->joy_id)+1,label]];
        [inqViewControl setConnectingDevice:nil];
        myosd_num_of_joys++;
    }
}

void packet_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size){
    bd_addr_t event_addr;
    
    
    if(BTJOY_DBG)printf("packet_type:0x%02x channel: 0x%02x [0x%02x 0x%02x 0x%02x 0x%02x]\n",packet_type,channel,packet[0],packet[1],packet[2],packet[3]);
    
    switch (packet_type) {
            
        case L2CAP_DATA_PACKET://0x06
        {
            btjoy_handle_data_packet(channel, packet, size);
            
            break;
        }
        case HCI_EVENT_PACKET://0x04
        {
            switch (packet[0]){
                    
                case HCI_EVENT_COMMAND_COMPLETE:
                    if ( COMMAND_COMPLETE_EVENT(packet, hci_write_authentication_enable) ) {
                        // connect to device
                        BTDevice *device = [inqViewControl getConnectingDevice];
                        if(device!=nil)
                            bt_send_cmd(&l2cap_create_channel, [device address], PSM_HID_CONTROL);
                    }
                    break;
                    
                case HCI_EVENT_PIN_CODE_REQUEST:
                    bt_flip_addr(event_addr, &packet[2]);
                    BTDevice *device = [inqViewControl getConnectingDevice];
                    if(device == nil)break;
                    if (BD_ADDR_CMP([device address], event_addr)) break;
                    
                    // inform about pin code request
                    NSLog(@"HCI_EVENT_PIN_CODE_REQUEST\n");
                    bt_send_cmd(&hci_pin_code_request_reply, event_addr, 6,  &packet[2]); // use inverse bd_addr as PIN
                    break;
                    
                case L2CAP_EVENT_CHANNEL_OPENED:
                    
                    // data: event (8), len(8), status (8), address(48), handle (16), psm (16), local_cid(16), remote_cid (16)
                    if (packet[2] == 0) {
                        
                        // inform about new l2cap connection
                        bt_flip_addr(event_addr, &packet[3]);
                        uint16_t psm = READ_BT_16(packet, 11);
                        uint16_t source_cid = READ_BT_16(packet, 13);
                        uint16_t dest_cid   = READ_BT_16(packet, 15);
                        uint16_t wiiMoteConHandle = READ_BT_16(packet, 9);
                        NSLog(@"Channel successfully opened: handle 0x%02x, psm 0x%02x, source cid 0x%02x, dest cid 0x%02x",
                              wiiMoteConHandle, psm, source_cid,  dest_cid);
                        
                        BTDevice *device = [inqViewControl getConnectingDevice];
                        if(device==nil)break;
                                                
                        if (psm == PSM_HID_CONTROL) {
                            
                            if(device.deviceType == kBluetoothDeviceTypeWiiMote)
                            {
                                //control channel openedn succesfully, now open  interupt channel, too.
                                if(WIIMOTE_DBG)printf("open interrupt channel\n");
                                
                                device.c_source_cid = source_cid;
                                
                                bt_send_cmd(&l2cap_create_channel, event_addr, PSM_HID_INTERRUPT);
                            }
                            
                        } else {
                            
                            if(device.deviceType == kBluetoothDeviceTypeWiiMote)
                            {
                                device.i_source_cid = source_cid;
                                
                                bt_joy_initjoy(WIIMOTE_TYPE, [device address] ,device.c_source_cid ,device.i_source_cid );
                            }
                            else if(device.deviceType == kBluetoothDeviceTypeSixaxis)
                            {
                                bt_joy_initjoy(SIXAXIS_TYPE, [device address] ,device.c_source_cid ,device.i_source_cid );
                            }
                        }
                    }
                    break;
                case L2CAP_EVENT_CHANNEL_CLOSED:
                {
                    // data: event (8), len(8), channel (16)
                    uint16_t  source_cid = READ_BT_16(packet, 2);
                    NSLog(@"Channel successfully closed: cid 0x%02x",source_cid);
                    

                    bd_addr_t addr;
                    int joyid = bt_joy_remove(source_cid,&addr);
                    if(joyid!=-1)
                    {
                        [inqViewControl removeDeviceForAddress:&addr];
                        UIAlertView* alert =
                        [[UIAlertView alloc] initWithTitle:@"Disconnection!"
                                                   message:[NSString stringWithFormat:@"P%@ disconnection detected.\nIs battery drainned?",[NSNumber numberWithInt:(joyid+1)]]
                                                  delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                        [alert show];
                        
                        [alert release];
                    }
                    
                }
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

@implementation BTJoyHelper

+(void) startBTJoy:(UIViewController *)controller{

    if(!initLoop)
    {
        void *handle = dlopen("libBTstack.dylib",RTLD_LAZY);
        if(!handle)
        {
            UIAlertView* alert =
            [[UIAlertView alloc] initWithTitle:@"Error!"
                                       message:@"You don't have BTstack installed. Please, install it from Cydia."
                                      delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
            [alert show];
            
            [alert release];
            
            EmulatorController *eC = (EmulatorController *)controller;
            [eC endMenu];
            return;
        }
        dlclose(handle);
        
        run_loop_init(RUN_LOOP_COCOA);
        initLoop = true;
    }
    if(!btOK )
    {
        if (bt_open() ){
            // Alert user?
        } else {
            bt_register_packet_handler(packet_handler);
            bt_joy_init(connection_callback);
            btOK = true;
        }
    }
    
    if (btOK)
    {
        // create inq controller
        if(inqViewControl==nil)
        {
            inqViewControl = [[BTInquiryViewController alloc] init];
            
            struct CGRect rect = controller.view.frame;
            
            CGFloat navBarWidht =  rect.size.width;
            CGFloat navBarHeight = 45;
            
            UINavigationBar *navBar = [ [ UINavigationBar alloc ] initWithFrame: CGRectMake(0, 0, navBarWidht , navBarHeight)];
            [navBar autorelease];
            [navBar setDelegate: inqViewControl ];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button setFrame:CGRectMake(rect.size.width-70,5,60,35)];
            [button setTitle:@"Done" forState:UIControlStateNormal];
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [button addTarget:self action:@selector(cancelBTJoySearch) forControlEvents:UIControlEventTouchUpInside];
            
            [navBar addSubview:button];
            
            UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(40,0,300, navBarHeight)];
            navLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            navLabel.text = @"WiiMote/Sixaxis Search";
            navLabel.backgroundColor = [UIColor clearColor];
            navLabel.textColor = [UIColor blackColor];
            navLabel.font = [UIFont systemFontOfSize: 18];
            navLabel.textAlignment = UITextAlignmentLeft;
            [navBar addSubview:navLabel];
            [navLabel release];
            
            [[inqViewControl tableView] setTableHeaderView:navBar];
            [navBar release];
            
        }
    
      if(!activated)
      {
          UIAlertView* alertView=[[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Do you want to activate BTstack?"
                                                           delegate:self cancelButtonTitle:nil
                                                  otherButtonTitles:@"Yes",@"No",nil];
          
          [alertView show];
          [alertView release];
      }
      
      [controller presentModalViewController:inqViewControl animated:YES];
  }

}

+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

  if(buttonIndex == 0 )
  {
     //[inqViewControl setAllowSelection:true];
     activated = true;
     [inqViewControl startInquiry];
  }
  else
  {
     [inqViewControl dismissModalViewControllerAnimated:YES];
     EmulatorController *eC = (EmulatorController *)my_parentViewController(inqViewControl);      
     [eC endMenu];

  }
}

+(void) cancelBTJoySearch {
    [inqViewControl stopInquiry];
    [inqViewControl removeAllDevicesNotConnected];
    [inqViewControl setConnectingDevice:nil];
    [inqViewControl dismissModalViewControllerAnimated:YES];
    EmulatorController *eC = (EmulatorController *)my_parentViewController(inqViewControl);
    [eC endMenu];
}

+ (void)endBTJoy {
    
    if(btOK)
    {
		if(g_menu_option==MENU_BTJOY)
		{
            [inqViewControl dismissModalViewControllerAnimated:YES];
            EmulatorController *eC = (EmulatorController *)my_parentViewController(inqViewControl);
            [eC endMenu];
		}
        		
        [inqViewControl removeAllDevices];

        [inqViewControl setConnectingDevice:nil];
        
		myosd_num_of_joys=0;
	    bt_send_cmd(&btstack_set_power_mode, HCI_POWER_OFF );
	    bt_close();
	    activated= false;
		btOK = false;
    }
}

@end

