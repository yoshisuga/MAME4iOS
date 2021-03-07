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

#import "NetplayController.h"
#import "Options.h"
#import "OptionsController.h"
#import "ListOptionController.h"
#import "EmulatorController.h"
#import "Alert.h"

#include "netplay.h"
#include "skt_netplay.h"
#include "myosd.h"

#import "NetplayGameKit.h"

// dont want to change this file too much, so ignore self warning
#pragma clang diagnostic ignored "-Wimplicit-retain-self"

@interface NetplayController()

-(void)setNetplayOptions;
-(bool)ensureWIFI;
-(bool)ensurePeerAddr;
-(void)startSocket;
-(void)joinSocket;
-(void)startGamekit;
-(void)joinGamekit;
-(bool)ensureBluetooth;
-(void)teardownCentral;
+(void)showAlert:(NSString *)msg;

@end

static void netplay_warn_callback(char *msg)
{
    [NetplayController performSelectorOnMainThread:@selector(showAlert:) withObject:[NSString stringWithUTF8String:msg] waitUntilDone:NO];
}

@implementation NetplayController

+ (void)showAlert:(NSString *)msg {
    UIViewController* root = UIApplication.sharedApplication.windows.firstObject.rootViewController;
    [root showAlertWithTitle:@"Netplay" message:msg /*timeout:1.5*/];
}

- (id)init {
    if (self = [super init]) {
        
        arrayWFframeSync = [[NSArray alloc] initWithObjects:@"Auto", @"1", @"2", @"3",@"4", @"5", @"6", @"7", @"8", @"9", @"10",nil];
        arrayWPANtype = [[NSArray alloc] initWithObjects:@"Wi-Fi", @"Bluetooth",nil];
        arrayBTlatency = [[NSArray alloc] initWithObjects:@"Low", @"Normal", @"High",nil];
        
        btMgr = nil;
        btState =  BluetoothNotSet;
       
        self.title = @"Netplay";
        
        
          NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
         [defaultCenter addObserver:self
                          selector:@selector(teardownCentral)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
    }
    return self;
}

-(void)teardownCentral{
    if(btMgr!=nil)
    {
        NSLog(@"Elimino btmgr");
        btMgr = nil;
    }
    btState =  BluetoothNotSet;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    switch (section)
    {
        case 0: return 3;
        case 1: return 1;
        case 2: return 4;
        case 3: return 1;
    }
    return -1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section)
    {
        case 0: return @"Connection";
        case 1: return @"";
        case 2: return @"Wi-Fi";
        case 3: return @"Bluetooth";
    }
    return @"Error!";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [NSString stringWithFormat: @"%lu:%lu", (unsigned long)[indexPath indexAtPosition:0], (unsigned long)[indexPath indexAtPosition:1]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    netplay_t *handle = netplay_get_handle();
    
    if (cell == nil)
    {
        
        UITableViewCellStyle style;
        
        if((indexPath.section==0 && indexPath.row==0)
           || (indexPath.section==0 && indexPath.row==1)
           || (indexPath.section==0 && indexPath.row==2)
           )
            style = UITableViewCellStyleDefault;
        else
            style = UITableViewCellStyleValue1;
        
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:@"CellIdentifier"];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Options *op = [[Options alloc] init];
    
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    bool nogame = myosd_selected_game[0] == '\0';
                    if( nogame || (handle->has_connection && handle->has_joined))
                    {
                       cell.selectionStyle = UITableViewCellSelectionStyleNone;
                       cell.userInteractionEnabled = false;
                       cell.textLabel.enabled = false;
                       if(nogame)
                           cell.textLabel.text =  @"Not Selected Game!";
                       else
                           cell.textLabel.text = [NSString stringWithFormat:@"Connected: %s",handle->game_name];
                    }
                    else
                    {
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                        cell.textLabel.text = [NSString stringWithFormat:@"Start Game: %s",myosd_selected_game];                        
                    }
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    
                    break;
                }
                case 1:
                {
                    if(handle->has_connection)
                    {
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        cell.userInteractionEnabled = false;
                        cell.textLabel.enabled = false;
                    }
                    else
                    {
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    cell.textLabel.text = @"Join Peer Game";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    break;
                }
                case 2:
                {
                    if(!handle->has_connection)
                    {
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        cell.userInteractionEnabled = false;
                        cell.textLabel.enabled = false;
                    }
                    else
                    {
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    cell.textLabel.text = @"Disconnect";
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    
                    break;
                }
            }
            break;
        }
        case 1:
        {
            cell.textLabel.text   = @"Mode";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [arrayWPANtype objectAtIndex:op.wpantype];
            break;
        }
        case 2:
        {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(180, 40, 145, 25)] ;

            textField.returnKeyType = UIReturnKeyDone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.clearButtonMode = UITextFieldViewModeNever;
            textField.textAlignment = NSTextAlignmentRight;
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textField.clearsOnBeginEditing = YES;
            
            textField.delegate = self;
            //textField.borderStyle = UITextBorderStyleRoundedRect;
            
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text   = @"Local Address";
                    char buff[256];
                    int res = skt_netplay_get_address("en0", buff);
                    cell.detailTextLabel.text = res ? [NSString stringWithFormat:@"%s" , buff] : @"No Available!";
                    break;
                }
                case 1:
                {
                    cell.textLabel.text   = @"Peer Address";
                    textField.placeholder = @"Empty Text";
                    textField.text =  op.wfpeeraddr;
                    textField.tag = 1;
                    cell.accessoryView = textField;
                    break;
                }
                case 2:
                {
                    cell.textLabel.text   = @"Port";
                    textField.text =  [NSString stringWithFormat:@"%d",op.wfport];
                    textField.tag = 2;
                    cell.accessoryView = textField;
                    break;
                }
                case 3:
                {
                    cell.textLabel.text   = @"Host Frame Sync";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [arrayWFframeSync objectAtIndex:op.wfframesync];
                    break;
                }
            }
            break;
        }
        case 3:
        {
            cell.textLabel.text   = @"Host Latency";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [arrayBTlatency objectAtIndex:op.btlatency];
            break;
        }
     }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    netplay_t *handle = netplay_get_handle();
    Options *op = [[Options alloc] init];
    
    if (section == 0 && row==0){
        
        if(op.wpantype == 0)
        {
            if(![self ensureWIFI])
                return;
            
            [self startSocket];
//            [self startGamekit];
        }
        else
        {            
            
            if(![self ensureBluetooth])
                return;
            
            [self startGamekit];
        }
        
        [tableView reloadData];
        
    }
    else if (section == 0 && row==1){

        if(op.wpantype == 0)
        {
            if(![self ensureWIFI])
                return;

            if(![self ensurePeerAddr])
                return;
            
            [self joinSocket];
//            [self joinGamekit];
        }
        else
        {
            
            if(![self ensureBluetooth])
                return;

            [self joinGamekit];
        }
        
        [tableView reloadData];
        
    }
    else if (section == 0 && row==2){
        handle->has_connection = false;
        
        [tableView reloadData];
    }
    else if (section == 1 && row==0){
        ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"wpantype" list:arrayWPANtype title:cell.textLabel.text];
        [[self navigationController] pushViewController:listController animated:YES];
    }
    else if(section == 2 && (row==1 || row==2))
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [(UITextField *)cell.accessoryView  becomeFirstResponder];
    }
    else if(section == 2 && row==3)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"wfframesync" list:arrayWFframeSync title:cell.textLabel.text];
        [[self navigationController] pushViewController:listController animated:YES];
    }
    else if(section == 3 && row==0)
    {
        ListOptionController *listController = [[ListOptionController alloc] initWithKey:@"btlatency" list:arrayBTlatency title:cell.textLabel.text];
        [[self navigationController] pushViewController:listController animated:YES];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNetplayOptions];
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell*) [textField superview];
    UITableView *tableView = (UITableView *)self.view;
    [tableView scrollToRowAtIndexPath:[tableView indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    
    Options *op = [[Options alloc] init];
    if(textField.tag == 1)
    {
        if(textField.text == nil ||  textField.text.length==0)
            op.wfpeeraddr = nil;
        else
            op.wfpeeraddr = textField.text;
    }
    else if(textField.tag == 2)
    {
        if(textField.text == nil ||  textField.text.length==0)
            op.wfport = NETPLAY_PORT;
        else
        {
            int i = [textField.text intValue];
            if(i != 0 && i >1024 && i <= 65535)
               op.wfport = i;
            else
               op.wfport = NETPLAY_PORT;
        }
        [(UITableView *)self.view reloadData];
    }
        
    [op saveOptions];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField {
    Options *op = [[Options alloc] init];
    if(textField.tag == 1)
       op.wfpeeraddr = nil;
    else if(textField.tag == 2)
       op.wfport = 0;
    [op saveOptions];
    return YES;
}

-(void)setNetplayOptions{
    netplay_t *handle = netplay_get_handle();
    Options *op = [[Options alloc] init];
    
    if(handle->type == NETPLAY_TYPE_SKT)
    {
        if(op.wfframesync == 0)
            handle->is_auto_frameskip = op.wfframesync == 0;
        else
        {
            handle->is_auto_frameskip = 0;
            
            if(handle->has_joined)
            {
                if(handle->frame_skip!=op.wfframesync)
                    handle->new_frameskip_set = op.wfframesync;
            }
            else
            {
                handle->frame_skip = op.wfframesync;
            }
        }
    }
    else if(handle->type == NETPLAY_TYPE_GAMEKIT)
    {
        if(handle->has_joined)
        {
            int fs;
            if(op.btlatency == 0)
                fs= 2;
            else if(op.btlatency == 1)
                fs = 3;
            else
                fs = 4;
            if(fs!=handle->frame_skip)
                handle->new_frameskip_set = fs;
        }
        else{
            if(op.btlatency == 0)
                handle->frame_skip = 2;
            else if(op.btlatency == 1)
                handle->frame_skip = 3;
            else
                handle->frame_skip = 4;
        }
    }
}

-(bool)ensureWIFI{
    int res = skt_netplay_get_address("en0", NULL);
    
    if(!res)
    {
        [self showAlertWithTitle:@"No WI-FI available!" message:@"You have no wifi connection available. Please connect to a WIFI network."];

        UITableView *tableView = (UITableView *)self.view;
        [tableView reloadData];
        return false;
    }
    return true;
}

-(bool)ensureBluetooth{
    bool first = false;
    if(btMgr==nil)
    {
        btMgr = [[CBCentralManager alloc] initWithDelegate:self queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        first = true;
    }
    
    while (btState==BluetoothNotSet)
         usleep(100);
    
    if(btState == BluetoothOff)
    {
        /*
        if(!first)
        {
            [self showAlertWithTitle:@"No Bluetooth available!" message:@"You have no bluetooth available. Please connect bluetooth."];
        }*/
        UITableView *tableView = (UITableView *)self.view;
        [tableView reloadData];
        return false;
    }
    return true;
}

-(bool)ensurePeerAddr{
    Options *op = [[Options alloc] init];
    if(op.wfpeeraddr == nil)
    {
        [self showAlertWithTitle:@"No peer address available!" message:@"Peer address has not been set."];
        UITableView *tableView = (UITableView *)self.view;
        [tableView reloadData];
        return false;
    }
    return true;
}

-(void)startSocket{
    Options *op = [[Options alloc] init];
    netplay_t *handle = netplay_get_handle();
    
    if(!skt_netplay_init(handle,NULL,op.wfport,netplay_warn_callback))
    {
        [NetplayController showAlert:@"Error initializing Netplay!"];
        return;
    }
    
    cancelled = false;
    [self showAlertWithTitle:@"Waiting peer to connect..." message:nil buttons:@[@"Cancel"] handler:^(NSUInteger button) {
        cancelled = true;
    }];
        
    [self setNetplayOptions];
    
    strcpy(handle->game_name,myosd_selected_game);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        while(!handle->has_joined && !cancelled)
        {
            usleep(1000*1000);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!cancelled)
            {
                [self dismissAlert];
                myosd_exitGame = 1;
            }
            else
            {
                handle->has_connection = false;
            }
            UITableView *tableView = (UITableView *)self.view;
            [tableView reloadData];
        });
        
    });
    
}

-(void)joinSocket{
    Options *op = [[Options alloc] init];
    netplay_t *handle = netplay_get_handle();
    
    if(!skt_netplay_init(handle,[op.wfpeeraddr UTF8String],op.wfport,netplay_warn_callback))
    {
        [NetplayController showAlert:@"Error initializing Netplay!"];
        return;
    }
    
    cancelled = false;
    [self showAlertWithTitle:[NSString stringWithFormat: @"Waiting to join to\n %@...",op.wfpeeraddr] message:nil buttons:@[@"Cancel"] handler:^(NSUInteger button) {
        cancelled = true;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         
        while(!handle->has_joined && !cancelled)
        {
            if(!netplay_send_join(handle))
                cancelled = 1;
            usleep(1000*1000);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if(!cancelled)
            {
                [self dismissAlert];
                myosd_exitGame = 1;
            }
            else
            {
                handle->has_connection = false;
            }
            UITableView *tableView = (UITableView *)self.view;
            [tableView reloadData];
        });
    
    });
}

-(void)startGamekit{
 
    netplay_t *handle = netplay_get_handle();
    
    cancelled = false;
    [self showAlertWithTitle:@"Waiting peer to connect..." message:nil buttons:@[@"Cancel"] handler:^(NSUInteger button) {
        cancelled = true;
    }];

    NetplayGameKit *gk = [NetplayGameKit sharedInstance];
    
    [gk connect:true];
    handle->netplay_warn = netplay_warn_callback;
    
    [self setNetplayOptions];
    
    strcpy(handle->game_name,myosd_selected_game);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        while(!handle->has_connection && !cancelled)
        {
            printf("Esperando conexion\n");
            usleep(1000*1000);
        }
        
        while(!handle->has_joined && !cancelled)
        {
            printf("Esperando join\n");
            usleep(1000*1000);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!cancelled)
            {
                [self dismissAlert];
                myosd_exitGame = 1;
            }
            else
            {
                handle->has_connection = false;
            }
            UITableView *tableView = (UITableView *)self.view;
            [tableView reloadData];
        });
        
    });
}

-(void)joinGamekit{

    netplay_t *handle = netplay_get_handle();
    
    cancelled = false;
    [self showAlertWithTitle: @"Waiting to join..." message:nil buttons:@[@"Cancel"] handler:^(NSUInteger button) {
        cancelled = true;
    }];
    
    NetplayGameKit *gk = [NetplayGameKit sharedInstance];
    
    [gk connect:false];
    handle->netplay_warn = netplay_warn_callback;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        while(!handle->has_connection && !cancelled){
            printf("Esperando conexion\n");
            usleep(1000*1000);
        }
        
        while(!handle->has_joined && !cancelled)
        {
            printf("Esperando to join\n");
            if(!netplay_send_join(handle))
                cancelled = 1;
            usleep(1000*1000);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!cancelled)
            {
                [self dismissAlert];
                myosd_exitGame = 1;
            }
            else
            {
                handle->has_connection = false;
            }
            UITableView *tableView = (UITableView *)self.view;
            [tableView reloadData];
        });
        
    });

}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch(central.state)
    {
        case CBManagerStatePoweredOff: btState = BluetoothOff; break;
        case CBManagerStatePoweredOn: btState = BluetoothOn; break;
        default: btState =  BluetoothUnknown; break;
    }
    NSLog(@"Bluetooth state: %d", btState);
    btMgr = nil;
}

@end
