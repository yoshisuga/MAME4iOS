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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include "sixaxis.h"

static void (*sixaxis_notify_connection)(struct sixaxis_t* sixaxis) = NULL;
static void (*sixaxis_send_l2cap)(int unid, int interrupt, unsigned char *buf, int len) = NULL;

static void sixaxis_calc_joystick_state(struct sxxs_joystick_t* js, float x, float y);

int sixaxis_init(void (*sixaxis_notify_connection_callback)(struct sixaxis_t* sixaxis),
                 void (*sixaxis_send_l2cap_callback)(int unid, int interrupt, unsigned char *buf, int len) ){
    sixaxis_notify_connection = sixaxis_notify_connection_callback;
    sixaxis_send_l2cap = sixaxis_send_l2cap_callback;
    return 1;
}

void sixaxis_pressed_buttons(struct sixaxis_t* sixaxis, unsigned char* msg){
    
    float lx,ly,rx,ry;
    
    if(sixaxis==NULL || !SIXAXIS_IS_CONNECTED(sixaxis))
        return;
    
    if(!SIXAXIS_IS_SET(sixaxis, SIXAXIS_STATE_HANDSHAKE_COMPLETE))
        return;
    
    sixaxis->buttonstate = msg [3] | (msg[4] << 8) | (msg[5] << 16) ;
    
    lx = (msg[7] - 128.0f) / 128.0f;
    ly = ((msg[8] - 128.0f) / 128.0f) * -1;
    rx = (msg[9] - 128.0f) / 128.0f;
    ry = ((msg[10] - 128.0f) / 128.0f) * -1;
    
    sixaxis_calc_joystick_state(&sixaxis->ljs, lx, ly);
    
	sixaxis_calc_joystick_state(&sixaxis->rjs, rx, ry);
    
    //printf(" %.2f %.2f\n",sixaxis->ljs.ang, sixaxis->ljs.mag);

    //printf(" %f %f %f %f\n",sixaxis->ljs.ang, sixaxis->ljs.mag, sixaxis->rjs.ang, sixaxis->rjs.mag);
    
    if(SIXAXIS_DBG)
    {
        int buttonstate = sixaxis->buttonstate;
        unsigned char *psdata_buffer = msg;
        printf("U:%d D:%d R:%d L:%d B1:%d B2:%d B3:%d b4:%d sl:%d st:%d l1:%d r1:%d l2:%d r2:%d PS:%d [LX:%d LY:%d RX:%d RY:%d]\n",
               (buttonstate & (1 << 0x04)) != 0,
               (buttonstate & (1 << 0x06)) != 0,
               (buttonstate & (1 << 0x05)) != 0,
               (buttonstate & (1 << 0x07)) != 0 ,
               
               (buttonstate & (1 << 0x0c)) != 0,
               (buttonstate & (1 << 0x0d)) != 0,
               (buttonstate & (1 << 0x0e)) != 0,
               (buttonstate & (1 << 0x0f)) != 0,
               
               (buttonstate & (1 << 0x00)) != 0,
               (buttonstate & (1 << 0x03)) != 0,
               (buttonstate & (1 << 0x0a)) != 0,
               (buttonstate & (1 << 0x0b)) != 0 ,
               (buttonstate & (1 << 0x08)) != 0,
               (buttonstate & (1 << 0x09)) != 0,
               
               (buttonstate & (1 << 16)) != 0,
               
               psdata_buffer[7],
               psdata_buffer[8],
               psdata_buffer[9],
               psdata_buffer[10]
               );
    }
        
}

void sixaxis_set_leds(struct sixaxis_t* sixaxis, int leds){
    
    if(sixaxis==NULL || !SIXAXIS_IS_CONNECTED(sixaxis))
        return;
    
    if (!SIXAXIS_IS_SET(sixaxis, SIXAXIS_STATE_HANDSHAKE_COMPLETE))
		return;
    
    static unsigned char report_buffer[] = {
        SIXAXIS_SET_REPORT | SIXAXIS_OUTPUT, SIXAXIS_OUTPUT_01, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0xff, 0x27, 0x10, 0x00, 0x32,
        0xff, 0x27, 0x10, 0x00, 0x32,
        0xff, 0x27, 0x10, 0x00, 0x32,
        0xff, 0x27, 0x10, 0x00, 0x32,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    
    
    report_buffer[2 + 9] = leds;
    
    //un poquito de rumble
    report_buffer[2+1] = report_buffer[2+3] = 0x09;//0xfe;
    //report_buffer[2+4] = 0xff;
    report_buffer[2+2] = 0xff;
    
    if(sixaxis_send_l2cap!=NULL)
       sixaxis_send_l2cap(sixaxis->unid, 0, report_buffer, sizeof(report_buffer));
    else
        printf("Error: sixaxis_send_l2cap not set!");
    
}

int sixaxis_handshake(struct sixaxis_t* sixaxis){
    
    if(SIXAXIS_DBG)
	{
        printf("sixaxis_handshake\n");
    }
    
    if(sixaxis==NULL || !SIXAXIS_IS_CONNECTED(sixaxis))
        return 0;
    
    if(SIXAXIS_IS_SET(sixaxis, SIXAXIS_STATE_HANDSHAKE))
        return 0;
    
    if (SIXAXIS_IS_SET(sixaxis, SIXAXIS_STATE_HANDSHAKE_COMPLETE))
		return 1;
    
    SIXAXIS_ENABLE_STATE(wm, SIXAXIS_STATE_HANDSHAKE);
    
    unsigned char data[] = {SIXAXIS_SET_REPORT | SIXAXIS_FEATURE,  SIXAXIS_FEATURE_F4, 0x42, 0x03, 0x00, 0x00};
    
    if(sixaxis_send_l2cap!=NULL)
       sixaxis_send_l2cap(sixaxis->unid, 0, data, sizeof(data));
    else
        printf("Error: sixaxis_send_l2cap not set!");
    
    //usleep(500000)
    
    return 0;
}

int sixaxis_handle_data_packet(struct sixaxis_t* sixaxis, uint8_t *packet, uint16_t size){
    
    if(sixaxis==NULL || !SIXAXIS_IS_CONNECTED(sixaxis))
        return 0;
    
    if (packet[0] ==  (SIXAXIS_DATA | SIXAXIS_INPUT) && packet[1] == SIXAXIS_INPUT_01)
    {
        
        if(SIXAXIS_IS_SET(sixaxis, SIXAXIS_STATE_HANDSHAKE))
        {
            SIXAXIS_DISABLE_STATE(sixaxis, SIXAXIS_STATE_HANDSHAKE);
            SIXAXIS_ENABLE_STATE(sixaxis, SIXAXIS_STATE_HANDSHAKE_COMPLETE);
            
            if(sixaxis->unid==0)
                sixaxis_set_leds(sixaxis, SIXAXIS_LED_1);
            else if(sixaxis->unid==1)
                sixaxis_set_leds(sixaxis, SIXAXIS_LED_2);
            else if(sixaxis->unid==2)
                sixaxis_set_leds(sixaxis, SIXAXIS_LED_3);
            else if(sixaxis->unid==3)
                sixaxis_set_leds(sixaxis, SIXAXIS_LED_4);
            
            if(sixaxis_notify_connection!=NULL)
                sixaxis_notify_connection(sixaxis);
        }
        
        sixaxis_pressed_buttons(sixaxis, packet);
        
        return 1;
    }
    return 0;
}


void sixaxis_calc_joystick_state(struct sxxs_joystick_t* js, float x, float y) {
	float rx, ry, ang;
    
    rx = x;
    ry = y;
	/* calculate the joystick angle and magnitude */
	ang = SIXAXIS_RAD_TO_DEGREE(atanf(ry / rx));
	ang -= 90.0f;
	if (rx < 0.0f)
		ang -= 180.0f;
	js->ang = sixaxis_absf(ang);
	js->mag = (float) sqrt((rx * rx) + (ry * ry));
	js->rx = rx;
	js->ry = ry;
    
}
