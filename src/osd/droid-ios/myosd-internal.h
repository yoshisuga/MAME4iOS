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
#include "myosd.h"

extern void myosd_init(void);
extern void myosd_deinit(void);
extern void myosd_set_video_mode(int width,int height);
extern void myosd_video_draw(render_primitive*, int width, int height);
extern void myosd_poll_input(myosd_input_state* input);
extern void myosd_openSound(int rate,int stereo);
extern void myosd_closeSound(void);
extern void myosd_sound_play(void *buff, int len);



