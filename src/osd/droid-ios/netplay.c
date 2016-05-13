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

#include <string.h>

#include "netplay.h"

#include <netinet/in.h>

//extern void mylog(char * msg);

static netplay_t netplay_player;

static void* threaded_data(void* args);

float htonf(float value){
    union v {
        float       f;
        uint32_t    i;
    };
    union v val;
    val.f = value;
    htonl(val.i);
    return val.f;
}

float ntohf(float value){
    union v {
        float       f;
        uint32_t    i;
    };
    union v val;
    val.f = value;
    ntohl(val.i);
    return val.f;
}

netplay_t * netplay_get_handle(){
    static int init = 0;    
    if(!init)
    {
        netplay_init_handle(&netplay_player);
        init = 1;
    }
    return &netplay_player;
}

int netplay_init_handle(netplay_t *handle){
    
    memset(handle,0,sizeof(netplay_t));
    
    handle->has_connection = 0;
    
    handle->frame_skip = 1;
    handle->peer_frame_skip = 1;
    
    time(&handle->basetime);
        
    return 1;
}

void netplay_warn_hangup(netplay_t *handle)
{
    char msg[] = "Netplay has disconnected.\nWill continue without connection ...\n";
    
    if(handle->netplay_warn!=0)
        handle->netplay_warn(msg);
    else
        printf("%s",msg);
}

int netplay_read_data(netplay_t *handle)
{
    netplay_msg_t msg;
    int reliable = 0;
    
    if(!handle->read_pkt_data(handle,&msg))
        return 0;
    
    uint32_t msg_packet_uid = ntohl(msg.packetid);
    
    reliable = msg_packet_uid>handle->recv_packet_uid;
    
    if(!reliable)
    {
        printf("received BAD pkt msg_packet_uid:%d recv_packet_uid: %d!\n",msg_packet_uid,handle->recv_packet_uid);
    }
    else
    {
        handle->recv_packet_uid = msg_packet_uid;
    }
    //printf("received packed uid:%d type:%d\n",msg_packet_uid,msg.msg_type);
    
    switch (msg.msg_type) {
        case NETPLAY_MSG_DATA:
        {
            handle->is_peer_paused =  msg.u.data.is_peer_paused;  //msg.data[0];
                        
            //printf("received peer_frame %d peer_peer_frame: %d\n",ntohl(buffer[0]),ntohl(buffer[2]));
            
            uint32_t peer_frame = ntohl(msg.u.data.peer_frame);
            if(handle->target_frame == peer_frame)
            {
                handle->peer_state_tmp.digital = ntohl(msg.u.data.peer_state_tmp.digital);
                handle->peer_state_tmp.analog_x = ntohf(msg.u.data.peer_state_tmp.analog_x);
                handle->peer_state_tmp.analog_y = ntohf(msg.u.data.peer_state_tmp.analog_y);
                handle->peer_state_tmp.ext = ntohs(msg.u.data.peer_state_tmp.ext);
                handle->peer_frame = peer_frame;
                                
                //printf("handle->target_frame == peer_frame (%d=%d)\n",handle->target_frame, handle->peer_frame);
                
                if(!netplay_send_data(handle)) //ACK
                    return 0;
            }
            
            if( handle->target_frame == handle->peer_frame && handle->target_frame + handle->frame_skip == peer_frame)
            {
                handle->peer_next_state_tmp.digital = ntohl(msg.u.data.peer_state_tmp.digital);
                handle->peer_next_state_tmp.analog_x = ntohf(msg.u.data.peer_state_tmp.analog_x);
                handle->peer_next_state_tmp.analog_y = ntohf(msg.u.data.peer_state_tmp.analog_y);
                handle->peer_next_state_tmp.ext = ntohs(msg.u.data.peer_state_tmp.ext);
                handle->peer_next_frame = peer_frame;
                
                //printf("handle->target_frame + handle->frame_skip == peer_frame (%d+%d==%d)\n",handle->target_frame,handle->frame_skip, handle->peer_next_frame);
                
                if(!netplay_send_data(handle)) //ACK
                    return 0;
            }
            
            uint32_t peer_peer_frame = ntohl(msg.u.data.peer_peer_frame);
            if(handle->peer_peer_frame < peer_peer_frame)
            {
                //printf("handle->peer_peer_frame < peer_peer_frame (%d<%d)\n",handle->peer_peer_frame,peer_peer_frame);
                
                handle->peer_peer_frame = peer_peer_frame;
            }
            
            uint8_t peer_frame_skip = msg.u.data.peer_frame_skip;
            if(reliable && handle->peer_frame_skip != peer_frame_skip){
                handle->peer_frame_skip = peer_frame_skip;
            }
        }
            break;
        case NETPLAY_MSG_JOIN:
        {
            if(!handle->has_begun_game)
            {
               handle->has_joined = 1;
               if(!netplay_send_join_ack(handle)) //ACK
                   return 0;
            }
        }
            break;
        case NETPLAY_MSG_JOIN_ACK:
        {
            handle->has_joined = 1;
            handle->frame_skip = msg.u.join.frame_skip;
            handle->basetime = ntohl(msg.u.join.time);
            strcpy(handle->game_name,msg.u.join.game_name);
            
            printf("received join ack for %s with basetime:%s..\n",handle->game_name, ctime(&handle->basetime));
        }
            break;
        default:
            printf("netplay unknow msg %d",msg.msg_type);
            break;
    }
    
    return 1;
}

int netplay_send_data(netplay_t *handle)
{
    netplay_msg_t msg;
    
    if(!handle->has_connection)
        return 0;
    
    handle->packet_uid+=1;
    
    msg.packetid = htonl(handle->packet_uid);
    msg.msg_type = NETPLAY_MSG_DATA;
    
    msg.u.data.is_peer_paused = myosd_pause;
    
    msg.u.data.peer_frame = htonl(handle->target_frame);
    
    msg.u.data.peer_state_tmp.digital = htonl(handle->state_tmp.digital);
    msg.u.data.peer_state_tmp.analog_x = htonf(handle->state_tmp.analog_x);
    msg.u.data.peer_state_tmp.analog_y = htonf(handle->state_tmp.analog_y);
    msg.u.data.peer_state_tmp.ext = htons(handle->state_tmp.ext);
    
    msg.u.data.peer_peer_frame = htonl(handle->peer_frame);
    msg.u.data.peer_frame_skip = handle->frame_skip;
    
    //printf("send data [uid: %d] %d %d\n",ntohl(msg.packetid),ntohl(buffer[0]), ntohl(buffer[2]));
    
    return handle->send_pkt_data(handle,&msg);
}

int netplay_send_join(netplay_t *handle){
    netplay_msg_t msg;
    
    handle->packet_uid+=1;
    
    msg.packetid = htonl(handle->packet_uid);
    msg.msg_type = NETPLAY_MSG_JOIN;
        
    return handle->send_pkt_data(handle,&msg);
}

int netplay_send_join_ack(netplay_t *handle){
    netplay_msg_t msg;
    
    handle->packet_uid+=1;
    
    msg.packetid = htonl(handle->packet_uid);
    msg.msg_type = NETPLAY_MSG_JOIN_ACK;
    msg.u.join.frame_skip = handle->frame_skip;
    msg.u.join.time = htonl(handle->basetime);
    strcpy(msg.u.join.game_name,handle->game_name);
    
    printf("send join ack for %s with basetime:%s\n",handle->game_name, ctime(&handle->basetime));
    
    return handle->send_pkt_data(handle,&msg);
}

#define MAX_RETRIES 16
#define RETRY_MS 500

#define IS_SYNCED(h) ((h->frame < h->target_frame) || \
                      ((h)->frame ==  h->target_frame && \
                       (h)->peer_frame == (h)->target_frame) && \
                       (h)->peer_peer_frame == (h)->target_frame )

void netplay_pre_frame_net(netplay_t *handle)
{
    //recibir y bloquear por pkts salvo en frame 0
    if(!handle->has_connection || !handle->has_begun_game)return;
    
    //printf("netplay_pre_frame_net %d\n",handle->frame);
        
    if(handle->frame >= handle->frame_skip)
    {
        int retry = 0;
        
        int ms = 0;
        //int warn_paused = 0;
        
        if(!IS_SYNCED(handle))
        {
            handle->timeout_cnt++;
            
            int sync = 0;
            while(retry < MAX_RETRIES && !sync)
            {
                retry++;
                
                if(ms>0)
                   printf("Retry: %d frame:%d target:%d peer:%d peer_peer:%d %d ms\n",retry, handle->frame,handle->target_frame, handle->peer_frame,handle->peer_peer_frame,ms);
                ms+=250;
                
                //begin polling!
                for(int i=0; i<RETRY_MS && !sync;i++) //max 500ms
                {
                    if(i % /*(16*3)*/ 250 == 0)
                    {
                        if(!netplay_send_data(handle)) //send frame data
                        {
                            handle->has_connection = 0;
                            netplay_warn_hangup(handle);
                            return;
                        }
                    }
                    usleep(1000);
                    
                    if(IS_SYNCED (handle))
                        sync=1;
                    
                    if(myosd_exitGame && !myosd_in_menu)
                    {
                        sync = 1;
                        handle->has_connection = 0;
                    }
                }
                
                if(handle->is_peer_paused)
                {
                    retry = 0;
                    handle->is_peer_paused = 0;
                    printf("peer is paused...\n");
                    /*
                    if(!warn_paused)
                    {
                        warn_paused = 1;
                        handle->netplay_warn("Peer is paused!");
                    }*/
                    myosd_exitPause = 1;
                }
            
                if(handle->peer_frame_skip != handle->frame_skip)
                {
                    printf("-->> NEW: old packet skip: %d  peer_frame_skip: %d\n",handle->frame_skip,handle->peer_frame_skip);
                    handle->frame_skip = handle->peer_frame_skip;
                    handle->target_frame = handle->target_frame + handle->frame_skip;
                    handle->peer_next_frame = 0;
                    printf("-->> NEW target frame: %d  packet skip: %d \n",handle->target_frame,handle->peer_frame_skip);
                    break;
                }
            }
        }
        else
        {
            handle->timeout_cnt = 0;
        }
        
        if(!IS_SYNCED(handle))
        {
            handle->has_connection = 0;
            netplay_warn_hangup(handle);
            return;
        }
        else if(handle->frame == handle->peer_peer_frame)
        {
              handle->state = handle->state_tmp;
              handle->peer_state = handle->peer_state_tmp;
            
              //myosd_ext_status = 0;
  
        }
        else if(handle->frame == handle->target_frame)
        {
             printf("Not sync frame:%d target:%d peer:%d peer_peer:%d\n", handle->frame,handle->target_frame, handle->peer_frame,handle->peer_peer_frame);
        }
    }
    
     //printf("netplay_pre_frame_net END %d\n",handle->frame);
}

void netplay_post_frame_net(netplay_t *handle)
{

    if(!handle->has_connection || !handle->has_begun_game)return;
    
    //printf("netplay_post_frame_net %d BGIN\n",handle->frame);
    
    if( handle->frame == handle->target_frame)
    {        
        if((handle->timeout_cnt > 10 && handle->frame_skip <= 10 && handle->is_auto_frameskip) || handle->new_frameskip_set)
        {
                        
            uint32_t old_target_frame = handle->frame + handle->frame_skip;
            
            if(handle->new_frameskip_set)
            {
                handle->frame_skip = handle->new_frameskip_set;
                handle->new_frameskip_set = 0;
            }
            else
            {
                handle->frame_skip += 1;
                handle->timeout_cnt = 0;
            }
            
            //printf("-->> chenge packet skip: %d\n",handle->frame_skip);
            
            int retry = 0;
            while(handle->peer_frame_skip != handle->frame_skip && retry < (MAX_RETRIES*5))
            {
                
                if(!netplay_send_data(handle)) //send frame data
                {
                    handle->has_connection = 0;
                    netplay_warn_hangup(handle);
                    return;
                }
                usleep(100*1000);
                retry++;
                if(handle->is_peer_paused)
                {
                    retry = 0;
                    handle->is_peer_paused = 0;
                    printf("peer is paused...\n");
                    myosd_exitPause = 1;
                }
            }
            
            if(handle->peer_frame_skip != handle->frame_skip)
            {
                handle->has_connection = 0;
                netplay_warn_hangup(handle);
                return;
            }
            else
            {
               handle->target_frame = old_target_frame + handle->frame_skip;
               handle->peer_next_frame = 0;
               //printf("-->> NEW target frame: %d  \n",handle->target_frame);
            }
        }
        else
        {
            handle->target_frame =  handle->frame + handle->frame_skip;
            
            if(handle->target_frame == handle->peer_next_frame)
            {
                handle->peer_frame = handle->peer_next_frame;
                handle->peer_state_tmp = handle->peer_next_state_tmp;
            }
        }
        
        if(handle->frame!=0)
        {
           handle->state_tmp.digital = myosd_joystick_read(0);
           handle->state_tmp.analog_x = myosd_joystick_read_analog(0, 'x');
           handle->state_tmp.analog_y = myosd_joystick_read_analog(0, 'y');
           handle->state_tmp.ext = myosd_ext_status;
        }
        //printf("netplay_post_frame_net %d\n",handle->frame);
        
        if(!netplay_send_data(handle)) //send frame data
        {
            handle->has_connection = 0;
            netplay_warn_hangup(handle);
            return;
        }
    }
    
    //printf("frame %d\n",handle->frame);
    
    handle->frame++;
}



