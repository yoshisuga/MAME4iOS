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
    
#define NUM_JOY 4
#define NUM_KEYS 256

extern const char * myosd_version;
extern int  myosd_fps;
extern int  myosd_showinfo;
extern int  myosd_pause;
extern int  myosd_exitPause;
extern int  myosd_waysStick;
extern int  myosd_video_width;
extern int  myosd_video_height;
extern int  myosd_vis_video_width;
extern int  myosd_vis_video_height;
extern int  myosd_display_width;        // display width,height is the screen output resolution
extern int  myosd_display_height;       // ...set in the iOS app, to pick a good default render target size.
extern int  myosd_force_pxaspect;

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

extern unsigned long myosd_joy_status[NUM_JOY];
extern unsigned char myosd_keyboard[NUM_KEYS];

extern float joy_analog_x[NUM_JOY][4];
extern float joy_analog_y[NUM_JOY][2];

extern float lightgun_x[NUM_JOY];
extern float lightgun_y[NUM_JOY];

extern float mouse_x[NUM_JOY];
extern float mouse_y[NUM_JOY];
extern float mouse_z[NUM_JOY];
extern unsigned long mouse_status[NUM_JOY];

extern int myosd_mouse;
extern int myosd_light_gun;

extern int myosd_last_game_selected;

extern int myosd_filter_clones;
extern int myosd_filter_not_working;

extern int myosd_num_buttons;
extern int myosd_num_ways;
extern int myosd_num_players;
extern int myosd_num_coins;
extern int myosd_num_inputs;

extern int myosd_hiscore;
extern int myosd_speed;
    
extern void myosd_init(void);
extern void myosd_deinit(void);
extern unsigned long myosd_joystick_read(int n);
extern float myosd_joystick_read_analog(int n, char axis);
extern void myosd_set_video_mode(int width,int height,int vis_width, int vis_height);
extern void myosd_video_draw(void*);
extern void myosd_closeSound(void);
extern void myosd_openSound(int rate,int stereo);
extern void myosd_sound_play(void *buff, int len);
extern void myosd_check_pause(void);
    
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
    uint32_t              texture_junk;        /* padding */
//  render_quad_texuv     texcoords;           /* texture coordinates (for quad primitives) */
    struct {float u,v;}   texcoords[4];
};
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

// define MYOSD KEY CODES to match ITEM_ID_* codes from input.h
enum myosd_keycode
{
    MYOSD_KEY_INVALID,
    MYOSD_KEY_A,
    MYOSD_KEY_B,
    MYOSD_KEY_C,
    MYOSD_KEY_D,
    MYOSD_KEY_E,
    MYOSD_KEY_F,
    MYOSD_KEY_G,
    MYOSD_KEY_H,
    MYOSD_KEY_I,
    MYOSD_KEY_J,
    MYOSD_KEY_K,
    MYOSD_KEY_L,
    MYOSD_KEY_M,
    MYOSD_KEY_N,
    MYOSD_KEY_O,
    MYOSD_KEY_P,
    MYOSD_KEY_Q,
    MYOSD_KEY_R,
    MYOSD_KEY_S,
    MYOSD_KEY_T,
    MYOSD_KEY_U,
    MYOSD_KEY_V,
    MYOSD_KEY_W,
    MYOSD_KEY_X,
    MYOSD_KEY_Y,
    MYOSD_KEY_Z,
    MYOSD_KEY_0,
    MYOSD_KEY_1,
    MYOSD_KEY_2,
    MYOSD_KEY_3,
    MYOSD_KEY_4,
    MYOSD_KEY_5,
    MYOSD_KEY_6,
    MYOSD_KEY_7,
    MYOSD_KEY_8,
    MYOSD_KEY_9,
    MYOSD_KEY_F1,
    MYOSD_KEY_F2,
    MYOSD_KEY_F3,
    MYOSD_KEY_F4,
    MYOSD_KEY_F5,
    MYOSD_KEY_F6,
    MYOSD_KEY_F7,
    MYOSD_KEY_F8,
    MYOSD_KEY_F9,
    MYOSD_KEY_F10,
    MYOSD_KEY_F11,
    MYOSD_KEY_F12,
    MYOSD_KEY_F13,
    MYOSD_KEY_F14,
    MYOSD_KEY_F15,
    MYOSD_KEY_ESC,
    MYOSD_KEY_TILDE,
    MYOSD_KEY_MINUS,
    MYOSD_KEY_EQUALS,
    MYOSD_KEY_BACKSPACE,
    MYOSD_KEY_TAB,
    MYOSD_KEY_OPENBRACE,
    MYOSD_KEY_CLOSEBRACE,
    MYOSD_KEY_ENTER,
    MYOSD_KEY_COLON,
    MYOSD_KEY_QUOTE,
    MYOSD_KEY_BACKSLASH,
    MYOSD_KEY_BACKSLASH2,
    MYOSD_KEY_COMMA,
    MYOSD_KEY_STOP,
    MYOSD_KEY_SLASH,
    MYOSD_KEY_SPACE,
    MYOSD_KEY_INSERT,
    MYOSD_KEY_DEL,
    MYOSD_KEY_HOME,
    MYOSD_KEY_END,
    MYOSD_KEY_PGUP,
    MYOSD_KEY_PGDN,
    MYOSD_KEY_LEFT,
    MYOSD_KEY_RIGHT,
    MYOSD_KEY_UP,
    MYOSD_KEY_DOWN,
    MYOSD_KEY_0_PAD,
    MYOSD_KEY_1_PAD,
    MYOSD_KEY_2_PAD,
    MYOSD_KEY_3_PAD,
    MYOSD_KEY_4_PAD,
    MYOSD_KEY_5_PAD,
    MYOSD_KEY_6_PAD,
    MYOSD_KEY_7_PAD,
    MYOSD_KEY_8_PAD,
    MYOSD_KEY_9_PAD,
    MYOSD_KEY_SLASH_PAD,
    MYOSD_KEY_ASTERISK,
    MYOSD_KEY_MINUS_PAD,
    MYOSD_KEY_PLUS_PAD,
    MYOSD_KEY_DEL_PAD,
    MYOSD_KEY_ENTER_PAD,
    MYOSD_KEY_PRTSCR,
    MYOSD_KEY_PAUSE,
    MYOSD_KEY_LSHIFT,
    MYOSD_KEY_RSHIFT,
    MYOSD_KEY_LCONTROL,
    MYOSD_KEY_RCONTROL,
    MYOSD_KEY_LALT,
    MYOSD_KEY_RALT,
    MYOSD_KEY_SCRLOCK,
    MYOSD_KEY_NUMLOCK,
    MYOSD_KEY_CAPSLOCK,
    MYOSD_KEY_LCMD,
    MYOSD_KEY_RCMD,
    MYOSD_KEY_MENU,
    MYOSD_KEY_CANCEL
};
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
