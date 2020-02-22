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

#import "iCadeView.h"

#include "myosd.h"

@implementation iCadeView

- (id)initWithFrame:(CGRect)frame withEmuController:(EmulatorController*)emulatorController
{
    self = [super initWithFrame:frame];
    inputView = [[UIView alloc] initWithFrame:CGRectZero];//inputView es variable de instancia que ya elimina el super
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    emuController = emulatorController;
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didEnterBackground {
    if (self.active)
    {
        [self resignFirstResponder];
    }
}

- (void)didBecomeActive {
    if (self.active)
    {
        [self becomeFirstResponder];
    }

    if(g_iCade_used){//ensure is iCade
        g_iCade_used = 0;
        g_joy_used = 0;
        myosd_num_of_joys = 0;
        [emuController changeUI];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setActive:(BOOL)value {
    if (_active == value) return;
    
    _active = value;
    if (_active) {
        [self becomeFirstResponder];
    } else {
        [self resignFirstResponder];
    }
}


- (UIView*) inputView {
    return inputView;
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText {
    return NO;
}

- (void)insertText:(NSString *)text {
    //NSLog(@"%s: %@ %d", __FUNCTION__, text, [text characterAtIndex:0]);
    static int up = 0;
    static int down = 0;
    static int left = 0;
    static int right = 0;
    
    static int up2 = 0;
    static int down2 = 0;
    static int left2 = 0;
    static int right2 = 0;
    
    unichar key = [text characterAtIndex:0];
    
    if(g_iCade_used == 0)
    {
        g_iCade_used = 1;
        g_joy_used = 1;
        myosd_num_of_joys = 1;
        [emuController changeUI];
    }
    
    int *ga_btnStates = [emuController getBtnStates];
    
    int joy1 = 0;
    int joy2 = 0;
    
    switch (key)
    {            
        // joystick up
        case 'w':
            if(STICK4WAY)
            {
                myosd_joy_status[0] &= ~MYOSD_LEFT;
                myosd_joy_status[0] &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY)
                myosd_joy_status[0] |= MYOSD_UP;
            up = 1;
            joy1 = 1;
            break;
        case 'e':
            if(STICK4WAY)
            {
                if(left)myosd_joy_status[0] |= MYOSD_LEFT;
                if(right)myosd_joy_status[0] |= MYOSD_RIGHT;
            }
            myosd_joy_status[0] &= ~MYOSD_UP;
            up = 0;
            joy1 = 1;
            break;
            
            // joystick down
        case 'x':
            if(STICK4WAY)
            {
                myosd_joy_status[0] &= ~MYOSD_LEFT;
                myosd_joy_status[0] &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY)
                myosd_joy_status[0] |= MYOSD_DOWN;
            down = 1;
            joy1 = 1;
            break;
        case 'z':
            if(STICK4WAY)
            {
                if(left)myosd_joy_status[0] |= MYOSD_LEFT;
                if(right)myosd_joy_status[0] |= MYOSD_RIGHT;
            }
            myosd_joy_status[0] &= ~MYOSD_DOWN;
            down = 0;
            joy1 = 1;
            break;
            
            // joystick right
        case 'd':
            if(STICK4WAY)
            {
                myosd_joy_status[0] &= ~MYOSD_UP;
                myosd_joy_status[0] &= ~MYOSD_DOWN;
            }
            myosd_joy_status[0] |= MYOSD_RIGHT;
            right = 1;
            joy1 = 1;
            break;
        case 'c':
            if(STICK4WAY)
            {
                if(up)myosd_joy_status[0] |= MYOSD_UP;
                if(down)myosd_joy_status[0] |= MYOSD_DOWN;
            }
            myosd_joy_status[0] &= ~MYOSD_RIGHT;
            right = 0;
            joy1 = 1;
            break;
            
            // joystick left
        case 'a':
            if(STICK4WAY)
            {
                myosd_joy_status[0] &= ~MYOSD_UP;
                myosd_joy_status[0] &= ~MYOSD_DOWN;
            }
            myosd_joy_status[0] |= MYOSD_LEFT;
            left = 1;
            joy1 = 1;
            break;
        case 'q':
            if(STICK4WAY)
            {
                if(up)myosd_joy_status[0] |= MYOSD_UP;
                if(down)myosd_joy_status[0] |= MYOSD_DOWN;
            }
            myosd_joy_status[0] &= ~MYOSD_LEFT;
            left = 0;
            joy1 = 1;
            break;
            
            // Y / UP (iCade/iCP) or 2P Right(iMpulse)
        case 'i':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_Y;
               ga_btnStates[BTN_Y] = BUTTON_PRESS;
               joy1 = 1;
            }
            else
            {
               if(STICK4WAY)
               {
                   myosd_joy_status[1] &= ~MYOSD_UP;
                   myosd_joy_status[1] &= ~MYOSD_DOWN;
               }
               myosd_joy_status[1] |= MYOSD_RIGHT;
               right2 = 1;
               joy2 = 1;
            }
            break;
        case 'm':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
                myosd_joy_status[0] &= ~MYOSD_Y;
                ga_btnStates[BTN_Y] = BUTTON_NO_PRESS;
                joy1 = 1;
            }
            else
            {
                if(STICK4WAY)
                {
                    if(up2)myosd_joy_status[1] |= MYOSD_UP;
                    if(down2)myosd_joy_status[1] |= MYOSD_DOWN;
                }
                myosd_joy_status[1] &= ~MYOSD_RIGHT;
                right2 = 0;
                joy2 = 1;
            }
            break;
            
            // X / DOWN (iCade & iCP) or A / RIGHT (iMpulse)
        case 'l':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_X;
               ga_btnStates[BTN_X] = BUTTON_PRESS;
            }
            else
            {
                myosd_joy_status[0] |= MYOSD_A;
                ga_btnStates[BTN_A] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 'v':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_X;
               ga_btnStates[BTN_X] = BUTTON_NO_PRESS;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_A;
               ga_btnStates[BTN_A] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
            // A / LEFT (iCade & iCP) or X / DOWN (iMpulse)
        case 'k':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_A;
               ga_btnStates[BTN_A] = BUTTON_PRESS;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_X;
               ga_btnStates[BTN_X] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 'p':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_A;
               ga_btnStates[BTN_A] = BUTTON_NO_PRESS;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_X;
               ga_btnStates[BTN_X] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
            // B / RIGHT (iCade & iCP) or Y / UP (iMpulse)
        case 'o':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_B;
               ga_btnStates[BTN_B] = BUTTON_PRESS;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_Y;
               ga_btnStates[BTN_Y] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 'g':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_B;
               ga_btnStates[BTN_B] = BUTTON_NO_PRESS;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_Y;
               ga_btnStates[BTN_Y] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
            // SELECT / COIN (iCade & iCP) or B / RIGHT (iMpulse)
        case 'y': //button down
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_SELECT;
               ga_btnStates[BTN_SELECT] = BUTTON_PRESS;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_B;
               ga_btnStates[BTN_B] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 't': //button up
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_SELECT;
               ga_btnStates[BTN_SELECT] = BUTTON_NO_PRESS;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_B;
               ga_btnStates[BTN_B] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
            //L1(iCade) or START (iCP) or 2P LEFT(iMpulse)
        case 'u':   //button down
            if(g_pref_ext_control_type == EXT_CONTROL_ICADE) {
                myosd_joy_status[0] |= MYOSD_L1;
                ga_btnStates[BTN_L1] = BUTTON_PRESS;
                joy1 = 1;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] |= MYOSD_START;
                ga_btnStates[BTN_START] = BUTTON_PRESS;
                joy1 = 1;
            }
            else {
                if(STICK4WAY)
                {
                    myosd_joy_status[1] &= ~MYOSD_UP;
                    myosd_joy_status[1] &= ~MYOSD_DOWN;
                }
                myosd_joy_status[1] |= MYOSD_LEFT;
                left2 = 1;
                joy2 = 1;
            }
           
            break;
        case 'f':   //button up
            if(g_pref_ext_control_type == EXT_CONTROL_ICADE) {
                myosd_joy_status[0] &= ~MYOSD_L1;
                ga_btnStates[BTN_L1] = BUTTON_NO_PRESS;
                joy1 = 1;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] &= ~MYOSD_START;
                ga_btnStates[BTN_START] = BUTTON_NO_PRESS;
                joy1 = 1;
            }
            else{
                if(STICK4WAY)
                {
                    if(up2)myosd_joy_status[1] |= MYOSD_UP;
                    if(down2)myosd_joy_status[1] |= MYOSD_DOWN;
                }
                myosd_joy_status[1] &= ~MYOSD_LEFT;
                left2 = 0;
                joy2 = 1;
            }
            
            break;
            
            //Start(iCade) or L1(iCP) or Coin / Select(iMpulse)
        case 'h':   //button down
            if(g_pref_ext_control_type == EXT_CONTROL_ICADE) {
                myosd_joy_status[0] |= MYOSD_START;
                ga_btnStates[BTN_START] = BUTTON_PRESS;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] |= MYOSD_L1;
                ga_btnStates[BTN_L1] = BUTTON_PRESS;
            }
            else
            {
                myosd_joy_status[0] |= MYOSD_SELECT;
                ga_btnStates[BTN_SELECT] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 'r':   //button up
            if(g_pref_ext_control_type == EXT_CONTROL_ICADE) {
                myosd_joy_status[0] &= ~MYOSD_START;
                ga_btnStates[BTN_START] = BUTTON_NO_PRESS;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] &= ~MYOSD_L1;
                ga_btnStates[BTN_L1] = BUTTON_NO_PRESS;
            }
            else
            {
                myosd_joy_status[0] &= ~MYOSD_SELECT;
                ga_btnStates[BTN_SELECT] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
            // R1 (iCade & iCP) or Start (iMpulse)
        case 'j':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_R1;
               ga_btnStates[BTN_R1] = BUTTON_PRESS;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_START;
               ga_btnStates[BTN_START] = BUTTON_PRESS;
            }
            joy1 = 1;
            break;
        case 'n':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_R1;
               ga_btnStates[BTN_R1] = BUTTON_NO_PRESS;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_START;
               ga_btnStates[BTN_START] = BUTTON_NO_PRESS;
            }
            joy1 = 1;
            break;
            
       ////////////
    
            // 2p joystick up
        case '[':
            if(STICK4WAY)
            {
                myosd_joy_status[1] &= ~MYOSD_LEFT;
                myosd_joy_status[1] &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY)
                myosd_joy_status[1] |= MYOSD_UP;
            up2 = 1;
            joy2 = 1;
            break;
        case ']':
            if(STICK4WAY)
            {
                if(left)myosd_joy_status[1] |= MYOSD_LEFT;
                if(right)myosd_joy_status[1] |= MYOSD_RIGHT;
            }
            myosd_joy_status[1] &= ~MYOSD_UP;
            up2 = 0;
            joy2 = 1;
            break;
            
            //2p joystick down
        case 's':
            if(STICK4WAY)
            {
                myosd_joy_status[1] &= ~MYOSD_LEFT;
                myosd_joy_status[1] &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY)
                myosd_joy_status[1] |= MYOSD_DOWN;
            down2 = 1;
            joy2 = 1;
            break;
        case 'b':
            if(STICK4WAY)
            {
                if(left)myosd_joy_status[1] |= MYOSD_LEFT;
                if(right)myosd_joy_status[1] |= MYOSD_RIGHT;
            }
            myosd_joy_status[1] &= ~MYOSD_DOWN;
            down2 = 0;
            joy2 = 1;
            break;
            
            // B / RIGHT
        case '3':
            myosd_joy_status[1] |= MYOSD_B;
            joy2 = 1;
            break;
        case '4':
            myosd_joy_status[1] &= ~MYOSD_B;
            joy2 = 1;
            break;
            
            // X / DOWN
        case '1':
            myosd_joy_status[1] |= MYOSD_X;
            joy2 = 1;
            break;
        case '2':
            myosd_joy_status[1] &= ~MYOSD_X;
            joy2 = 1;
            break;
            
            // A / LEFT
        case '5':
            myosd_joy_status[1] |= MYOSD_A;
            joy2 = 1;
            break;
        case '6':
            myosd_joy_status[1] &= ~MYOSD_A;
            joy2 = 1;
            break;
            
            //Y / UP
        case '7':
            myosd_joy_status[1] |= MYOSD_Y;
            joy2 = 1;
            break;
        case '8':
            myosd_joy_status[1] &= ~MYOSD_Y;
            joy2 = 1;
            break;
            
            // SELECT / COIN
        case '9': //button down
            myosd_joy_status[1] |= MYOSD_SELECT;
            joy2 = 1;
            break;
        case '0': //button up
            myosd_joy_status[1] &= ~MYOSD_SELECT;
            joy2 = 1;
            break;
            
            //START
        case '-':   //button down
            myosd_joy_status[1] |= MYOSD_START;
            joy2 = 1;
            break;
        case '=':   //button up
            myosd_joy_status[1] &= ~MYOSD_START;
            joy2 = 1;
            break;
            
        ///////////
            
    }
        
    if(joy2 && myosd_num_of_joys<2)
    {
        myosd_num_of_joys = 2;
    }
    //printf(" %d %d\n",myosd_num_of_joys,g_joy_used);
    
    int dpad_state = 0;
    
    // calculate dpad_state
    switch (myosd_joy_status[0] & (MYOSD_UP|MYOSD_DOWN|MYOSD_LEFT|MYOSD_RIGHT))
    {
        case    MYOSD_UP:    dpad_state = DPAD_UP; break;
        case    MYOSD_DOWN:  dpad_state = DPAD_DOWN; break;
        case    MYOSD_LEFT:  dpad_state = DPAD_LEFT; break;
        case    MYOSD_RIGHT: dpad_state = DPAD_RIGHT; break;
            
        case    MYOSD_UP | MYOSD_LEFT:  dpad_state = DPAD_UP_LEFT; break;
        case    MYOSD_UP | MYOSD_RIGHT: dpad_state = DPAD_UP_RIGHT; break;
        case    MYOSD_DOWN | MYOSD_LEFT:  dpad_state = DPAD_DOWN_LEFT; break;
        case    MYOSD_DOWN | MYOSD_RIGHT: dpad_state = DPAD_DOWN_RIGHT; break;
            
        default: dpad_state = DPAD_NONE;
    }
    
    emuController.dpad_state = dpad_state;

    static int cycleResponder = 0;
    if (++cycleResponder > 20) {
        // necessary to clear a buffer that accumulates internally
        cycleResponder = 0;
        [self resignFirstResponder];
        [self becomeFirstResponder];        
    }
    
    [emuController handle_DPAD];
}

- (void)deleteBackward {
    // This space intentionally left blank to complete protocol
}

@end
