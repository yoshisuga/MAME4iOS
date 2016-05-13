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


#include "btstack/btstack.h"

#include "bt_joy.h"
#include "wiimote.h"
#include "sixaxis.h"
#include "myosd.h"

#define STICK4WAY (myosd_waysStick == 4 && myosd_inGame)
#define STICK2WAY (myosd_waysStick == 2 && myosd_inGame)

extern int g_pref_BT_DZ_value;

struct bt_joy_t btjoys[MAX_JOYS];

static void (*bt_joy_notify_connection)(struct bt_joy_t* btjoy) = NULL;
static void btjoy_send_l2cap(int unid, int interrupt, unsigned char *buf, int len);
static void bt_joy_wiimote_connection_callback(struct wiimote_t *vm);
static void bt_joy_sixaxis_connection_callback(struct sixaxis_t *sixaxis);
static int bt_joy_wiimote_poll (struct  wiimote_t  *wm);
static int bt_joy_sixaxis_poll (struct sixaxis_t *sixaxis);

void bt_joy_init(void (*connection_callback)(struct bt_joy_t* btjoy)){
    myosd_num_of_joys = 0;
    memset(btjoys,0,sizeof(btjoys));
    bt_joy_notify_connection = connection_callback;
    wiimote_init(bt_joy_wiimote_connection_callback, btjoy_send_l2cap );
    sixaxis_init(bt_joy_sixaxis_connection_callback, btjoy_send_l2cap );
}

void bt_joy_initjoy(enum BT_JOY_TYPES type, bd_addr_t *addr, uint16_t c_source_cid, uint16_t i_source_cid ){
    
    struct bt_joy_t *btjoy = &btjoys[myosd_num_of_joys];
    memset(btjoy,0,sizeof(struct bt_joy_t));
    memcpy(&btjoy->addr,addr,BD_ADDR_LEN);
    btjoy->c_source_cid = c_source_cid;
    btjoy->i_source_cid = i_source_cid;
    btjoy->joy_id = myosd_num_of_joys;
    btjoy->type = type;
    
    if(type == WIIMOTE_TYPE)
    {
        struct wiimote_t *wm = &btjoy->joy_data.wm;
        wm->unid = myosd_num_of_joys;
        wm->exp.type = EXP_NONE;
        wm->state = WIIMOTE_STATE_CONNECTED;
        wiimote_handshake(wm,-1,NULL,-1);
    }
    else if(type == SIXAXIS_TYPE){
        struct sixaxis_t *sixaxis = &btjoy->joy_data.sixasis;
        sixaxis->unid = myosd_num_of_joys;
        sixaxis->state = SIXAXIS_STATE_CONNECTED;
        sixaxis_handshake(sixaxis);
    }
}

int bt_joy_remove(uint16_t source_cid, bd_addr_t *addr){

    int i = 0;
    int joyid = -1;
    int found = 0;

    for(;i<myosd_num_of_joys;i++)
    {
        if((btjoys[i].c_source_cid==source_cid || btjoys[i].i_source_cid==source_cid) && !found)
        {
            found=1;
            struct bt_joy_t *btjoy =  &btjoys[i];
            
            if(BTJOY_DBG)printf("%02x:%02x:%02x:%02x:%02x:%02x\n",btjoy->addr[0], btjoy->addr[1], btjoy->addr[2],btjoy->addr[3], btjoy->addr[4], btjoy->addr[5]);
            memcpy(addr,&(btjoy->addr),BD_ADDR_LEN);
            joyid = btjoy->joy_id;
            continue;
        }
        if(found)
        {
            memcpy(&btjoys[i-1],&btjoys[i],sizeof(struct bt_joy_t));
            btjoys[i-1].joy_id = i-1;
            
            if(btjoys[i-1].type == WIIMOTE_TYPE)
            {
                struct wiimote_t *wm = &btjoys[i-1].joy_data.wm;
                wm->unid = i -1;
                if(wm->unid==0)
                    wiimote_set_leds(wm, WIIMOTE_LED_1);
                else if(wm->unid==1)
                    wiimote_set_leds(wm, WIIMOTE_LED_2);
                else if(wm->unid==2)
                    wiimote_set_leds(wm, WIIMOTE_LED_3);
                else if(wm->unid==3)
                    wiimote_set_leds(wm, WIIMOTE_LED_4);
            }
            else if(btjoys[i-1].type == SIXAXIS_TYPE)
            {
                struct sixaxis_t *sixaxis = &btjoys[i-1].joy_data.sixasis;
                sixaxis->unid = i -1;
                if(sixaxis->unid==0)
                    sixaxis_set_leds(sixaxis, SIXAXIS_LED_1);
                else if(sixaxis->unid==1)
                    sixaxis_set_leds(sixaxis, SIXAXIS_LED_2);
                else if(sixaxis->unid==2)
                    sixaxis_set_leds(sixaxis, SIXAXIS_LED_3);
                else if(sixaxis->unid==3)
                    sixaxis_set_leds(sixaxis, SIXAXIS_LED_4);
            }
        }
    }

    if(found)
    {
        myosd_num_of_joys--;
        if(WIIMOTE_DBG)printf("NUM JOYS %d\n",myosd_num_of_joys);
        return joyid;
    }
    return joyid;
}


struct bt_joy_t* btjoy_get_by_source_cid(uint16_t source_cid){
    
	int i = 0;
    
	for (; i < MAX_JOYS/*myosd_num_of_joys*/; ++i) {
		if(BTJOY_DBG)printf("search by source_cid 0x%02x 0x%02x 0x%02x\n",btjoys[i].i_source_cid,btjoys[i].c_source_cid ,source_cid);
		if (btjoys[i].i_source_cid == source_cid || btjoys[i].c_source_cid == source_cid )
			return &btjoys[i];
	}
    
	return NULL;
}

struct bt_joy_t* btjoy_get_by_unid(int unid){
    int i = 0;
    
    for (; i < MAX_JOYS/*myosd_num_of_joys*/; ++i) {

		if(BTJOY_DBG) printf("search by unid: %d\n",btjoys[i].joy_id);
        if (btjoys[i].joy_id == unid)
			return &btjoys[i];
	}
    
    return NULL;
}

void btjoy_send_l2cap(int unid, int interrupt, unsigned char *buf, int len) {
    
    if(BTJOY_DBG)
        printf("send l2cap unid:%d interrupt:%d len:%d\n",unid,interrupt,len);
    
    struct bt_joy_t* joy = btjoy_get_by_unid(unid);
    if(joy!=NULL)
    {
        if(BTJOY_DBG)
        {
            int x = 2;
            printf("[DEBUG] (id %i) SEND: (%x) %.2x ", joy->joy_id, buf[0], buf[1]);
            for (; x < len; ++x)
                printf("%.2x ", buf[x]);
            printf("\n");
        }
        bt_send_l2cap(interrupt ? joy->i_source_cid : joy->c_source_cid, buf,len);
    }
}

int  btjoy_handle_data_packet(uint16_t channel, uint8_t *packet, uint16_t size){
    
    struct bt_joy_t *btjoy = btjoy_get_by_source_cid(channel);
    
    if(btjoy==NULL)return 0;
    
    struct wiimote_t *wm = NULL;
    struct sixaxis_t *sixaxis = NULL;
    
    if(btjoy->type == SIXAXIS_TYPE)
        sixaxis = &btjoy->joy_data.sixasis;
    else if(btjoy->type == WIIMOTE_TYPE)
        wm = &btjoy->joy_data.wm;
    
    if(sixaxis != NULL)
        return sixaxis_handle_data_packet(sixaxis,packet,size);
    else if (wm != NULL)
        return wiimote_handle_data_packet(wm,packet,size);
    
    return 0;
}

int bt_joy_poll(int i){
        
    struct bt_joy_t *btjoy = &btjoys[i];
    
    if(btjoy->type == SIXAXIS_TYPE)
    {
        return bt_joy_sixaxis_poll(&btjoy->joy_data.sixasis);
    }
    else if(btjoy->type == WIIMOTE_TYPE)
    {
        return bt_joy_wiimote_poll(&btjoy->joy_data.wm);
    }
    return 0;
}

void bt_joy_wiimote_connection_callback(struct wiimote_t *wm) {
    struct bt_joy_t* joy = btjoy_get_by_unid(wm->unid);
    if(joy!=NULL && bt_joy_notify_connection!=NULL)
        bt_joy_notify_connection(joy);

}

void bt_joy_sixaxis_connection_callback(struct sixaxis_t *sixaxis) {
    struct bt_joy_t* joy = btjoy_get_by_unid(sixaxis->unid);
    if(joy!=NULL && bt_joy_notify_connection!=NULL)
        bt_joy_notify_connection(joy);
}


int bt_joy_wiimote_poll (struct  wiimote_t  *wm){
    //printf("check %d\n",wm->unid);
    joy_analog_x[wm->unid]=0.0f;
    joy_analog_y[wm->unid]=0.0f;
    int joyExKey = 0;
    //myosd_exitGame = 0;
    if (1) {
        
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_A))		{joyExKey |= MYOSD_A;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_B))		{joyExKey |= MYOSD_Y;}
        
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_UP))		{joyExKey |= MYOSD_LEFT;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN))	{joyExKey |= MYOSD_RIGHT;}
        
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_LEFT))	{
            if(!STICK2WAY &&
               !(STICK4WAY && (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_UP) ||
                               (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN)))))
				joyExKey |= MYOSD_DOWN;
        }
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_RIGHT))	{
            if(!STICK2WAY &&
               !(STICK4WAY && (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_UP) ||
                               (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN)))))
				joyExKey |= MYOSD_UP;
        }
        
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_MINUS))	{joyExKey |= MYOSD_SELECT;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_PLUS))	{joyExKey |= MYOSD_START;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_ONE))		{joyExKey |= MYOSD_X;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_TWO))		{joyExKey |= MYOSD_B;}
        if (WM_IS_PRESSED(wm, WIIMOTE_BUTTON_HOME))	{
            
            //usleep(50000);
            myosd_exitGame = 1;
        }
        
        if (wm->exp.type == EXP_CLASSIC) {
            
            float deadZone;
            
            switch(g_pref_BT_DZ_value)
            {
                case 0: deadZone = 0.100f;break;
                case 1: deadZone = 0.125f;break;
                case 2: deadZone = 0.150f;break;
                case 3: deadZone = 0.180f;break;
                case 4: deadZone = 0.250f;break;
                case 5: deadZone = 0.300f;break;
            }
            
            //printf("deadzone %f\n",deadZone);
            
            struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;
            
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZL))			joyExKey |= MYOSD_R1;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_B))			joyExKey |= MYOSD_X;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_Y))			joyExKey |= MYOSD_A;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_A))			joyExKey |= MYOSD_B;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_X))			joyExKey |= MYOSD_Y;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZR))			joyExKey |= MYOSD_L1;
            
            
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_UP)){
                if(!STICK2WAY &&
                   !(STICK4WAY && (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT) ||
                                   (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT)))))
                    joyExKey |= MYOSD_UP;
            }
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_DOWN)){
                if(!STICK2WAY &&
                   !(STICK4WAY && (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT) ||
                                   (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT)))))
                    joyExKey |= MYOSD_DOWN;
            }
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT))		joyExKey |= MYOSD_LEFT;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT))		joyExKey |= MYOSD_RIGHT;
            
            
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_L))		joyExKey |= MYOSD_L1;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_MINUS))		joyExKey |= MYOSD_SELECT;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_HOME))		{//myosd_exitGame = 0;usleep(50000);
                myosd_exitGame = 1;}
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_PLUS))		joyExKey |= MYOSD_START;
            if (WM_IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_R))		joyExKey |= MYOSD_R1;
            
            if(cc->ljs.mag >= deadZone)
            {
                joy_analog_x[wm->unid] =  (  cc->ljs.rx > 1.0 ) ? 1.0 : (  cc->ljs.rx < -1.0 ) ? -1.0 :  cc->ljs.rx;
                joy_analog_y[wm->unid] =  (  cc->ljs.ry > 1.0 ) ? 1.0 : (  cc->ljs.ry < -1.0 ) ? -1.0 :  cc->ljs.ry;
                
                float v = cc->ljs.ang;
                
                if(STICK2WAY)
                {
                    if( v < 180){
                        joyExKey |= MYOSD_RIGHT;
                        //printf("Right\n");
                    }
                    else if ( v >= 180){
                        joyExKey |= MYOSD_LEFT;
                        //printf("Left\n");
                    }
                }
                else if(STICK4WAY)
                {
                    if(v >= 315 || v < 45){
                        joyExKey |= MYOSD_UP;
                        //printf("Up\n");
                    }
                    else if (v >= 45 && v < 135){
                        joyExKey |= MYOSD_RIGHT;
                        //printf("Right\n");
                    }
                    else if (v >= 135 && v < 225){
                        joyExKey |= MYOSD_DOWN;
                        //printf("Down\n");
                    }
                    else if (v >= 225 && v < 315){
                        joyExKey |= MYOSD_LEFT;
                        //printf("Left\n");
                    }
                }
                else
                {
                    if( v >= 330 || v < 30){
                        joyExKey |= MYOSD_UP;
                        //printf("Up\n");
                    }
                    else if ( v >= 30 && v <60  )  {
                        joyExKey |= MYOSD_UP;joyExKey |= MYOSD_RIGHT;
                        //printf("UpRight\n");
                    }
                    else if ( v >= 60 && v < 120  ){
                        joyExKey |= MYOSD_RIGHT;
                        //printf("Right\n");
                    }
                    else if ( v >= 120 && v < 150  ){
                        joyExKey |= MYOSD_RIGHT;joyExKey |= MYOSD_DOWN;
                        //printf("RightDown\n");
                    }
                    else if ( v >= 150 && v < 210  ){
                        joyExKey |= MYOSD_DOWN;
                        //printf("Down\n");
                    }
                    else if ( v >= 210 && v < 240  ){
                        joyExKey |= MYOSD_DOWN;joyExKey |= MYOSD_LEFT;
                        //printf("DownLeft\n");
                    }
                    else if ( v >= 240 && v < 300  ){
                        joyExKey |= MYOSD_LEFT;
                        //printf("Left\n");
                    }
                    else if ( v >= 300 && v < 330  ){
                        joyExKey |= MYOSD_LEFT;
                        joyExKey |= MYOSD_UP;
                        //printf("LeftUp\n");
                    }
                }
            }
            
            if(cc->rjs.mag >= deadZone)
            {
                float v = cc->rjs.ang;
                
                if( v >= 330 || v < 30){
                    joyExKey |= MYOSD_Y;
                    //printf("Y\n");
                }
                else if ( v >= 30 && v <60  )  {
                    joyExKey |= MYOSD_Y;joyExKey |= MYOSD_B;
                    //printf("Y B\n");
                }
                else if ( v >= 60 && v < 120  ){
                    joyExKey |= MYOSD_B;
                    //printf("B\n");
                }
                else if ( v >= 120 && v < 150  ){
                    joyExKey |= MYOSD_B;joyExKey |= MYOSD_X;
                    //printf("B X\n");
                }
                else if ( v >= 150 && v < 210  ){
                    joyExKey |= MYOSD_X;
                    //printf("X\n");
                }
                else if ( v >= 210 && v < 240  ){
                    joyExKey |= MYOSD_X;joyExKey |= MYOSD_A;
                    //printf("X A\n");
                }
                else if ( v >= 240 && v < 300  ){
                    joyExKey |= MYOSD_A;
                    //printf("A\n");
                }
                else if ( v >= 300 && v < 330  ){
                    joyExKey |= MYOSD_A;joyExKey |= MYOSD_Y;
                    //printf("A Y\n");
                }
            }
        }
        
		return joyExKey;
    } else {
		joyExKey = 0;
		return joyExKey;
    }
}

static int bt_joy_sixaxis_poll (struct sixaxis_t *sixaxis) {
    
    int joyExKey = 0;
    
    joy_analog_x[sixaxis->unid]=0.0f;
    joy_analog_y[sixaxis->unid]=0.0f;
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_CIRCLE))		{joyExKey |= MYOSD_B;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_CROSS))		{joyExKey |= MYOSD_X;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_SQUARE))		{joyExKey |= MYOSD_A;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_TRIANGLE))		{joyExKey |= MYOSD_Y;}
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_LEFT))	{joyExKey |= MYOSD_LEFT;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_RIGHT))	{joyExKey |= MYOSD_RIGHT;}
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_DOWN))	{
        if(!STICK2WAY &&
           !(STICK4WAY && (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_LEFT) ||
                           (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_RIGHT)))))
            joyExKey |= MYOSD_DOWN;
    }
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_UP))	{
        if(!STICK2WAY &&
           !(STICK4WAY && (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_LEFT) ||
                           (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_RIGHT)))))
            joyExKey |= MYOSD_UP;
    }
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_SELECT))	{joyExKey |= MYOSD_SELECT;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_START))	{joyExKey |= MYOSD_START;}
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_L1))	{joyExKey |= MYOSD_L1;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_R1))	{joyExKey |= MYOSD_R1;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_L2))	{joyExKey |= MYOSD_R1;}
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_R2))	{joyExKey |= MYOSD_L1;}
    
    if (SIXAXIS_IS_PRESSED(sixaxis, SIXAXIS_BUTTON_PS) && sixaxis->unid==0 )	{myosd_exitGame = 1;}
    
    float deadZone = 0.1f;
    
    switch(g_pref_BT_DZ_value)
    {
        case 0: deadZone = 0.10f;break;
        case 1: deadZone = 0.14f;break;
        case 2: deadZone = 0.17f;break;
        case 3: deadZone = 0.2f;break;
        case 4: deadZone = 0.3f;break;
        case 5: deadZone = 0.4f;break;
    }
    

    if(sixaxis->ljs.mag >= deadZone)
    {
        joy_analog_x[sixaxis->unid] =  (  sixaxis->ljs.rx > 1.0 ) ? 1.0 : (  sixaxis->ljs.rx < -1.0 ) ? -1.0 :  sixaxis->ljs.rx;
        joy_analog_y[sixaxis->unid] =  (  sixaxis->ljs.ry > 1.0 ) ? 1.0 : (  sixaxis->ljs.ry < -1.0 ) ? -1.0 :  sixaxis->ljs.ry;
        
        float v = sixaxis->ljs.ang;
        
        if(STICK2WAY)
        {
            if( v < 180){
                joyExKey |= MYOSD_RIGHT;
                //printf("Right\n");
            }
            else if ( v >= 180){
                joyExKey |= MYOSD_LEFT;
                //printf("Left\n");
            }
        }
        else if(STICK4WAY)
        {
            if(v >= 315 || v < 45){
                joyExKey |= MYOSD_UP;
                //printf("Up\n");
            }
            else if (v >= 45 && v < 135){
                joyExKey |= MYOSD_RIGHT;
                //printf("Right\n");
            }
            else if (v >= 135 && v < 225){
                joyExKey |= MYOSD_DOWN;
                //printf("Down\n");
            }
            else if (v >= 225 && v < 315){
                joyExKey |= MYOSD_LEFT;
                //printf("Left\n");
            }
        }
        else
        {
            if( v >= 330 || v < 30){
                joyExKey |= MYOSD_UP;
                //printf("Up\n");
            }
            else if ( v >= 30 && v <60  )  {
                joyExKey |= MYOSD_UP;joyExKey |= MYOSD_RIGHT;
                //printf("UpRight\n");
            }
            else if ( v >= 60 && v < 120  ){
                joyExKey |= MYOSD_RIGHT;
                //printf("Right\n");
            }
            else if ( v >= 120 && v < 150  ){
                joyExKey |= MYOSD_RIGHT;joyExKey |= MYOSD_DOWN;
                //printf("RightDown\n");
            }
            else if ( v >= 150 && v < 210  ){
                joyExKey |= MYOSD_DOWN;
                //printf("Down\n");
            }
            else if ( v >= 210 && v < 240  ){
                joyExKey |= MYOSD_DOWN;joyExKey |= MYOSD_LEFT;
                //printf("DownLeft\n");
            }
            else if ( v >= 240 && v < 300  ){
                joyExKey |= MYOSD_LEFT;
                //printf("Left\n");
            }
            else if ( v >= 300 && v < 330  ){
                joyExKey |= MYOSD_LEFT;
                joyExKey |= MYOSD_UP;
                //printf("LeftUp\n");
            }
        }
    }
    
    if(sixaxis->rjs.mag >= deadZone)
    {
        float v = sixaxis->rjs.ang;
        
        if( v >= 330 || v < 30){
            joyExKey |= MYOSD_Y;
            //printf("Y\n");
        }
        else if ( v >= 30 && v <60  )  {
            joyExKey |= MYOSD_Y;joyExKey |= MYOSD_B;
            //printf("Y B\n");
        }
        else if ( v >= 60 && v < 120  ){
            joyExKey |= MYOSD_B;
            //printf("B\n");
        }
        else if ( v >= 120 && v < 150  ){
            joyExKey |= MYOSD_B;joyExKey |= MYOSD_X;
            //printf("B X\n");
        }
        else if ( v >= 150 && v < 210  ){
            joyExKey |= MYOSD_X;
            //printf("X\n");
        }
        else if ( v >= 210 && v < 240  ){
            joyExKey |= MYOSD_X;joyExKey |= MYOSD_A;
            //printf("X A\n");
        }
        else if ( v >= 240 && v < 300  ){
            joyExKey |= MYOSD_A;
            //printf("A\n");
        }
        else if ( v >= 300 && v < 330  ){
            joyExKey |= MYOSD_A;joyExKey |= MYOSD_Y;
            //printf("A Y\n");
        }
    }

    return joyExKey;
}
