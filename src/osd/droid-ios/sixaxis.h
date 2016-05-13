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

#ifndef sixaxis_h
#define sixaxis_h

#if defined(__cplusplus)
extern "C" {
#endif
    
#define SIXAXIS_DBG			0
    
#define SIXAXIS_PI			3.14159265
        
	/* Convert between radians and degrees */
#define SIXAXIS_RAD_TO_DEGREE(r)	((r * 180.0f) / SIXAXIS_PI)
#define SIXAXIS_DEGREE_TO_RAD(d)	(d * (SIXAXIS_PI / 180.0f))
    
#define sixaxis_absf(x)						((x >= 0) ? (x) : (x * -1.0f))
    
#define SIXAXIS_LED_NONE				0x00
#define SIXAXIS_LED_1					0x02
#define SIXAXIS_LED_2					0x04
#define SIXAXIS_LED_3					0x08
#define SIXAXIS_LED_4					0x10
    
#define SIXAXIS_STATE_DEV_FOUND				0x0001
#define SIXAXIS_STATE_HANDSHAKE				0x0002
#define SIXAXIS_STATE_HANDSHAKE_COMPLETE	0x0004
#define SIXAXIS_STATE_CONNECTED				0x0008
    
    //type
#define SIXAXIS_HANDSHAKE				0x00
#define SIXAXIS_SET_REPORT				0x50
#define SIXAXIS_GET_REPORT				0x40
#define SIXAXIS_DATA				    0xA0
    
    //sub type
#define SIXAXIS_RESERVED			0x00
#define SIXAXIS_INPUT				0x01
#define SIXAXIS_OUTPUT				0x02
#define SIXAXIS_FEATURE				0x03
    
    //requests
#define SIXAXIS_FEATURE_F8              0xF8
#define SIXAXIS_FEATURE_F4              0xF4
#define SIXAXIS_FEATURE_F2              0xF2
#define SIXAXIS_FEATURE_EF              0xEF
#define SIXAXIS_OUTPUT_01               0x01
#define SIXAXIS_INPUT_01                0x01
    
    //buttons
#define SIXAXIS_BUTTON_UP       (1 << 0x04)
#define SIXAXIS_BUTTON_DOWN     (1 << 0x06)
#define SIXAXIS_BUTTON_RIGHT    (1 << 0x05)
#define SIXAXIS_BUTTON_LEFT     (1 << 0x07)
    
#define SIXAXIS_BUTTON_TRIANGLE (1 << 0x0c)
#define SIXAXIS_BUTTON_CIRCLE   (1 << 0x0d)
#define SIXAXIS_BUTTON_CROSS    (1 << 0x0e)
#define SIXAXIS_BUTTON_SQUARE   (1 << 0x0f)
    
#define SIXAXIS_BUTTON_SELECT   (1 << 0x00)
#define SIXAXIS_BUTTON_START    (1 << 0x03)
    
#define SIXAXIS_BUTTON_L1       (1 << 0x0a)
#define SIXAXIS_BUTTON_R1       (1 << 0x0b)
#define SIXAXIS_BUTTON_L2       (1 << 0x08)
#define SIXAXIS_BUTTON_R2       (1 << 0x09)
    
#define SIXAXIS_BUTTON_PS       (1 << 0x10)
    
#define SIXAXIS_IS_PRESSED(dev, button)		((sixaxis->buttonstate & button) == button)
    
#define SIXAXIS_ENABLE_STATE(wm, s)		(sixaxis->state |= (s))
#define SIXAXIS_DISABLE_STATE(wm, s)	(sixaxis->state &= ~(s))
#define SIXAXIS_TOGGLE_STATE(wm, s)		((sixaxis->state & (s)) ? SIXAXIS_DISABLE_STATE(sixaxis, s) : SIXAXIS_ENABLE_STATE(sixaxis, s))
#define SIXAXIS_IS_SET(sixaxis, s)		((sixaxis->state & (s)) == (s))
#define SIXAXIS_IS_CONNECTED(wm)		(SIXAXIS_IS_SET(wm, SIXAXIS_STATE_CONNECTED))
    
    typedef struct sxxs_joystick_t {
		float ang;
		float mag;
		float rx, ry;
	} sxxs_joystick_t;
    
    typedef struct sixaxis_t {
        int unid;
        int state;
        struct sxxs_joystick_t ljs;
		struct sxxs_joystick_t rjs;
        unsigned int buttonstate;
    }sixaxis;
    
    int sixaxis_init(void (*sixaxis_notify_connection_callback)(struct sixaxis_t* sixaxis),
                     void (*sixaxis_send_l2cap_callback)(int unid, int interrupt, unsigned char *buf, int len) );
    int sixaxis_handshake(struct sixaxis_t* sixaxis);
    void sixaxis_pressed_buttons(struct sixaxis_t* sixaxis, unsigned char* msg);
    void sixaxis_set_leds(struct sixaxis_t* sixaxis, int leds);
    int sixaxis_handle_data_packet(struct sixaxis_t* sixaxis, uint8_t *packet, uint16_t size);
    
#if defined(__cplusplus)
}
#endif

#endif