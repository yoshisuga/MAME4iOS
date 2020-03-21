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

#ifndef netplay_h
#define netplay_h

#if defined(__cplusplus)
extern "C" {
#endif
    
#include <stdint.h>
#include <time.h>

#include "myosd.h"
    
    typedef enum {
        NETPLAY_TYPE_SKT = 1,
        NETPLAY_TYPE_GAMEKIT,
    } netplay_impl_type;
    
    typedef struct netplay_state{
        uint32_t digital;
        float analog_x;
        float analog_y;
        uint16_t ext;
    }netplay_state_t;
    
    typedef enum {
        NETPLAY_MSG_DATA = 1,
        NETPLAY_MSG_JOIN,
        NETPLAY_MSG_JOIN_ACK
    } netplay_msg_type;
    
    typedef struct netplay_msg_join {
        uint8_t frame_skip;
        uint32_t time;
        char game_name[MAX_GAME_NAME];
    }netplay_msg_join_t;
    
    typedef struct netplay_msg_data {
        uint8_t is_peer_paused;
        uint32_t peer_frame;
        netplay_state_t peer_state_tmp;
        uint32_t peer_peer_frame;
        uint8_t peer_frame_skip;
    }netplay_msg_data_t;
    
    typedef struct netplay_msg{
        uint32_t packetid;
        netplay_msg_type msg_type;
        union {
            netplay_msg_join_t join;
            netplay_msg_data_t data;
        }u;
    }netplay_msg_t;
    
    typedef struct netplay
    {
        netplay_impl_type type;
        
        unsigned player1;
        
        int has_connection;
        int has_joined;
        int has_begun_game;
        int is_peer_paused;
        int is_auto_frameskip;
        int new_frameskip_set;
        
        char game_name[MAX_GAME_NAME];
        
        unsigned timeout_cnt;
        uint32_t packet_uid;
        uint32_t recv_packet_uid;
        
        netplay_state_t state;
        netplay_state_t peer_state;
        
        netplay_state_t state_tmp;
        netplay_state_t peer_state_tmp;
        netplay_state_t peer_next_state_tmp;
        
        uint32_t frame;
        uint32_t target_frame;
        volatile uint32_t peer_frame;
        volatile uint32_t peer_next_frame;
        volatile uint32_t peer_peer_frame;
        
        uint32_t frame_skip;
        volatile uint32_t peer_frame_skip;
        
        time_t basetime;
        
        void *impl_data;
        
        int (*read_pkt_data)(struct netplay *,netplay_msg_t *);
        int (*send_pkt_data)(struct netplay *,netplay_msg_t *);
        void (*netplay_warn)(char *);
        
    } netplay_t;
    
    
    netplay_t * netplay_get_handle(void);
    void netplay_warn_hangup(netplay_t *handle);
    int  netplay_read_data(netplay_t *handle);
    int  netplay_send_data(netplay_t *handle);
    int  netplay_send_join(netplay_t *handle);
    int  netplay_send_join_ack(netplay_t *handle);
    int  netplay_init_handle(netplay_t *handle);
    void netplay_pre_frame_net(netplay_t *handle);
    void netplay_post_frame_net(netplay_t *handle);
    
    
#if defined(__cplusplus)
}
#endif

#endif
