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

#define OPTION_HISCORE  "hiscore"

// globals in osd-ios.c
extern int  myosd_display_width;        // display width,height is the screen output resolution
extern int  myosd_display_height;       // ...set in the iOS app, to pick a good default render target size.

extern int  myosd_fps;
extern int  myosd_speed;

extern int  myosd_num_ways;

extern void myosd_init(void);
extern void myosd_deinit(void);
extern void myosd_machine_init(running_machine *machine);
extern void myosd_machine_exit(running_machine *machine);
extern void myosd_set_video_mode(int vis_width,int vis_height,int width, int height);
extern void myosd_video_draw(render_primitive*, int width, int height);
extern void myosd_poll_input_init(myosd_input_state* input);
extern void myosd_poll_input(myosd_input_state* input);
extern void myosd_set_game_info(const game_driver *info[], int game_count);
extern void myosd_openSound(int rate,int stereo);
extern void myosd_closeSound(void);
extern void myosd_sound_play(void *buff, int len);


#if defined(__cplusplus)
}
#endif

#endif


