//============================================================
//
//  Copyright (c) 1996-2009, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#ifdef ANDROID
#include <android/log.h>
#endif

#include "osdcore.h"
//#include <malloc.h>
#include <unistd.h>
#include "render.h"
#include "emu.h"
#include "osdvideo.h"

#include <pthread.h>
#include "myosd.h"

static int screen_width;
static int screen_height;
static int vis_area_screen_width;
static int vis_area_screen_height;

static int curr_screen_width;
static int curr_screen_height;
static int curr_vis_area_screen_width;
static int curr_vis_area_screen_height;

static int hofs;
static int vofs;

static const render_primitive_list *currlist = NULL;
static int thread_stopping = 0;

static pthread_mutex_t cond_mutex     = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  condition_var   = PTHREAD_COND_INITIALIZER;
#ifdef ANDROID
static void draw_rgb565_draw_primitives(const render_primitive *primlist, void *dstdata, UINT32 width, UINT32 height, UINT32 pitch);
#else
static void draw_rgb555_draw_primitives(const render_primitive *primlist, void *dstdata, UINT32 width, UINT32 height, UINT32 pitch);
#endif

static void droid_ios_video_draw(void);
extern "C"
void droid_ios_video_thread(void);

//int video_threaded = 1;

void droid_ios_setup_video()
{

}

//static void droid_video_cleanup(running_machine *machine)
static void droid_ios_video_cleanup(running_machine &machine)
{
   	usleep(150000);
}

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

	//add_exit_callback(machine, droid_video_cleanup);
	machine->add_notifier(MACHINE_NOTIFY_EXIT, droid_ios_video_cleanup);
}

void droid_ios_video_draw()
{
	UINT8 *surfptr;
	INT32 pitch;
	int bpp;

	bpp = 2;
	vofs = hofs = 0;

	if(myosd_video_threaded)
	{
		pthread_mutex_lock( &cond_mutex );

		while(currlist == NULL)
		{
			pthread_cond_wait( &condition_var, &cond_mutex );
		}
	}

	if(curr_screen_width!= screen_width || curr_screen_height != screen_height ||
	   curr_vis_area_screen_width!= vis_area_screen_width || curr_vis_area_screen_height != vis_area_screen_height)
	{
		screen_width = curr_screen_width;
		screen_height = curr_screen_height;

		vis_area_screen_width = curr_vis_area_screen_width;
		vis_area_screen_height = curr_vis_area_screen_height;

		myosd_set_video_mode(screen_width,screen_height,vis_area_screen_width,vis_area_screen_height);
	}

	if(myosd_video_threaded)
	   pthread_mutex_unlock( &cond_mutex );

	if(myosd_video_threaded)
	   osd_lock_acquire(currlist->lock);

	surfptr = (UINT8 *) myosd_screen15;

	pitch = screen_width * 2;

	surfptr += ((vofs * pitch) + (hofs * bpp));

#ifdef ANDROID
	draw_rgb565_draw_primitives(currlist->head, surfptr, screen_width, screen_height, pitch / 2);
#else
	draw_rgb555_draw_primitives(currlist->head, surfptr, screen_width, screen_height, pitch / 2);
#endif

	if(myosd_video_threaded)
	  osd_lock_release(currlist->lock);

	myosd_video_flip();

	if(myosd_video_threaded)
	   pthread_mutex_lock( &cond_mutex );

	currlist = NULL;

	if(myosd_video_threaded)
	   pthread_mutex_unlock( &cond_mutex );
}

extern "C"
void droid_ios_video_thread()
{
    while (!thread_stopping && myosd_video_threaded)
	{
		droid_ios_video_draw();
	}
}

void droid_ios_video_render(render_target *our_target)
{
	int minwidth, minheight;
	int viswidth, visheight;

	if(myosd_video_threaded)
	   pthread_mutex_lock( &cond_mutex );

    if(currlist==NULL)
    {
		if(myosd_force_pxaspect)
		{
		   render_target_get_minimum_size(our_target, &minwidth, &minheight);
		   viswidth = minwidth;
		   visheight = minheight;
		}
		else if(myosd_res==1)
		{
		   render_target_get_minimum_size(our_target, &minwidth, &minheight);

		   int w,h;
		   render_target_compute_visible_area(our_target,minwidth,minheight,4/3,render_target_get_orientation(our_target),&w, &h);

		   viswidth = w;
		   visheight = h;

		   /*
		   float ratio = (float)w / (float)h;

		   int new_w = minheight *  ratio;
		   int new_h = minwidth * (1/ratio);

		   if(new_w > minwidth && new_w<=1024)
		   {
			   minwidth = new_w;
		   }
		   else
		   {
			   minheight = new_h;
		   }
		   */
		}
		else
		{
			minwidth = 320;minheight = 200;
			switch (myosd_res){
			   case 3:{minwidth = 320;minheight = 240;break;}
			   case 4:{minwidth = 400;minheight = 300;break;}
			   case 5:{minwidth = 480;minheight = 300;break;}
			   case 6:{minwidth = 512;minheight = 384;break;}
			   case 7:{minwidth = 640;minheight = 400;break;}
			   case 8:{minwidth = 640;minheight = 480;break;}
			   case 9:{minwidth = 800;minheight = 600;break;}
         case 10:{minwidth = 1024;minheight = 768;break;}
         case 11:{minwidth = 1280;minheight = 960;break;}
         case 12:{minwidth = 1440;minheight = 1080;break;} // Optimal HD: added for 1080P displays
         case 13:{minwidth = 1600;minheight = 1200;break;}
         case 14:{minwidth = 1920;minheight = 1440;break;}
         case 15:{minwidth = 2048;minheight = 1536;break;}
         case 16:{minwidth = 2880;minheight = 2160;break;} // Optimal UHD: added for Consumer 4K/UHD displays
			}
			render_target_compute_visible_area(our_target,minwidth,minheight,4/3,render_target_get_orientation(our_target),&minwidth,&minheight);
			viswidth = minwidth;
			visheight = minheight;
		}

		if(minwidth%2!=0)minwidth++;

		// make that the size of our target
		render_target_set_bounds(our_target, minwidth, minheight, 0);

		currlist = render_target_get_primitives(our_target);

		curr_screen_width = minwidth;
		curr_screen_height = minheight;
		curr_vis_area_screen_width = viswidth;
		curr_vis_area_screen_height = visheight;

		if(myosd_video_threaded)
		    pthread_cond_signal( &condition_var );
		else
			droid_ios_video_draw();
    }


    if(myosd_video_threaded)
	   pthread_mutex_unlock( &cond_mutex );
}

#define FUNC_PREFIX(x)		draw_rgb565_##x
#define PIXEL_TYPE			UINT16
#define SRCSHIFT_R			3
#define SRCSHIFT_G			2
#define SRCSHIFT_B			3
#define DSTSHIFT_R			11
#define DSTSHIFT_G			5
#define DSTSHIFT_B			0

#include "rendersw.c"

#define FUNC_PREFIX(x)		draw_rgb555_##x
#define PIXEL_TYPE			UINT16
#define SRCSHIFT_R			3
#define SRCSHIFT_G			3
#define SRCSHIFT_B			3
#define DSTSHIFT_R			10
#define DSTSHIFT_G			5
#define DSTSHIFT_B			0

#include "rendersw.c"
