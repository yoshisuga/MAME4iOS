//============================================================
//
//  Copyright (c) 1996-2009, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#ifndef _OSDVIDEO_H_
#define _OSDVIDEO_H_

#include "render.h"

void droid_ios_init_video(running_machine *machine);
void droid_ios_setup_video(void);
void droid_ios_video_render(render_target *);

#endif
