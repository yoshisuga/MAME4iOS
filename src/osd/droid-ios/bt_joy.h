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

#ifndef bt_joy_h
#define bt_joy_h

#if defined(__cplusplus)
extern "C" {
#endif
    
#include "btstack/utils.h"
#include "wiimote.h"
#include "sixaxis.h"
    
    #define BTJOY_DBG			0
    
    #define MAX_JOYS 4

    enum BT_JOY_TYPES{
        WIIMOTE_TYPE,
        SIXAXIS_TYPE
    };

    
    typedef struct bt_joy_t {
        int joy_id;
        
        //BT-connection stuff
        uint16_t i_source_cid;
        uint16_t c_source_cid;
        bd_addr_t addr;
        
        //payload
        union {
            struct wiimote_t wm;
            struct sixaxis_t sixasis;
        }joy_data;
        enum BT_JOY_TYPES type;
        
    } bt_joy;
    
    //extern struct bt_joy_t btjoys[MAX_JOYS];
    
    void bt_joy_init(void (*connection_callback)(struct bt_joy_t* btjoy));
    void bt_joy_initjoy(enum BT_JOY_TYPES type, bd_addr_t *addr, uint16_t c_source_cid, uint16_t i_source_cid );
    int bt_joy_remove(uint16_t source_cid, bd_addr_t *addr);
    struct bt_joy_t* btjoy_get_by_source_cid(uint16_t source_cid);
    struct bt_joy_t* btjoy_get_by_unid(int unid);
    int  btjoy_handle_data_packet(uint16_t channel, uint8_t *packet, uint16_t size);
    int bt_joy_poll(int i);
    
#if defined(__cplusplus)
}
#endif

#endif
