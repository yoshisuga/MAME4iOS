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
#include "osdvideo.h"

#include "myosd.h"

static int screen_width;
static int screen_height;
static int vis_area_screen_width;
static int vis_area_screen_height;

static int curr_screen_width;
static int curr_screen_height;
static int curr_vis_area_screen_width;
static int curr_vis_area_screen_height;

void droid_ios_init_video(running_machine *machine)
{
	curr_screen_width = 1;
	curr_screen_height = 1;
	curr_vis_area_screen_width = 1;
	curr_vis_area_screen_height = 1;

	screen_width = 1;
	screen_height = 1;
	vis_area_screen_width = 1;
	vis_area_screen_height = 1;
}

void droid_ios_video_draw(const render_primitive_list *currlist)
{
	if(curr_screen_width!= screen_width || curr_screen_height != screen_height ||
	   curr_vis_area_screen_width!= vis_area_screen_width || curr_vis_area_screen_height != vis_area_screen_height)
	{
		screen_width = curr_screen_width;
		screen_height = curr_screen_height;

		vis_area_screen_width = curr_vis_area_screen_width;
		vis_area_screen_height = curr_vis_area_screen_height;

		myosd_set_video_mode(vis_area_screen_width,vis_area_screen_height);
	}

    myosd_video_draw(currlist->head, screen_width, screen_height);
}

// HACK function to get current view from render target
// TODO: move it into render.c??
// TODO: make a function called render_target_has_art()??
layout_view * render_target_get_current_view(render_target *target)
{
    //return target->curview;
    return (layout_view *)((void**)target)[2];
}

void droid_ios_video_render(render_target *our_target)
{
	int minwidth, minheight;
	int viswidth, visheight;

    if(myosd_force_pxaspect)
    {
       render_target_get_minimum_size(our_target, &minwidth, &minheight);
       viswidth = minwidth;
       visheight = minheight;
    }
    else
    {
       render_target_get_minimum_size(our_target, &minwidth, &minheight);

       int w,h;
       render_target_compute_visible_area(our_target,minwidth,minheight,4/3,render_target_get_orientation(our_target),&w, &h);
       viswidth = w;
       visheight = h;
        
       layout_view * view = render_target_get_current_view(our_target);
        
       // if the current view has artwork we want to use the largest target we can, to fit the display
       // in the no art case, use the minimal buffer size needed, so it gets scaled up by hardware.
       if (layout_view_has_art(view) && myosd_display_width > viswidth && myosd_display_height > visheight)
       {
            if (myosd_display_width < myosd_display_height * viswidth / visheight)
            {
                visheight = visheight * myosd_display_width / viswidth;
                viswidth  = myosd_display_width;
            }
            else
            {
                viswidth  = viswidth * myosd_display_height / visheight;
                visheight = myosd_display_height;
            }
            minwidth = viswidth;
            minheight = visheight;
       }
    }

    curr_screen_width = minwidth;
    curr_screen_height = minheight;
    curr_vis_area_screen_width = viswidth;
    curr_vis_area_screen_height = visheight;

    // make that the size of our target
    render_target_set_bounds(our_target, minwidth, minheight, 0);
    // and draw the frame
    droid_ios_video_draw(render_target_get_primitives(our_target));
}
