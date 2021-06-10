//============================================================
//
//  Copyright (c) 1996-2009, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#include "osdcore.h"
#include <unistd.h>
#include "emu.h"
#include "render.h"
#include "rendlay.h"
#include "ui.h"
#include "osdvideo.h"

#include "myosd.h"

static int curr_min_width;      // minimum render target size
static int curr_min_height;     //
static int curr_vis_width;  // current external screen size
static int curr_vis_height;

void droid_ios_init_video(running_machine *machine)
{
    curr_min_width = 0;
    curr_min_height = 0;
	curr_vis_width = 0;
	curr_vis_height = 0;
}

void droid_ios_video_render(render_target *our_target)
{
    int vis_width,vis_height;
    int min_width,min_height;
    render_target_get_minimum_size(our_target, &min_width, &min_height);
    render_target_compute_visible_area(our_target,MAX(640,myosd_display_width),MAX(480,myosd_display_height),1.0,render_target_get_orientation(our_target),&vis_width, &vis_height);
    
    // check for a change in the min-size of render target *or* size of the vis screen
    if (min_width != curr_min_width || min_height != curr_min_height ||
        vis_width != curr_vis_width || vis_height != curr_vis_height) {
        
        curr_min_width = min_width;
        curr_min_height = min_height;
        curr_vis_width = vis_width;
        curr_vis_height = vis_height;

        myosd_set_video_mode(vis_width,vis_height,min_width,min_height);
    }
    
    render_target_set_bounds(our_target, vis_width, vis_height, 1.0);
    const render_primitive_list *list = render_target_get_primitives(our_target);
    myosd_video_draw(list->head, vis_width, vis_height);
}

