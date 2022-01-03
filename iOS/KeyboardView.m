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

#import "KeyboardView.h"
#import "EmulatorController.h"
#import <GameController/GameController.h>
#include "libmame.h"

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

@implementation KeyboardView {
    UIView              *inputView;          //This is to show a fake invisible keyboard
    EmulatorController  *emuController;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    inputView = [[UIView alloc] initWithFrame:CGRectZero];//inputView es variable de instancia que ya elimina el super

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    emuController = EmulatorController.sharedInstance;
    
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
        memset(myosd_keyboard, 0, sizeof(myosd_keyboard));
        myosd_keyboard_changed = 1;
        if (emuController.presentedViewController == nil)
            [self becomeFirstResponder];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canBecomeFocused {
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

- (void)setShowSoftwareKeyboard:(BOOL)showSoftwareKeyboard {
    if (_showSoftwareKeyboard != showSoftwareKeyboard) {
        _showSoftwareKeyboard = showSoftwareKeyboard;
        [self setActive:_active];
        [self reloadInputViews];
    }
}

// the dismiss keyboard key on iPad software keyboard will just call resignFirstResponder
- (BOOL)resignFirstResponder {
    if (emuController.presentingViewController == nil)
        _showSoftwareKeyboard = NO;
    return [super resignFirstResponder];
}

- (UIView*)inputView {
    if (_showSoftwareKeyboard)
        return nil;
    else
        return inputView;
}

#pragma mark handle iCade key

// iCade keys
//        we      yt uf im og
//      aq  dc    hr jn kp lv
//        xz
//
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
    
    if ([emuController controllerUserInteractionEnabled])
        return;
    
    //NSLog(@"%s: %@ (%d)", __FUNCTION__, text.debugDescription, [text characterAtIndex:0]);

    int joy1 = 0;
    int joy2 = 0;
    
    switch (key)
    {
        // joystick up
        case 'w':
            if(STICK4WAY)
            {
                myosd_pad_status &= ~MYOSD_LEFT;
                myosd_pad_status &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY || g_emulation_paused)
                myosd_pad_status |= MYOSD_UP;
            up = 1;
            joy1 = 1;
            break;
        case 'e':
            if(STICK4WAY)
            {
                if(left)myosd_pad_status |= MYOSD_LEFT;
                if(right)myosd_pad_status |= MYOSD_RIGHT;
            }
            myosd_pad_status &= ~MYOSD_UP;
            up = 0;
            joy1 = 1;
            break;
            
            // joystick down
        case 'x':
            if(STICK4WAY)
            {
                myosd_pad_status &= ~MYOSD_LEFT;
                myosd_pad_status &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY || g_emulation_paused)
                myosd_pad_status |= MYOSD_DOWN;
            down = 1;
            joy1 = 1;
            break;
        case 'z':
            if(STICK4WAY)
            {
                if(left)myosd_pad_status |= MYOSD_LEFT;
                if(right)myosd_pad_status |= MYOSD_RIGHT;
            }
            myosd_pad_status &= ~MYOSD_DOWN;
            down = 0;
            joy1 = 1;
            break;
            
            // joystick right
        case 'd':
            if(STICK4WAY)
            {
                myosd_pad_status &= ~MYOSD_UP;
                myosd_pad_status &= ~MYOSD_DOWN;
            }
            myosd_pad_status |= MYOSD_RIGHT;
            right = 1;
            joy1 = 1;
            break;
        case 'c':
            if(STICK4WAY)
            {
                if(up)myosd_pad_status |= MYOSD_UP;
                if(down)myosd_pad_status |= MYOSD_DOWN;
            }
            myosd_pad_status &= ~MYOSD_RIGHT;
            right = 0;
            joy1 = 1;
            break;
            
            // joystick left
        case 'a':
            if(STICK4WAY)
            {
                myosd_pad_status &= ~MYOSD_UP;
                myosd_pad_status &= ~MYOSD_DOWN;
            }
            myosd_pad_status |= MYOSD_LEFT;
            left = 1;
            joy1 = 1;
            break;
        case 'q':
            if(STICK4WAY)
            {
                if(up)myosd_pad_status |= MYOSD_UP;
                if(down)myosd_pad_status |= MYOSD_DOWN;
            }
            myosd_pad_status &= ~MYOSD_LEFT;
            left = 0;
            joy1 = 1;
            break;
            
            // Y / UP (iCade/iCP) or 2P Right(iMpulse)
        case 'i':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_Y;
               joy1 = 1;
            }
            else
            {
               if(STICK4WAY)
               {
                   myosd_pad_status_2 &= ~MYOSD_UP;
                   myosd_pad_status_2 &= ~MYOSD_DOWN;
               }
               myosd_pad_status_2 |= MYOSD_RIGHT;
               right2 = 1;
               joy2 = 1;
            }
            break;
        case 'm':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
                myosd_pad_status &= ~MYOSD_Y;
                joy1 = 1;
            }
            else
            {
                if(STICK4WAY)
                {
                    if(up2)myosd_pad_status_2 |= MYOSD_UP;
                    if(down2)myosd_pad_status_2 |= MYOSD_DOWN;
                }
                myosd_pad_status_2 &= ~MYOSD_RIGHT;
                right2 = 0;
                joy2 = 1;
            }
            break;
            
            // X / DOWN (iCade & iCP) or A / RIGHT (iMpulse)
        case 'l':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_X;
            }
            else
            {
                myosd_pad_status |= MYOSD_A;
            }
            joy1 = 1;
            break;
        case 'v':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status &= ~MYOSD_X;
            }
            else
            {
               myosd_pad_status &= ~MYOSD_A;
            }
            joy1 = 1;
            break;
            
            // A / LEFT (iCade & iCP) or X / DOWN (iMpulse)
        case 'k':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_A;
            }
            else
            {
               myosd_pad_status |= MYOSD_X;
            }
            joy1 = 1;
            break;
        case 'p':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status &= ~MYOSD_A;
            }
            else
            {
               myosd_pad_status &= ~MYOSD_X;
            }
            joy1 = 1;
            break;
            
            // B / RIGHT (iCade & iCP) or Y / UP (iMpulse)
        case 'o':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_B;
            }
            else
            {
               myosd_pad_status |= MYOSD_Y;
            }
            joy1 = 1;
            break;
        case 'g':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status &= ~MYOSD_B;
            }
            else
            {
               myosd_pad_status &= ~MYOSD_Y;
            }
            joy1 = 1;
            break;
            
            // SELECT / COIN (iCade & iCP) or B / RIGHT (iMpulse)
        case 'y': //button down
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_SELECT;
            }
            else
            {
               myosd_pad_status |= MYOSD_B;
            }
            joy1 = 1;
            break;
        case 't': //button up
            
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status &= ~MYOSD_SELECT;
            }
            else
            {
               myosd_pad_status &= ~MYOSD_B;
            }
            joy1 = 1;
            break;
            
            //L1(iCade) or START (iCP) or 2P LEFT(iMpulse)
        case 'u':   //button down
            if (g_pref_ext_control_type == EXT_CONTROL_ICP) {
                myosd_pad_status |= MYOSD_START;
                joy1 = 1;
            }
            else if (g_pref_ext_control_type == EXT_CONTROL_IMPULSE) {
                if(STICK4WAY)
                {
                    myosd_pad_status_2 &= ~MYOSD_UP;
                    myosd_pad_status_2 &= ~MYOSD_DOWN;
                }
                myosd_pad_status_2 |= MYOSD_LEFT;
                left2 = 1;
                joy2 = 1;
            }
            else {
                myosd_pad_status |= MYOSD_L1;
                joy1 = 1;
            }

            break;
        case 'f':   //button up
            if (g_pref_ext_control_type == EXT_CONTROL_ICP) {
                myosd_pad_status &= ~MYOSD_START;
                joy1 = 1;
            }
            else if (g_pref_ext_control_type == EXT_CONTROL_IMPULSE) {
                if(STICK4WAY)
                {
                    if(up2)myosd_pad_status_2 |= MYOSD_UP;
                    if(down2)myosd_pad_status_2 |= MYOSD_DOWN;
                }
                myosd_pad_status_2 &= ~MYOSD_LEFT;
                left2 = 0;
                joy2 = 1;
            }
            else {
                myosd_pad_status &= ~MYOSD_L1;
                joy1 = 1;
            }

            break;
            
            //Start(iCade) or L1(iCP) or Coin / Select(iMpulse)
        case 'h':   //button down
            if(g_pref_ext_control_type == EXT_CONTROL_ICP) {
                myosd_pad_status |= MYOSD_L1;
            }
            else if (g_pref_ext_control_type == EXT_CONTROL_IMPULSE)
            {
                myosd_pad_status |= MYOSD_SELECT;
            }
            else {
                myosd_pad_status |= MYOSD_START;
            }
            joy1 = 1;
            break;
        case 'r':   //button up
            if (g_pref_ext_control_type == EXT_CONTROL_ICP) {
                myosd_pad_status &= ~MYOSD_L1;
            }
            else if (g_pref_ext_control_type == EXT_CONTROL_IMPULSE)
            {
                myosd_pad_status &= ~MYOSD_SELECT;
            }
            else {
                myosd_pad_status &= ~MYOSD_START;
            }
            joy1 = 1;
            break;
            
            // R1 (iCade & iCP) or Start (iMpulse)
        case 'j':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status |= MYOSD_R1;
            }
            else
            {
               myosd_pad_status |= MYOSD_START;
            }
            joy1 = 1;
            break;
        case 'n':
            if(g_pref_ext_control_type != EXT_CONTROL_IMPULSE)
            {
               myosd_pad_status &= ~MYOSD_R1;
            }
            else
            {
               myosd_pad_status &= ~MYOSD_START;
            }
            joy1 = 1;
            break;
            
       ////////////
    
            // 2p joystick up
        case '[':
            if(STICK4WAY)
            {
                myosd_pad_status_2 &= ~MYOSD_LEFT;
                myosd_pad_status_2 &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY || g_emulation_paused)
                myosd_pad_status_2 |= MYOSD_UP;
            up2 = 1;
            joy2 = 1;
            break;
        case ']':
            if(STICK4WAY)
            {
                if(left)myosd_pad_status_2 |= MYOSD_LEFT;
                if(right)myosd_pad_status_2 |= MYOSD_RIGHT;
            }
            myosd_pad_status_2 &= ~MYOSD_UP;
            up2 = 0;
            joy2 = 1;
            break;
            
            //2p joystick down
        case 's':
            if(STICK4WAY)
            {
                myosd_pad_status_2 &= ~MYOSD_LEFT;
                myosd_pad_status_2 &= ~MYOSD_RIGHT;
            }
            if(!STICK2WAY || g_emulation_paused)
                myosd_pad_status_2 |= MYOSD_DOWN;
            down2 = 1;
            joy2 = 1;
            break;
        case 'b':
            if(STICK4WAY)
            {
                if(left)myosd_pad_status_2 |= MYOSD_LEFT;
                if(right)myosd_pad_status_2 |= MYOSD_RIGHT;
            }
            myosd_pad_status_2 &= ~MYOSD_DOWN;
            down2 = 0;
            joy2 = 1;
            break;
            
            // B / RIGHT
        case '3':
            myosd_pad_status_2 |= MYOSD_B;
            joy2 = 1;
            break;
        case '4':
            myosd_pad_status_2 &= ~MYOSD_B;
            joy2 = 1;
            break;
            
            // X / DOWN
        case '1':
            myosd_pad_status_2 |= MYOSD_X;
            joy2 = 1;
            break;
        case '2':
            myosd_pad_status_2 &= ~MYOSD_X;
            joy2 = 1;
            break;
            
            // A / LEFT
        case '5':
            myosd_pad_status_2 |= MYOSD_A;
            joy2 = 1;
            break;
        case '6':
            myosd_pad_status_2 &= ~MYOSD_A;
            joy2 = 1;
            break;
            
            //Y / UP
        case '7':
            myosd_pad_status_2 |= MYOSD_Y;
            joy2 = 1;
            break;
        case '8':
            myosd_pad_status_2 &= ~MYOSD_Y;
            joy2 = 1;
            break;
            
            // SELECT / COIN
        case '9': //button down
            myosd_pad_status_2 |= MYOSD_SELECT;
            joy2 = 1;
            break;
        case '0': //button up
            myosd_pad_status_2 &= ~MYOSD_SELECT;
            joy2 = 1;
            break;
            
            //START
        case '-':   //button down
            myosd_pad_status_2 |= MYOSD_START;
            joy2 = 1;
            break;
        case '=':   //button up
            myosd_pad_status_2 &= ~MYOSD_START;
            joy2 = 1;
            break;
            
        ///////////
            
    }
    
    // emulate a analog joystick too.
    myosd_pad_x = (myosd_pad_status & MYOSD_UP)    ? +1.0 : (myosd_pad_status & MYOSD_DOWN) ? -1.0 : 0.0;
    myosd_pad_y = (myosd_pad_status & MYOSD_RIGHT) ? +1.0 : (myosd_pad_status & MYOSD_LEFT) ? -1.0 : 0.0;

    // only treat iCade as a controler when DPAD used for first time.
    if (g_joy_used == 0 && (myosd_pad_status & (MYOSD_DOWN|MYOSD_UP|MYOSD_RIGHT|MYOSD_LEFT)))
    {
        g_joy_used = 1;
        [emuController changeUI];
    }
    if (!(g_device_is_fullscreen && g_joy_used) || emuController.presentedViewController != nil)
        [emuController handle_INPUT:myosd_pad_status stick:CGPointMake(myosd_pad_x, myosd_pad_y)];
}

#pragma mark Hardare Keyboard

// map a HID key (UIKeyboardHIDUsageKeyboardA) to a MAME KEY (MYOSD_KEY_A)
int hid_to_mame(int keyCode) {

    static int mame_map[256];
    
    if (mame_map[4 /*UIKeyboardHIDUsageKeyboardA*/] == 0) {
#ifdef __IPHONE_13_4
        /* A-Z */
        for (int i=0; i<26; i++)
            mame_map[UIKeyboardHIDUsageKeyboardA+i] = MYOSD_KEY_A+i;
        
        /* 0-9 */
        mame_map[UIKeyboardHIDUsageKeyboard0] = MYOSD_KEY_0;
        for (int i=0; i<9; i++)
            mame_map[UIKeyboardHIDUsageKeyboard1+i] = MYOSD_KEY_1+i;

        /* F1-F15 */
        for (int i=0; i<12; i++)
            mame_map[UIKeyboardHIDUsageKeyboardF1+i] = MYOSD_KEY_F1+i;
        mame_map[UIKeyboardHIDUsageKeyboardF13] = MYOSD_KEY_F13;
        mame_map[UIKeyboardHIDUsageKeyboardF14] = MYOSD_KEY_F14;
        mame_map[UIKeyboardHIDUsageKeyboardF15] = MYOSD_KEY_F15;
        
        /* special keys */
        mame_map[UIKeyboardHIDUsageKeyboardReturnOrEnter    ] = MYOSD_KEY_ENTER;
        mame_map[UIKeyboardHIDUsageKeyboardEscape           ] = MYOSD_KEY_ESC;
        mame_map[UIKeyboardHIDUsageKeyboardDeleteOrBackspace] = MYOSD_KEY_BACKSPACE;
        mame_map[UIKeyboardHIDUsageKeyboardTab              ] = MYOSD_KEY_TAB;
        mame_map[UIKeyboardHIDUsageKeyboardSpacebar         ] = MYOSD_KEY_SPACE;
        mame_map[UIKeyboardHIDUsageKeyboardHyphen           ] = MYOSD_KEY_MINUS;
        mame_map[UIKeyboardHIDUsageKeyboardEqualSign        ] = MYOSD_KEY_EQUALS;
        mame_map[UIKeyboardHIDUsageKeyboardOpenBracket      ] = MYOSD_KEY_OPENBRACE;
        mame_map[UIKeyboardHIDUsageKeyboardCloseBracket     ] = MYOSD_KEY_CLOSEBRACE;
        mame_map[UIKeyboardHIDUsageKeyboardBackslash        ] = MYOSD_KEY_BACKSLASH;
        mame_map[UIKeyboardHIDUsageKeyboardNonUSPound       ] = MYOSD_KEY_BACKSLASH2;   // TODO: check
        mame_map[UIKeyboardHIDUsageKeyboardSemicolon        ] = MYOSD_KEY_COLON;
        mame_map[UIKeyboardHIDUsageKeyboardQuote            ] = MYOSD_KEY_QUOTE;
        mame_map[UIKeyboardHIDUsageKeyboardGraveAccentAndTilde] = MYOSD_KEY_TILDE;
        mame_map[UIKeyboardHIDUsageKeyboardComma            ] = MYOSD_KEY_COMMA;
        mame_map[UIKeyboardHIDUsageKeyboardPeriod           ] = MYOSD_KEY_STOP;
        mame_map[UIKeyboardHIDUsageKeyboardSlash            ] = MYOSD_KEY_SLASH;
        mame_map[UIKeyboardHIDUsageKeyboardCapsLock         ] = MYOSD_KEY_CAPSLOCK;
        mame_map[UIKeyboardHIDUsageKeyboardNonUSBackslash   ] = MYOSD_KEY_BACKSLASH2;   // TODO: check

        mame_map[UIKeyboardHIDUsageKeyboardPrintScreen  ] = MYOSD_KEY_PRTSCR;
        mame_map[UIKeyboardHIDUsageKeyboardScrollLock   ] = MYOSD_KEY_SCRLOCK;
        mame_map[UIKeyboardHIDUsageKeyboardPause        ] = MYOSD_KEY_PAUSE;
        mame_map[UIKeyboardHIDUsageKeyboardInsert       ] = MYOSD_KEY_INSERT;
        mame_map[UIKeyboardHIDUsageKeyboardHome         ] = MYOSD_KEY_HOME;
        mame_map[UIKeyboardHIDUsageKeyboardPageUp       ] = MYOSD_KEY_PGUP;
        mame_map[UIKeyboardHIDUsageKeyboardDeleteForward] = MYOSD_KEY_DEL;              // TODO: check
        mame_map[UIKeyboardHIDUsageKeyboardEnd          ] = MYOSD_KEY_END;
        mame_map[UIKeyboardHIDUsageKeyboardPageDown     ] = MYOSD_KEY_PGDN;
        mame_map[UIKeyboardHIDUsageKeyboardRightArrow   ] = MYOSD_KEY_RIGHT;
        mame_map[UIKeyboardHIDUsageKeyboardLeftArrow    ] = MYOSD_KEY_LEFT;
        mame_map[UIKeyboardHIDUsageKeyboardDownArrow    ] = MYOSD_KEY_DOWN;
        mame_map[UIKeyboardHIDUsageKeyboardUpArrow      ] = MYOSD_KEY_UP;
        
        /* modifier keys */
        mame_map[UIKeyboardHIDUsageKeyboardLeftControl  ] = MYOSD_KEY_LCONTROL;
        mame_map[UIKeyboardHIDUsageKeyboardLeftShift    ] = MYOSD_KEY_LSHIFT;
        mame_map[UIKeyboardHIDUsageKeyboardLeftAlt      ] = MYOSD_KEY_LALT;
        mame_map[UIKeyboardHIDUsageKeyboardRightControl ] = MYOSD_KEY_RCONTROL;
        mame_map[UIKeyboardHIDUsageKeyboardRightShift   ] = MYOSD_KEY_RSHIFT;
        mame_map[UIKeyboardHIDUsageKeyboardRightAlt     ] = MYOSD_KEY_RALT;

        /* command keys */
        // dont let MAME have access to the ⌘ key, we (and macOS, and iOS) want to use it.
        // mame_map[UIKeyboardHIDUsageKeyboardLeftGUI] = MYOSD_KEY_LCMD;
        // mame_map[UIKeyboardHIDUsageKeyboardRightGUI] = MYOSD_KEY_RCMD;

        /* Keypad (numpad) keys */
        mame_map[UIKeyboardHIDUsageKeypadNumLock         ] = MYOSD_KEY_NUMLOCK;
        mame_map[UIKeyboardHIDUsageKeypadSlash           ] = MYOSD_KEY_SLASH;
        mame_map[UIKeyboardHIDUsageKeypadAsterisk        ] = MYOSD_KEY_ASTERISK;
        mame_map[UIKeyboardHIDUsageKeypadHyphen          ] = MYOSD_KEY_MINUS_PAD;
        mame_map[UIKeyboardHIDUsageKeypadPlus            ] = MYOSD_KEY_PLUS_PAD;
        mame_map[UIKeyboardHIDUsageKeypadEnter           ] = MYOSD_KEY_ENTER_PAD;
        mame_map[UIKeyboardHIDUsageKeypad1               ] = MYOSD_KEY_1_PAD;
        mame_map[UIKeyboardHIDUsageKeypad2               ] = MYOSD_KEY_2_PAD;
        mame_map[UIKeyboardHIDUsageKeypad3               ] = MYOSD_KEY_3_PAD;
        mame_map[UIKeyboardHIDUsageKeypad4               ] = MYOSD_KEY_4_PAD;
        mame_map[UIKeyboardHIDUsageKeypad5               ] = MYOSD_KEY_5_PAD;
        mame_map[UIKeyboardHIDUsageKeypad6               ] = MYOSD_KEY_6_PAD;
        mame_map[UIKeyboardHIDUsageKeypad7               ] = MYOSD_KEY_7_PAD;
        mame_map[UIKeyboardHIDUsageKeypad8               ] = MYOSD_KEY_8_PAD;
        mame_map[UIKeyboardHIDUsageKeypad9               ] = MYOSD_KEY_9_PAD;
        mame_map[UIKeyboardHIDUsageKeypad0               ] = MYOSD_KEY_0_PAD;
        mame_map[UIKeyboardHIDUsageKeypadPeriod          ] = MYOSD_KEY_STOP;
        mame_map[UIKeyboardHIDUsageKeypadEqualSign       ] = MYOSD_KEY_EQUALS;

#else   // provide a minimal set of keys for Xcode < 11.4
        
        for (int i=0; i<26; i++)
            mame_map[4+i] = MYOSD_KEY_A+i;
        
        for (int i=0; i<9; i++)
            mame_map[30+i] = MYOSD_KEY_1+i;
        
        for (int i=0; i<12; i++)
            mame_map[58+i] = MYOSD_KEY_F1+i;

        mame_map[39] = MYOSD_KEY_0;
        mame_map[40] = MYOSD_KEY_ENTER;
        mame_map[41] = MYOSD_KEY_ESC;
        mame_map[42] = MYOSD_KEY_BACKSPACE;
        mame_map[43] = MYOSD_KEY_TAB;
        mame_map[44] = MYOSD_KEY_SPACE;

        mame_map[224] = MYOSD_KEY_LCONTROL;
        mame_map[225] = MYOSD_KEY_LSHIFT;
        mame_map[226] = MYOSD_KEY_LALT;
        
        mame_map[79] = MYOSD_KEY_RIGHT;
        mame_map[80] = MYOSD_KEY_LEFT;
        mame_map[81] = MYOSD_KEY_DOWN;
        mame_map[82] = MYOSD_KEY_UP;
#endif
    }

    if (keyCode >= 0 && keyCode < 256)
        return mame_map[keyCode];
    else
        return 0;
}

//
// HARDWARE KEYBOARD
//
// handle input from a hardware keyboard, the following are examples hardware keyboards.
//
//      * a USB or Bluetooth keyboard connected to a iOS device or AppleTV
//      * Apple - Smart Keyboard connected to an iPad
//      * macOS keyboard when debugging in Xcode simulator
//
-(void)hardwareKey:(NSString*)key keyCode:(int)keyCode isKeyDown:(BOOL)isKeyDown modifierFlags:(UIKeyModifierFlags)modifierFlags {
    
#ifdef __IPHONE_13_4
    // CMD+. will send an ESC key like this. (used on the iPad magic keyboard with no real Escape key)
    if (key == UIKeyInputEscape)
        keyCode = UIKeyboardHIDUsageKeyboardEscape;
#endif
    
    NSLog(@"hardwareKey: %s%s%s%s%@ (%d) %s",
          (modifierFlags & UIKeyModifierShift)     ? "SHIFT+" : "",
          (modifierFlags & UIKeyModifierAlternate) ? "ALT+" : "",
          (modifierFlags & UIKeyModifierControl)   ? "CONTROL+" : "",
          (modifierFlags & UIKeyModifierCommand)   ? "CMD+" : "",
          [key.debugDescription stringByReplacingOccurrencesOfString:@"\r" withString:@"⏎"],
          keyCode, isKeyDown ? "DOWN" : "UP");
    
    // iCade (or compatible...)
    if (g_pref_ext_control_type != EXT_CONTROL_NONE)
    {
        if (isKeyDown && modifierFlags == 0)
            [self iCadeKey:key];

        return;
    }
    
    // TODO: convert HID code for international keyboards
    int mame_key = hid_to_mame(keyCode);
    
    if (mame_key == 0)
        return NSLog(@"....UNABLE TO CONVERT %@ (%d) TO MAME KEY", key.debugDescription, keyCode);
    
    // handle special keys without sending to MAME.

    // CMD+x special command key (ALT+ works in the simulator CMD+ does not)
    if (modifierFlags == (TARGET_OS_SIMULATOR ? UIKeyModifierAlternate : UIKeyModifierCommand))
    {
        // CMD+DELETE => SCRLOCK (aka UIMODE)
        if (mame_key == MYOSD_KEY_BACKSPACE)
            mame_key = MYOSD_KEY_SCRLOCK;
        if (isKeyDown && mame_key == MYOSD_KEY_ENTER)
            return [emuController commandKey:'\r'];
        if (isKeyDown && mame_key >= MYOSD_KEY_A && mame_key <= MYOSD_KEY_Z)
            return [emuController commandKey:'A' + (mame_key - MYOSD_KEY_A)];
        if (isKeyDown && mame_key >= MYOSD_KEY_0 && mame_key <= MYOSD_KEY_9)
            return [emuController commandKey:'0' + (mame_key - MYOSD_KEY_0)];
    }
    
    // handle ESC key without sending to MAME, so we can present UI
    // TODO: handle ESC different for machines that use direct keyboard
    if (mame_key == MYOSD_KEY_ESC && isKeyDown)
        return [emuController runExit];
    
    // dont let ALT+TAB or CMD+TAB get down to MAME, let the system have it.
    if (mame_key == MYOSD_KEY_TAB && modifierFlags != 0)
        return;

    // send the key to MAME via myosd_keyboard
    myosd_keyboard[mame_key] = isKeyDown ? 0x80 : 0x00;
    myosd_keyboard_changed = 1;

    // only treat as a controler when arrow keys used for first time.
    if (g_joy_used == 0 && (mame_key >= MYOSD_KEY_LEFT && mame_key <= MYOSD_KEY_DOWN))
    {
        g_joy_used = 1;
        [emuController changeUI];
    }
    
    if (!(g_device_is_fullscreen && g_joy_used) || emuController.presentedViewController != nil) {
        unsigned long kbd_status =
            (myosd_keyboard[MYOSD_KEY_ENTER]    ? MYOSD_A : 0)    | (myosd_keyboard[MYOSD_KEY_ESC]   ? MYOSD_B : 0) |
            (myosd_keyboard[MYOSD_KEY_LCONTROL] ? MYOSD_A : 0)    | (myosd_keyboard[MYOSD_KEY_LALT]  ? MYOSD_B : 0) |
            (myosd_keyboard[MYOSD_KEY_LSHIFT]   ? MYOSD_X : 0)    | (myosd_keyboard[MYOSD_KEY_SPACE] ? MYOSD_Y : 0) |
            (myosd_keyboard[MYOSD_KEY_Z]        ? MYOSD_L1 : 0)   | (myosd_keyboard[MYOSD_KEY_X]     ? MYOSD_R1 : 0) |
            (myosd_keyboard[MYOSD_KEY_LEFT]     ? MYOSD_LEFT : 0) | (myosd_keyboard[MYOSD_KEY_RIGHT] ? MYOSD_RIGHT : 0) |
            (myosd_keyboard[MYOSD_KEY_UP]       ? MYOSD_UP : 0)   | (myosd_keyboard[MYOSD_KEY_DOWN]  ? MYOSD_DOWN : 0) ;

        [emuController handle_INPUT:kbd_status stick:CGPointZero];
    }
}

// get keyboad input on macOS or iOS 13.4+
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
#ifdef __IPHONE_13_4
    if (@available(iOS 13.4, tvOS 13.4, *)) {
        for (UIPress* press in presses) {
            if (press.key != nil) {
                return [self hardwareKey:press.key.charactersIgnoringModifiers keyCode:(int)press.key.keyCode isKeyDown:TRUE modifierFlags:press.key.modifierFlags];
            }
        }
    }
#endif
    [super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
#ifdef __IPHONE_13_4
    if (@available(iOS 13.4, tvOS 13.4, *)) {
        for (UIPress* press in presses) {
            if (press.key != nil) {
                return [self hardwareKey:press.key.charactersIgnoringModifiers keyCode:(int)press.key.keyCode isKeyDown:FALSE modifierFlags:press.key.modifierFlags];
            }
        }
    }
#endif
    [super pressesEnded:presses withEvent:event];
}

// _keyCommandForEvent is *not* needed at all for iOS 13.4 or higher
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 130400 

// Overloaded _keyCommandForEvent (UIResponder.h) // Only exists in iOS 9+
-(UIKeyCommand *)_keyCommandForEvent:(UIEvent *)event { // UIPhysicalKeyboardEvent
    
#ifdef __IPHONE_13_4
    // on iOS 13.4 or higher, do nothing we will handle hardware keyboards in pressesBegan/pressesEnded
    if (@available(iOS 13.4, tvOS 13.4, *)) {
        return nil;
    }
#endif
    
    // This gets called twice with the same timestamp, so filter out duplicate event
    static NSTimeInterval last_time_stamp;
    if (last_time_stamp == event.timestamp)
        return nil;
    last_time_stamp = event.timestamp;
    
    int keyCode = [[event valueForKey:@"_keyCode"] intValue];
    BOOL isKeyDown = [[event valueForKey:@"_isKeyDown"] boolValue];
    int modifierFlags = [[event valueForKey:@"_modifierFlags"] intValue];
    NSString* key = [event valueForKey:@"_unmodifiedInput"];

    if (keyCode > 0 && keyCode <= 255)
        [self hardwareKey:key keyCode:keyCode isKeyDown:isKeyDown modifierFlags:modifierFlags];
    
    return nil;
}

#endif

#pragma mark Software Keyboard

#if (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)

- (BOOL)conformsToProtocol:(Protocol *)protocol {
    //NSLog(@"conformsToProtocol: %@ ==> %@", NSStringFromProtocol(protocol), [super conformsToProtocol:protocol] ? @"YES" : @"NO");
    // NOTE it is very important not to support UIKeyInput when running on macOS, otherwise pressesBegan/End does not get called.
    if (NSProtocolFromString(@"UIKeyInput") == protocol)
        return IsRunningOnMac() ? FALSE : TRUE;
    return [super conformsToProtocol:protocol];
}

- (BOOL) hasText {
    return YES;
}
- (void)insertText:(NSString *)text {
    NSLog(@"insertText: %@", text);
    int mame_key = ascii_to_mame([text characterAtIndex:0]);
    if (mame_key != 0)
        send_mame_key(mame_key);
}
- (void)deleteBackward {
    send_mame_key(MYOSD_KEY_BACKSPACE);
}

- (UIKeyboardAppearance)keyboardAppearance {
    return UIKeyboardAppearanceDark;
}

-(UIKeyboardType)keyboardType {
    return UIKeyboardTypeASCIICapable;
}

// map a ASCII key to a MAME KEY
static int ascii_to_mame(int key) {

    static int mame_map[128];
    
    if (mame_map['A'] == 0) {
        /* a-z */
        for (int i=0; i<26; i++)
            mame_map['a'+i] = MYOSD_KEY_A+i;
        
        /* A-Z */
        for (int i=0; i<26; i++)
            mame_map['A'+i] = MYOSD_KEY_A+i + (MYOSD_KEY_LSHIFT<<8);
        
        /* 0-9 */
        for (int i=0; i<10; i++)
            mame_map['0'+i] = MYOSD_KEY_0+i;

        mame_map['!'] = MYOSD_KEY_1 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['@'] = MYOSD_KEY_2 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['#'] = MYOSD_KEY_3 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['$'] = MYOSD_KEY_4 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['%'] = MYOSD_KEY_5 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['^'] = MYOSD_KEY_6 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['&'] = MYOSD_KEY_7 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['*'] = MYOSD_KEY_8 + (MYOSD_KEY_LSHIFT<<8);
        mame_map['('] = MYOSD_KEY_9 + (MYOSD_KEY_LSHIFT<<8);
        mame_map[')'] = MYOSD_KEY_0 + (MYOSD_KEY_LSHIFT<<8);

        /* special keys */
        mame_map['\r'] = MYOSD_KEY_ENTER;
        mame_map['\n'] = MYOSD_KEY_ENTER;
        mame_map[' '] = MYOSD_KEY_SPACE;
        mame_map['\t'] = MYOSD_KEY_TAB;
        
        mame_map['`'] = MYOSD_KEY_TILDE;
        mame_map['~'] = MYOSD_KEY_TILDE + (MYOSD_KEY_LSHIFT<<8);

        mame_map['-'] = MYOSD_KEY_MINUS;
        mame_map['='] = MYOSD_KEY_EQUALS;
        mame_map['_'] = MYOSD_KEY_MINUS + (MYOSD_KEY_LSHIFT<<8);
        mame_map['+'] = MYOSD_KEY_EQUALS + (MYOSD_KEY_LSHIFT<<8);

        mame_map[','] = MYOSD_KEY_COMMA;
        mame_map['.'] = MYOSD_KEY_STOP;
        mame_map['/'] = MYOSD_KEY_SLASH;
        mame_map['<'] = MYOSD_KEY_COMMA + (MYOSD_KEY_LSHIFT<<8);
        mame_map['>'] = MYOSD_KEY_STOP + (MYOSD_KEY_LSHIFT<<8);
        mame_map['?'] = MYOSD_KEY_SLASH + (MYOSD_KEY_LSHIFT<<8);

        mame_map[';'] = MYOSD_KEY_COLON;
        mame_map['\''] = MYOSD_KEY_QUOTE;
        mame_map[':'] = MYOSD_KEY_COLON + (MYOSD_KEY_LSHIFT<<8);
        mame_map['"'] = MYOSD_KEY_QUOTE + (MYOSD_KEY_LSHIFT<<8);

        mame_map['['] = MYOSD_KEY_OPENBRACE;
        mame_map[']'] = MYOSD_KEY_CLOSEBRACE;
        mame_map['\\'] = MYOSD_KEY_BACKSLASH;
        mame_map['{'] = MYOSD_KEY_OPENBRACE + (MYOSD_KEY_LSHIFT<<8);
        mame_map['}'] = MYOSD_KEY_CLOSEBRACE + (MYOSD_KEY_LSHIFT<<8);
        mame_map['|'] = MYOSD_KEY_BACKSLASH + (MYOSD_KEY_LSHIFT<<8);
    }

    if (key >= 0 && key < 128)
        return mame_map[key];
    else
        return 0;
}

static void send_mame_key(int key) {

    // send the key(s) to MAME via myosd_keyboard
    myosd_keyboard[key & 0xFF] = 0x80;
    if ((key & 0xFF00) != 0)
        myosd_keyboard[(key >> 8) & 0xFF] = 0x80;
    myosd_keyboard_changed = 1;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.100 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        myosd_keyboard[key & 0xFF] = 0x00;
        if ((key & 0xFF00) != 0)
            myosd_keyboard[(key >> 8) & 0xFF] = 0x00;
        myosd_keyboard_changed = 1;
    });
}

- (void)mameKeyDown:(UIButton*)sender {
    NSLog(@"KEY DOWN: %d", (int)sender.tag);
    int key = (int)sender.tag;
    sender.backgroundColor = UIColor.systemGrayColor;
    myosd_keyboard[key] = 0x80;
    myosd_keyboard_changed = 1;
}
- (void)mameKeyUp:(UIButton*)sender API_AVAILABLE(ios(14.0)) {
    NSLog(@"KEY UP: %d", (int)sender.tag);
    int key = (int)sender.tag;
    sender.backgroundColor = UIColor.systemGray5Color;
    myosd_keyboard[key] = 0x00;
    myosd_keyboard_changed = 1;
    if (key == MYOSD_KEY_MENU)
        [emuController runMenu:sender];
}

- (UIBarButtonItem*)mameKey:(NSString*)str code:(int)mame_key  API_AVAILABLE(ios(14.0)) {
    UIImage* image = [[UIImage systemImageNamed:str] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (image != nil)
        [btn setImage:image forState:UIControlStateNormal];
    else
        [btn setTitle:str forState:UIControlStateNormal];
    btn.contentEdgeInsets = UIEdgeInsetsMake(6, 5, 6, 5);
    btn.layer.cornerRadius = 4;
    btn.backgroundColor = UIColor.systemGray5Color;
    btn.tintColor = UIColor.whiteColor;
    btn.tag = mame_key;
    [btn addTarget:self action:@selector(mameKeyDown:) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(mameKeyUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [btn sizeToFit];
    return [[UIBarButtonItem alloc] initWithCustomView:btn];
}
- (UIBarButtonItem*)flexibleSpaceItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}
- (UIBarButtonItem*)fixedSpaceItemOfWidth:(CGFloat)width {
    UIBarButtonItem* fix = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fix.width = width;
    return fix;
}

- (UIView*)inputAccessoryView {
    
#ifdef __IPHONE_14_0
    // we only want to create/use an accessory view if we are *sure* there is no hardware keyboard attached....
    if (@available(iOS 14.0, *)) {
        BOOL isKeyboardAttached = GCKeyboard.coalescedKeyboard != nil;
        
        if (_showSoftwareKeyboard && !isKeyboardAttached)
            return [self makeKeyboardToolbar];
    }
#endif
    
    return nil;
}

- (UIToolbar*)makeKeyboardToolbar API_AVAILABLE(ios(14.0)) {
    
    static UIToolbar* toolbar = nil;

    if (toolbar == nil) {
        NSMutableArray* items = [[NSMutableArray alloc] init];

        BOOL iPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;

#define Fix() [self fixedSpaceItemOfWidth:2.0]
#define Sep() [self flexibleSpaceItem]
#define Key(str, key) [self mameKey:str code:key]
        
        if (iPad) {
            /* ESC, SHIFT, CONTROL, and ALT */
            [items addObjectsFromArray:@[
                Key(@"ESC", MYOSD_KEY_ESC),
                Fix(), Key(@"shift", MYOSD_KEY_LSHIFT),
                Fix(), Key(@"control", MYOSD_KEY_LCONTROL),
                Fix(), Key(@"option", MYOSD_KEY_LALT),
            ]];
        }
        else {
            /* TAB, SHIFT, CONTROL */
            [items addObjectsFromArray:@[
                Key(@"escape", MYOSD_KEY_ESC),
                Fix(), Key(@"arrow.right.to.line", MYOSD_KEY_TAB),
                Fix(), Key(@"shift", MYOSD_KEY_LSHIFT),
                Fix(), Key(@"control", MYOSD_KEY_LCONTROL),
            ]];
        }

        /* F1 - F12 */
        if (iPad) {
            for (int i=0; i<12; i++) {
                [items addObject:i==0 ? Sep() : Fix()];
                [items addObject:Key(([NSString stringWithFormat:@"F%d", i+1]), MYOSD_KEY_F1+i)];
            }
        }
        
        /* arrow keys */
        [items addObjectsFromArray:@[
            Sep(), Key(@"arrow.up", MYOSD_KEY_UP),
            Fix(), Key(@"arrow.left", MYOSD_KEY_LEFT),
            Fix(), Key(@"arrow.right", MYOSD_KEY_RIGHT),
            Fix(), Key(@"arrow.down", MYOSD_KEY_DOWN),
        ]];

        /* srrlock and menu */
        [items addObjectsFromArray:@[
            Sep(), Key(@"lock", MYOSD_KEY_SCRLOCK),
            Fix(), Key(@"list.dash", MYOSD_KEY_MENU),
        ]];

        toolbar = [[UIToolbar alloc] init];
        toolbar.items = items;
        [toolbar sizeToFit];
    }
    return toolbar;
}

#endif // (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)

@end
