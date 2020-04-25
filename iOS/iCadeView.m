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

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

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
    
    if (g_pref_ext_control_type < EXT_CONTROL_ICADE)
        return;

#if TARGET_OS_IOS
    [self iCadeKey:text];
#endif
    
#if 0  // TODO: is this really nessesarry???
    static int cycleResponder = 0;
    if (++cycleResponder > 20) {
        // necessary to clear a buffer that accumulates internally
        cycleResponder = 0;
        [self resignFirstResponder];
        [self becomeFirstResponder];
    }
#endif
}

- (void)iCadeKey:(NSString *)text {
    
    static int up = 0;
    static int down = 0;
    static int left = 0;
    static int right = 0;
    
    static int up2 = 0;
    static int down2 = 0;
    static int left2 = 0;
    static int right2 = 0;
    
    unichar key = [text characterAtIndex:0];
    
#if TARGET_OS_TV
    if ([emuController controllerUserInteractionEnabled])
        return;
#endif
    
    NSLog(@"%s: %@ (%d)", __FUNCTION__, text.debugDescription, [text characterAtIndex:0]);

    if(g_iCade_used == 0)
    {
        g_iCade_used = 1;
        g_joy_used = 1;
        myosd_num_of_joys = 1;
        [emuController changeUI];
    }
    
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
            if(!STICK2WAY || g_emulation_paused)
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
            if(!STICK2WAY || g_emulation_paused)
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
            }
            else
            {
                myosd_joy_status[0] |= MYOSD_A;
            }
            joy1 = 1;
            break;
        case 'v':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_X;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_A;
            }
            joy1 = 1;
            break;
            
            // A / LEFT (iCade & iCP) or X / DOWN (iMpulse)
        case 'k':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_A;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_X;
            }
            joy1 = 1;
            break;
        case 'p':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_A;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_X;
            }
            joy1 = 1;
            break;
            
            // B / RIGHT (iCade & iCP) or Y / UP (iMpulse)
        case 'o':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_B;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_Y;
            }
            joy1 = 1;
            break;
        case 'g':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_B;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_Y;
            }
            joy1 = 1;
            break;
            
            // SELECT / COIN (iCade & iCP) or B / RIGHT (iMpulse)
        case 'y': //button down
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_SELECT;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_B;
            }
            joy1 = 1;
            break;
        case 't': //button up
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_SELECT;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_B;
            }
            joy1 = 1;
            break;
            
            //L1(iCade) or START (iCP) or 2P LEFT(iMpulse)
        case 'u':   //button down
            if(g_pref_ext_control_type <= EXT_CONTROL_ICADE) {
                myosd_joy_status[0] |= MYOSD_L1;
                joy1 = 1;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] |= MYOSD_START;
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
            if(g_pref_ext_control_type <= EXT_CONTROL_ICADE) {
                myosd_joy_status[0] &= ~MYOSD_L1;
                joy1 = 1;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] &= ~MYOSD_START;
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
            if(g_pref_ext_control_type <= EXT_CONTROL_ICADE) {
                myosd_joy_status[0] |= MYOSD_START;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] |= MYOSD_L1;
            }
            else
            {
                myosd_joy_status[0] |= MYOSD_SELECT;
            }
            joy1 = 1;
            break;
        case 'r':   //button up
            if(g_pref_ext_control_type <= EXT_CONTROL_ICADE) {
                myosd_joy_status[0] &= ~MYOSD_START;
            }
            else if(g_pref_ext_control_type == EXT_CONTROL_ICP){
                myosd_joy_status[0] &= ~MYOSD_L1;
            }
            else
            {
                myosd_joy_status[0] &= ~MYOSD_SELECT;
            }
            joy1 = 1;
            break;
            
            // R1 (iCade & iCP) or Start (iMpulse)
        case 'j':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] |= MYOSD_R1;
            }
            else
            {
               myosd_joy_status[0] |= MYOSD_START;
            }
            joy1 = 1;
            break;
        case 'n':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_joy_status[0] &= ~MYOSD_R1;
            }
            else
            {
               myosd_joy_status[0] &= ~MYOSD_START;
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
            if(!STICK2WAY || g_emulation_paused)
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
            if(!STICK2WAY || g_emulation_paused)
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

    // emulate a analog joystick
    joy_analog_y[0][0] = (myosd_joy_status[0] & MYOSD_UP)    ? +1.0 : (myosd_joy_status[0] & MYOSD_DOWN) ? -1.0 : 0.0;
    joy_analog_x[0][0] = (myosd_joy_status[0] & MYOSD_RIGHT) ? +1.0 : (myosd_joy_status[0] & MYOSD_LEFT) ? -1.0 : 0.0;
    
    // also set the pad_status
    myosd_pad_status = myosd_joy_status[0];

    [emuController handle_INPUT];
}

- (void)deleteBackward {
    // This space intentionally left blank to complete protocol
}

#pragma mark Hardare Keyboard

//
// HARDWARE KEYBOARD
//
// handle input from a hardware keyboard, the following are examples hardware keyboards.
//
//      * a USB or Bluetooth keyboard connected to a iOS device or AppleTV
//      * Apple - Smart Keyboard connected to an iPad
//      * macOS keyboard when debugging in Xcode simulator
//
// we suppoprt a small subset of the keys supported by the command line MAME.
//
//      ARROW KEYS      - emulate a dpad or joystick
//      LEFT CONTROL    - A
//      LEFT OPTION/ALT - B
//      SPACE           - Y
//      LEFT SHIFT      - X
//      LEFT CMD        - L1
//      RIGHT CMD       - R1
//
//      1               - Player 1 START
//      2               - Player 2 START
//      5               - Player 1 COIN
//      6               - Player 2 COIN
//
//      TAB             - MAME UI MENU
//      ESC             - MAME UI EXIT
//      RETURN          - MAME UI SELECT    (aka A)
//      DELETE          - MAME UI BACK      (aka B)
//
//      BQUOTE          - MAME4iOS MENU
//
//      CMD+ENTER       - TOGGLE FULLSCREEN
//      CMD+T           - TOGGLE CRT/TV FILTER
//      CMD+S           - TOGGLE SCANLINE FILTER
//
// iCade keys
//        we      yt uf im og
//      aq  dc    hr jn kp lv
//        xz
//
// 8BitDo keys
//       k     m
//    c           h
//   e f         i g
//    d    n o    j
//

#define KEY_RARROW   79
#define KEY_LARROW   80
#define KEY_DARROW   81
#define KEY_UARROW   82

#define KEY_LCONTROL 224
#define KEY_LSHIFT   225
#define KEY_LALT     226
#define KEY_LCMD     227

#define KEY_RCONTROL 228
#define KEY_RSHIFT   229
#define KEY_RALT     230
#define KEY_RCMD     231

#define KEY_RETURN   40
#define KEY_ESCAPE   41
#define KEY_DELETE   42
#define KEY_TAB      43
#define KEY_SPACE    44
#define KEY_BQUOTE   53

#define KEY_A        4
#define KEY_B        5
#define KEY_C        6
#define KEY_D        7
#define KEY_E        8
#define KEY_F        9
#define KEY_G        10
#define KEY_H        11
#define KEY_I        12
#define KEY_J        13
#define KEY_K        14
#define KEY_L        15
#define KEY_M        16
#define KEY_N        17
#define KEY_O        18
#define KEY_P        19
#define KEY_Q        20
#define KEY_R        21
#define KEY_S        22
#define KEY_T        23
#define KEY_U        24
#define KEY_V        25
#define KEY_W        26
#define KEY_X        27
#define KEY_Y        28
#define KEY_Z        29

#define KEY_1        30
#define KEY_2        31
#define KEY_3        32
#define KEY_4        33
#define KEY_5        34
#define KEY_6        35
#define KEY_7        36
#define KEY_8        37
#define KEY_9        38
#define KEY_0        39

#define KEY_DOWN     0x8000

// Overloaded _keyCommandForEvent (UIResponder.h) // Only exists in iOS 9+
-(UIKeyCommand *)_keyCommandForEvent:(UIEvent *)event { // UIPhysicalKeyboardEvent
    
    static BOOL g_keyboard_state[256];
    
    int keyCode = [[event valueForKey:@"_keyCode"] intValue];
    BOOL isKeyDown = [[event valueForKey:@"_isKeyDown"] boolValue];

    if (keyCode <= 0 || keyCode > 255 || g_keyboard_state[keyCode] == isKeyDown)
        return nil;
    
    g_keyboard_state[keyCode] = isKeyDown;

    NSLog(@"_keyCommandForEvent:'%@' '%@' keyCode:%@ isKeyDown:%@ time:%f", [event valueForKey:@"_unmodifiedInput"], [event valueForKey:@"_modifiedInput"], [event valueForKey:@"_keyCode"], [event valueForKey:@"_isKeyDown"], [event timestamp]);

    if (g_pref_ext_control_type != EXT_CONTROL_NONE)
    {
#if TARGET_OS_TV
        if (isKeyDown)
            [self iCadeKey:[event valueForKey:@"_unmodifiedInput"]];
#endif
        return nil;
    }
    
    NSString* iCadeKey = nil;
    
    // MAME keys
    switch (keyCode + (isKeyDown ? KEY_DOWN : 0)) {
            
        // DPAD
        case KEY_RARROW:            iCadeKey = @"c"; break;
        case KEY_RARROW+KEY_DOWN:   iCadeKey = @"d"; break;
        case KEY_LARROW:            iCadeKey = @"q"; break;
        case KEY_LARROW+KEY_DOWN:   iCadeKey = @"a"; break;
        case KEY_UARROW:            iCadeKey = @"e"; break;
        case KEY_UARROW+KEY_DOWN:   iCadeKey = @"w"; break;
        case KEY_DARROW:            iCadeKey = @"z"; break;
        case KEY_DARROW+KEY_DOWN:   iCadeKey = @"x"; break;

        // A/B/Y/X
        case KEY_LCONTROL:          iCadeKey = @"p"; break;
        case KEY_LCONTROL+KEY_DOWN: iCadeKey = @"k"; break;
        case KEY_LALT:              iCadeKey = @"g"; break;
        case KEY_LALT+KEY_DOWN:     iCadeKey = @"o"; break;
        case KEY_SPACE:             iCadeKey = @"m"; break;
        case KEY_SPACE+KEY_DOWN:    iCadeKey = @"i"; break;
        case KEY_LSHIFT:            iCadeKey = @"v"; break;
        case KEY_LSHIFT+KEY_DOWN:   iCadeKey = @"l"; break;

        // L1/R1
        case KEY_LCMD:              iCadeKey = @"f"; break;
        case KEY_LCMD+KEY_DOWN:     iCadeKey = @"u"; break;
        case KEY_RCMD:              iCadeKey = @"n"; break;
        case KEY_RCMD+KEY_DOWN:     iCadeKey = @"j"; break;

        // RETURN -> A
        case KEY_RETURN:            iCadeKey = @"p"; break;
        case KEY_RETURN+KEY_DOWN:   iCadeKey = @"k"; break;
            
        // DELETE -> B
        case KEY_DELETE:            iCadeKey = @"g"; break;
        case KEY_DELETE+KEY_DOWN:   iCadeKey = @"o"; break;
            
        // START and SELECT/COIN (Player 1)
        case KEY_1:                 iCadeKey = @"r"; break;
        case KEY_1+KEY_DOWN:        iCadeKey = @"h"; break;
        case KEY_5:                 iCadeKey = @"t"; break;
        case KEY_5+KEY_DOWN:        iCadeKey = @"y"; break;
            
        // START and SELECT/COIN (Player 2)
        case KEY_2:                 myosd_pad_status &= ~(MYOSD_START|MYOSD_UP); break;
        case KEY_2+KEY_DOWN:        myosd_pad_status |=  (MYOSD_START|MYOSD_UP); break;
        case KEY_6:                 myosd_pad_status &= ~(MYOSD_SELECT|MYOSD_UP); break;
        case KEY_6+KEY_DOWN:        myosd_pad_status |=  (MYOSD_SELECT|MYOSD_UP); break;

        // MAME MENU
        case KEY_TAB:               myosd_configure = 1; break;
        case KEY_TAB+KEY_DOWN:      break;
            
        // EXIT
        case KEY_ESCAPE:            [emuController runExit]; break;
        case KEY_ESCAPE+KEY_DOWN:   break;
            
        // MAME4iOS MENU
        case KEY_BQUOTE:            [emuController runMenu]; break;
        case KEY_BQUOTE+KEY_DOWN:   break;
    }
    
    // command keys (ALT+ works in the simulator CMD+ does not)
    if (g_keyboard_state[KEY_LCMD] || g_keyboard_state[KEY_RCMD] ||
        g_keyboard_state[KEY_LALT] || g_keyboard_state[KEY_RALT])
    {
        switch (keyCode + (isKeyDown ? KEY_DOWN : 0)) {
            case KEY_RETURN+KEY_DOWN:
                if (g_device_is_landscape)
                    g_pref_full_screen_land = g_pref_full_screen_land_joy = !(g_pref_full_screen_land || g_pref_full_screen_land_joy);
                else
                    g_pref_full_screen_port = g_pref_full_screen_port_joy = !(g_pref_full_screen_port || g_pref_full_screen_port_joy);
                [emuController changeUI];
                return nil;
            case KEY_T+KEY_DOWN:
                if (g_device_is_landscape)
                    g_pref_tv_filter_land = !g_pref_tv_filter_land;
                else
                    g_pref_tv_filter_port = !g_pref_tv_filter_port;
                [emuController changeUI];
                return nil;
            case KEY_S+KEY_DOWN:
                if (g_device_is_landscape)
                    g_pref_scanline_filter_land = !g_pref_scanline_filter_land;
                else
                    g_pref_scanline_filter_port = !g_pref_scanline_filter_port;
                [emuController changeUI];
                return nil;
        }
    }
    
    // 8BitDo
    switch (keyCode + (isKeyDown ? KEY_DOWN : 0)) {
            
        // DPAD
        case KEY_F:            iCadeKey = @"c"; break;
        case KEY_F+KEY_DOWN:   iCadeKey = @"d"; break;
        case KEY_E:            iCadeKey = @"q"; break;
        case KEY_E+KEY_DOWN:   iCadeKey = @"a"; break;
        case KEY_C:            iCadeKey = @"e"; break;
        case KEY_C+KEY_DOWN:   iCadeKey = @"w"; break;
        case KEY_D:            iCadeKey = @"z"; break;
        case KEY_D+KEY_DOWN:   iCadeKey = @"x"; break;

        // A/B/Y/X
        case KEY_G:             iCadeKey = @"p"; break;
        case KEY_G+KEY_DOWN:    iCadeKey = @"k"; break;
        case KEY_J:             iCadeKey = @"g"; break;
        case KEY_J+KEY_DOWN:    iCadeKey = @"o"; break;
        case KEY_I:             iCadeKey = @"m"; break;
        case KEY_I+KEY_DOWN:    iCadeKey = @"i"; break;
        case KEY_H:             iCadeKey = @"v"; break;
        case KEY_H+KEY_DOWN:    iCadeKey = @"l"; break;

        // L1/R1
        case KEY_K:             iCadeKey = @"f"; break;
        case KEY_K+KEY_DOWN:    iCadeKey = @"u"; break;
        case KEY_M:             iCadeKey = @"n"; break;
        case KEY_M+KEY_DOWN:    iCadeKey = @"j"; break;

        // START and SELECT/COIN (Player 1)
        case KEY_O:             iCadeKey = @"r"; break;
        case KEY_O+KEY_DOWN:    iCadeKey = @"h"; break;
        case KEY_N:             iCadeKey = @"t"; break;
        case KEY_N+KEY_DOWN:    iCadeKey = @"y"; break;
    }

    if (iCadeKey != nil) {
        [self iCadeKey:iCadeKey];
    }

    return nil;
}

@end
