//============================================================
//
//  myosd.c - Implementation of osd stuff
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================

#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdarg.h>

#ifndef __MYOSD_H__
#define __MYOSD_H__

#if defined(__cplusplus)
extern "C" {
#endif

enum  { MYOSD_UP=0x1,       MYOSD_LEFT=0x4,       MYOSD_DOWN=0x10,   MYOSD_RIGHT=0x40,
        MYOSD_START=1<<8,   MYOSD_SELECT=1<<9,    MYOSD_L1=1<<10,    MYOSD_R1=1<<11,
        MYOSD_A=1<<12,      MYOSD_B=1<<13,        MYOSD_X=1<<14,     MYOSD_Y=1<<15,
        MYOSD_L3=1<<16,     MYOSD_R3=1<<17,       MYOSD_L2=1<<18,    MYOSD_R2=1<<19,
        MYOSD_EXIT=1<<20,   MYOSD_OPTION=1<<21,   MYOSD_HOME=1<<22,  MYOSD_MENU=1<<23,
};
    
#define MAX_FILTER_KEYWORD 30
#define MAX_GAME_NAME 14
#define NETPLAY_PORT 55435
#define NUM_JOY 4

#define MYOSD_BUFFER_WIDTH  3840
#define MYOSD_BUFFER_HEIGHT 2160
extern unsigned short *myosd_curr_screen;   // current screen being rendered.
extern unsigned short *myosd_prev_screen;   // current screen being drawn (we hope).
extern unsigned short myosd_screen[MYOSD_BUFFER_WIDTH * MYOSD_BUFFER_HEIGHT * 2];

extern int  myosd_fps;
extern int  myosd_showinfo;
extern int  myosd_sleep;
extern int  myosd_exitGame;
extern int  myosd_pause;
extern int  myosd_exitPause;
extern int  myosd_autosave;
extern int  myosd_cheat;
extern int  myosd_sound_value;
extern int  myosd_frameskip_value;
extern int  myosd_throttle;
extern int  myosd_savestate;
extern int  myosd_loadstate;
extern int  myosd_waysStick;
extern int  myosd_video_width;
extern int  myosd_video_height;
extern int  myosd_vis_video_width;
extern int  myosd_vis_video_height;
extern int  myosd_display_width;        // display width,height is the screen output resolution
extern int  myosd_display_height;       // ...set in the iOS app, to pick a good default render target size.
extern int  myosd_in_menu;
extern int  myosd_res;
extern int  myosd_force_pxaspect;
extern int  myosd_num_of_joys;
extern int  myosd_pxasp1;
extern int  myosd_video_threaded;
extern int  myosd_service;
extern int  myosd_configure;
extern int  myosd_mame_pause;           // NOTE myosd_pause is the state of the MAME thread, this is a request for MAME to PAUSE
extern int  myosd_reset;

//
// inGame   in_menu
//    0        0        - at top level select game menu (exit will quit app)
//    0        1        - in a menu (exit will exit menu)
//    0        2        - in configure input menu
//    1        0        - running a machine/game no menu is up (exit will quit app)
//    1        1        - running a machine/game with menu up (exit will exit menu)
//    1        2        - running a machine/game with configure input menu up
//
extern int  myosd_inGame;
extern int  myosd_in_menu;

extern unsigned long myosd_pad_status;
    
extern float joy_analog_x[NUM_JOY][4];
extern float joy_analog_y[NUM_JOY][2];

extern float lightgun_x[NUM_JOY];
extern float lightgun_y[NUM_JOY];

extern float mouse_x[NUM_JOY];
extern float mouse_y[NUM_JOY];

extern int myosd_mouse;
extern int myosd_light_gun;

extern unsigned short myosd_ext_status;
    
extern int myosd_last_game_selected;

extern int myosd_filter_favorites;
extern int myosd_filter_clones;
extern int myosd_filter_not_working;
extern int myosd_filter_manufacturer;
extern int myosd_filter_gte_year;
extern int myosd_filter_lte_year;
extern int myosd_filter_driver_source;
extern int myosd_filter_category;
extern char myosd_filter_keyword[MAX_FILTER_KEYWORD];
extern int myosd_reset_filter;

extern int myosd_num_buttons;
extern int myosd_num_ways;
extern int myosd_num_players;
extern int myosd_num_coins;
extern int myosd_num_inputs;

extern int myosd_vsync;
extern int myosd_dbl_buffer;
extern int myosd_autofire;
extern int myosd_hiscore;
    
extern int myosd_vector_bean2x;
extern int myosd_vector_antialias;
extern int myosd_vector_flicker;
    
extern int  myosd_speed;
    
extern char myosd_selected_game[MAX_GAME_NAME];

extern void myosd_init(void);
extern void myosd_deinit(void);
extern unsigned long myosd_joystick_read(int n);
extern float myosd_joystick_read_analog(int n, char axis);
extern void myosd_set_video_mode(int width,int height,int vis_width, int vis_height);
extern void myosd_video_flip(void);
extern int  myosd_video_draw(void*);
extern void myosd_closeSound(void);
extern void myosd_openSound(int rate,int stereo);
extern void myosd_sound_play(void *buff, int len);
extern void myosd_check_pause(void);
    
extern const char *myosd_array_main_manufacturers[];
extern const char *myosd_array_years[];
extern const char *myosd_array_main_driver_source[];
extern const char *myosd_array_categories[];

// myosd output
enum myosd_output_channel
{
    MYOSD_OUTPUT_ERROR,
    MYOSD_OUTPUT_WARNING,
    MYOSD_OUTPUT_INFO,
    MYOSD_OUTPUT_DEBUG,
    MYOSD_OUTPUT_VERBOSE,
};
extern void myosd_output(int channel, const char* text);
#ifdef __MACHINE_H__
_Static_assert(MYOSD_OUTPUT_ERROR == OUTPUT_CHANNEL_ERROR);
_Static_assert(MYOSD_OUTPUT_WARNING == OUTPUT_CHANNEL_WARNING);
_Static_assert(MYOSD_OUTPUT_INFO == OUTPUT_CHANNEL_INFO);
_Static_assert(MYOSD_OUTPUT_DEBUG == OUTPUT_CHANNEL_DEBUG);
_Static_assert(MYOSD_OUTPUT_VERBOSE == OUTPUT_CHANNEL_VERBOSE);
#endif

// subset of a internal game_driver structure we pass up to the UI/OSD layer
typedef struct
{
    const char *        source_file;                /* set this to __FILE__ */
    const char *        parent;                     /* if this is a clone, the name of the parent */
    const char *        name;                       /* short (8-character) name of the game */
    const char *        description;                /* full name of the game */
    const char *        year;                       /* year the game was released */
    const char *        manufacturer;               /* manufacturer of the game */
} myosd_game_info;
extern void myosd_set_game_info(myosd_game_info *info[], int game_count);

#ifdef __DRIVER_H__
// fail to compile if these structures get out of sync.
_Static_assert(offsetof(myosd_game_info, source_file)  == offsetof(game_driver, source_file), "");
_Static_assert(offsetof(myosd_game_info, parent)       == offsetof(game_driver, parent), "");
_Static_assert(offsetof(myosd_game_info, name)         == offsetof(game_driver, name), "");
_Static_assert(offsetof(myosd_game_info, description)  == offsetof(game_driver, description), "");
_Static_assert(offsetof(myosd_game_info, year)         == offsetof(game_driver, year), "");
_Static_assert(offsetof(myosd_game_info, manufacturer) == offsetof(game_driver, manufacturer), "");
#endif

// this is copy/clone of the render_primitive in render.h passed up to UI/OSD layer in myosd_video_draw
typedef struct _myosd_render_primitive myosd_render_primitive;
struct _myosd_render_primitive
{
    myosd_render_primitive* next;              /* pointer to next element */
    int                   type;                /* type of primitive */
//  render_bounds         bounds;              /* bounds or positions */
    float                 bounds_x0;
    float                 bounds_y0;
    float                 bounds_x1;
    float                 bounds_y1;
//  render_color          color;               /* RGBA values */
    float                 color_a;
    float                 color_r;
    float                 color_g;
    float                 color_b;
//  UINT32                flags;               /* flags */
    uint32_t              texorient:4;
    uint32_t              texformat:4;
    uint32_t              blendmode:4;
    uint32_t              antialias:1;
    uint32_t              screentex:1;
    uint32_t              texwrap:1;
    uint32_t              unused:17;
    float                 width;               /* width (for line primitives) */
//  render_texinfo        texture;             /* texture info (for quad primitives) */
    void *                texture_base;        /* base of the data */
    uint32_t              texture_rowpixels;   /* pixels per row */
    uint32_t              texture_width;       /* width of the image */
    uint32_t              texture_height;      /* height of the image */
    const void*           texture_palette;     /* palette for PALETTE16 textures, LUTs for RGB15/RGB32 */
    uint32_t              texture_seqid;       /* sequence ID */
//  render_quad_texuv     texcoords;           /* texture coordinates (for quad primitives) */
    struct {float u,v;}   texcoords[4];
};
#ifdef __RENDER_H__
// myosd struct **must** match the internal render.h version.
_Static_assert(sizeof(myosd_render_primitive) == sizeof(render_primitive), "");
_Static_assert(offsetof(myosd_render_primitive, bounds_x0)    == offsetof(render_primitive, bounds), "");
_Static_assert(offsetof(myosd_render_primitive, color_a)      == offsetof(render_primitive, color), "");
_Static_assert(offsetof(myosd_render_primitive, texture_base) == offsetof(render_primitive, texture), "");
_Static_assert(PRIMFLAG_TEXORIENT_MASK == 0x000F);
_Static_assert(PRIMFLAG_TEXFORMAT_MASK == 0x00F0);
_Static_assert(PRIMFLAG_BLENDMODE_MASK == 0x0F00);
_Static_assert(PRIMFLAG_ANTIALIAS_MASK == 0x1000);
_Static_assert(PRIMFLAG_SCREENTEX_MASK == 0x2000);
_Static_assert(PRIMFLAG_TEXWRAP_MASK   == 0x4000);
#endif

// NOTE if you get a re-defined enum error, you need to include emu.h before myosd.h
#ifndef __RENDER_H__
/* render primitive types */
enum
{
    RENDER_PRIMITIVE_LINE,          /* a single line */
    RENDER_PRIMITIVE_QUAD           /* a rectilinear quad */
};

/* texture formats */
enum
{
    TEXFORMAT_UNDEFINED = 0,        /* require a format to be specified */
    TEXFORMAT_PALETTE16,            /* 16bpp palettized, alpha ignored */
    TEXFORMAT_PALETTEA16,           /* 16bpp palettized, alpha respected */
    TEXFORMAT_RGB15,                /* 16bpp 5-5-5 RGB */
    TEXFORMAT_RGB32,                /* 32bpp 8-8-8 RGB */
    TEXFORMAT_ARGB32,               /* 32bpp 8-8-8-8 ARGB */
    TEXFORMAT_YUY16                 /* 16bpp 8-8 Y/Cb, Y/Cr in sequence */
};

/* blending modes */
enum
{
    BLENDMODE_NONE = 0,             /* no blending */
    BLENDMODE_ALPHA,                /* standard alpha blend */
    BLENDMODE_RGB_MULTIPLY,         /* apply source alpha to source pix, then multiply RGB values */
    BLENDMODE_ADD                   /* apply source alpha to source pix, then add to destination */
};

// orientation of bitmaps
#define ORIENTATION_FLIP_X  0x0001  /* mirror everything in the X direction */
#define ORIENTATION_FLIP_Y  0x0002  /* mirror everything in the Y direction */
#define ORIENTATION_SWAP_XY 0x0004  /* mirror along the top-left/bottom-right diagonal */

#define ORIENTATION_ROT0    0
#define ORIENTATION_ROT90   (ORIENTATION_SWAP_XY | ORIENTATION_FLIP_X)   /* rotate clockwise 90 degrees */
#define ORIENTATION_ROT180  (ORIENTATION_FLIP_X | ORIENTATION_FLIP_Y)    /* rotate 180 degrees */
#define ORIENTATION_ROT270  (ORIENTATION_SWAP_XY | ORIENTATION_FLIP_Y)   /* rotate counter-clockwise 90 degrees */

#endif

#if defined(__cplusplus)
}
#endif

#endif
