//============================================================
//
//  myosd-internal.h - Internal verions of MYOSD.H
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================
#include "libmame.h"

#ifndef __MYOSD_H__
#define __MYOSD_H__

#if defined(__cplusplus)
extern "C" {
#endif

// globals in osd-ios.c
extern int  myosd_inGame;
extern int  myosd_in_menu;
extern int  myosd_fps;
extern int  myosd_display_width;        // display width,height is the screen output resolution
extern int  myosd_display_height;       // ...set in the iOS app, to pick a good default render target size.
extern int  myosd_force_pxaspect;
extern int  myosd_hiscore;
extern int  myosd_speed;
extern int  myosd_filter_clones;
extern int  myosd_filter_not_working;

extern void myosd_init(void);
extern void myosd_deinit(void);
extern void myosd_set_video_mode(int width,int height);
extern void myosd_video_draw(render_primitive*, int width, int height);
extern void myosd_poll_input(myosd_input_state* input);
extern void myosd_set_game_info(const game_driver *info[], int game_count);
extern void myosd_openSound(int rate,int stereo);
extern void myosd_closeSound(void);
extern void myosd_sound_play(void *buff, int len);

#ifdef __MACHINE_H__
_Static_assert(MYOSD_OUTPUT_ERROR == OUTPUT_CHANNEL_ERROR);
_Static_assert(MYOSD_OUTPUT_WARNING == OUTPUT_CHANNEL_WARNING);
_Static_assert(MYOSD_OUTPUT_INFO == OUTPUT_CHANNEL_INFO);
_Static_assert(MYOSD_OUTPUT_DEBUG == OUTPUT_CHANNEL_DEBUG);
_Static_assert(MYOSD_OUTPUT_VERBOSE == OUTPUT_CHANNEL_VERBOSE);
#endif

#ifdef __DRIVER_H__
// fail to compile if these structures get out of sync.
_Static_assert(offsetof(myosd_game_info, source_file)  == offsetof(game_driver, source_file), "");
_Static_assert(offsetof(myosd_game_info, parent)       == offsetof(game_driver, parent), "");
_Static_assert(offsetof(myosd_game_info, name)         == offsetof(game_driver, name), "");
_Static_assert(offsetof(myosd_game_info, description)  == offsetof(game_driver, description), "");
_Static_assert(offsetof(myosd_game_info, year)         == offsetof(game_driver, year), "");
_Static_assert(offsetof(myosd_game_info, manufacturer) == offsetof(game_driver, manufacturer), "");
#endif

// NOTE if you get a re-defined enum error, you need to include emu.h before myosd.h
#ifdef __RENDER_H__
// myosd struct **must** match the internal render.h version.
_Static_assert(sizeof(myosd_render_primitive) == sizeof(render_primitive), "");
_Static_assert(offsetof(myosd_render_primitive, bounds_x0)    == offsetof(render_primitive, bounds), "");
_Static_assert(offsetof(myosd_render_primitive, color_a)      == offsetof(render_primitive, color), "");
_Static_assert(offsetof(myosd_render_primitive, texture_base) == offsetof(render_primitive, texture), "");
_Static_assert(offsetof(myosd_render_primitive, texcoords)    == offsetof(render_primitive, texcoords), "");
_Static_assert(PRIMFLAG_TEXORIENT_MASK == 0x000F);
_Static_assert(PRIMFLAG_TEXFORMAT_MASK == 0x00F0);
_Static_assert(PRIMFLAG_BLENDMODE_MASK == 0x0F00);
_Static_assert(PRIMFLAG_ANTIALIAS_MASK == 0x1000);
_Static_assert(PRIMFLAG_SCREENTEX_MASK == 0x2000);
_Static_assert(PRIMFLAG_TEXWRAP_MASK   == 0x4000);
#endif

#ifdef __INPUT_H__
// make sure MYOSD_KEY enum matches ITEM_ID enum
_Static_assert(MYOSD_KEY_A == ITEM_ID_A);
_Static_assert(MYOSD_KEY_0 == ITEM_ID_0);
_Static_assert(MYOSD_KEY_F1 == ITEM_ID_F1);
_Static_assert(MYOSD_KEY_ESC == ITEM_ID_ESC);
_Static_assert(MYOSD_KEY_LCMD == ITEM_ID_LWIN);
_Static_assert(MYOSD_KEY_CANCEL == ITEM_ID_CANCEL);
#endif

#if defined(__cplusplus)
}
#endif

#endif


