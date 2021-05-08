//============================================================
//
//  libmame.h - PUBLIC interface to the LIBMAME core/library
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//  this is the PUBLIC interface used by MAME4iOS to talk to the MAME core
//  for historical reasons this interface is refered to as MYOSD
//  if it makes you feel better, just pretend MYOSD stands for
//  [M]ame e[Y]e[OS] [D]river (aka MAME-iOS-DRIVER)
//
//  FUNCTIONS:
//      myosd_main
//      myosd_get
//      myosd_set
//
//============================================================

#include <stdint.h>

#ifndef __LIBMAME_H__
#define __LIBMAME_H__

#if defined(__cplusplus)
extern "C" {
#endif

enum MYOSD_STATUS {
    MYOSD_UP=0x1,       MYOSD_LEFT=0x4,       MYOSD_DOWN=0x10,   MYOSD_RIGHT=0x40,
    MYOSD_START=1<<8,   MYOSD_SELECT=1<<9,    MYOSD_L1=1<<10,    MYOSD_R1=1<<11,
    MYOSD_A=1<<12,      MYOSD_B=1<<13,        MYOSD_X=1<<14,     MYOSD_Y=1<<15,
    MYOSD_L3=1<<16,     MYOSD_R3=1<<17,       MYOSD_L2=1<<18,    MYOSD_R2=1<<19,
    MYOSD_EXIT=1<<20,   MYOSD_OPTION=1<<21,   MYOSD_HOME=1<<22,  MYOSD_MENU=1<<23,
};

enum MYOSD_AXIS {
    MYOSD_AXIS_LX,
    MYOSD_AXIS_LY,
    MYOSD_AXIS_RX,
    MYOSD_AXIS_RY,
    MYOSD_AXIS_LZ,
    MYOSD_AXIS_RZ,
    MYOSD_AXIS_NUM
};

#define NUM_JOY 4
#define NUM_KEYS 256

// MYOSD INPUT STATE
typedef struct {
    // keyboard
    unsigned char keyboard[NUM_KEYS];

    // joystick(s)
    unsigned long joy_status[NUM_JOY];
    float joy_analog[NUM_JOY][MYOSD_AXIS_NUM];

    // mice
    unsigned long mouse_status[NUM_JOY];
    float mouse_x[NUM_JOY];
    float mouse_y[NUM_JOY];
    float mouse_z[NUM_JOY];

    // lightgun(s)
    unsigned long lightgun_status[NUM_JOY];
    float lightgun_x[NUM_JOY];
    float lightgun_y[NUM_JOY];
    
    // input profile for current machine
    int num_buttons;
    int num_ways;
    int num_players;
    int num_coins;
    int num_inputs;
    int num_mouse;
    int num_lightgun;
    int num_keyboard;
    
    // current input mode
    int input_mode;
    int keyboard_mode;

}   myosd_input_state;

// myosd input mode
enum myosd_input_mode
{
    MYOSD_INPUT_MODE_NORMAL,
    MYOSD_INPUT_MODE_UI
};

// myosd keyboard mode
enum myosd_keyboard_mode
{
    MYOSD_KEYBOARD_MODE_NORMAL
};

// myosd output
enum myosd_output_channel
{
    MYOSD_OUTPUT_ERROR,
    MYOSD_OUTPUT_WARNING,
    MYOSD_OUTPUT_INFO,
    MYOSD_OUTPUT_DEBUG,
    MYOSD_OUTPUT_VERBOSE,
    MYOSD_OUTPUT_LOG,
};

// subset of a internal game_driver structure we pass up to the UI/OSD layer
typedef struct
{
    unsigned int        type;                       /* game type */
    unsigned int        flags;                      /* MYOSD_GAME_INFO_ flags */
    const char *        source_file;                /* set this to __FILE__ */
    const char *        parent;                     /* if this is a clone, the name of the parent */
    const char *        name;                       /* short (16-character) name of the game */
    const char *        description;                /* full name of the game */
    const char *        year;                       /* year the game was released */
    const char *        manufacturer;               /* manufacturer of the game */
    const void *        rom_list;                   /* list of ROMs */
    const void *        input_list;                 /* machine input */
    const char *        software_list;              /* list of software */
} myosd_game_info;

enum MYOSD_GAME_TYPE
{
    MYOSD_GAME_TYPE_ARCADE,       // coin-operated machine for public use
    MYOSD_GAME_TYPE_CONSOLE,      // console system
    MYOSD_GAME_TYPE_COMPUTER,     // any kind of computer including home computers, minis, calculators, ...
    MYOSD_GAME_TYPE_OTHER,        // any other emulated system (e.g. clock, satellite receiver, ...)
};

enum MYOSD_GAME_INFO
{
    MYOSD_GAME_INFO_VERTICAL            = 1<<0,     // vertical video (aka TATE)
    MYOSD_GAME_INFO_NOT_WORKING         = 1<<1,     // not working
    MYOSD_GAME_INFO_IMPERFECT_GRAPHICS  = 1<<2,     // imperfect video
    MYOSD_GAME_INFO_IMPERFECT_SOUND     = 1<<3,     // imperfect sound
    MYOSD_GAME_INFO_BIOS                = 1<<4,     // this driver entry is a BIOS root
    MYOSD_GAME_INFO_SUPPORTS_SAVE       = 1<<5,     // system supports save states
    MYOSD_GAME_INFO_VECTOR              = 1<<6,     // SCREEN is VECTOR
};

// this is copy/clone of the render_primitive in render.h passed up to UI/OSD layer in myosd_video_draw
typedef struct _myosd_render_primitive myosd_render_primitive;
struct _myosd_render_primitive
{
    myosd_render_primitive* next;               /* pointer to next element */
    int                   type;                 /* type of primitive */
//  render_bounds         bounds;               /* bounds or positions */
    float                 bounds_x0;
    float                 bounds_y0;
    float                 bounds_x1;
    float                 bounds_y1;
//  render_color          color;                /* RGBA values */
    float                 color_a;
    float                 color_r;
    float                 color_g;
    float                 color_b;
    union {
        uint32_t          flags;                /* flags */
        struct {
            uint32_t      texorient:4;          /* MYOSD_ORIENTATION_ */
            uint32_t      texformat:4;          /* MYOSD_TEXFORMAT_ */
            uint32_t      blendmode:4;          /* MYOSD_BLENDMODE_ */
            uint32_t      antialias:1;          /* antialias flag */
            uint32_t      screentex:1;          /* SCREEN flag */
            uint32_t      texwrap:1;            /* texture wrap */
            uint32_t      unused:17;
        };
    };
    float                 width;                /* width (for line primitives) */
//  render_texinfo        texture;              /* texture info (for quad primitives) */
    void *                texture_base;         /* base of the data */
    uint32_t              texture_rowpixels;    /* pixels per row */
    uint32_t              texture_width;        /* width of the image */
    uint32_t              texture_height;       /* height of the image */
    const void*           texture_palette;      /* palette for PALETTE16 textures, LUTs for RGB15/RGB32 */
    uint32_t              texture_seqid;        /* sequence ID */
    uint32_t              texture_junk;         /* padding */
//  render_quad_texuv     texcoords;            /* texture coordinates (for quad primitives) */
    struct {float u,v;}   texcoords[4];
};

/* render primitive types */
enum
{
    MYOSD_RENDER_PRIMITIVE_LINE,          /* a single line */
    MYOSD_RENDER_PRIMITIVE_QUAD           /* a rectilinear quad */
};

/* texture formats */
enum
{
    MYOSD_TEXFORMAT_UNDEFINED = 0,        /* require a format to be specified */
    MYOSD_TEXFORMAT_PALETTE16,            /* 16bpp palettized, alpha ignored */
    MYOSD_TEXFORMAT_PALETTEA16,           /* 16bpp palettized, alpha respected */
    MYOSD_TEXFORMAT_RGB15,                /* 16bpp 5-5-5 RGB */
    MYOSD_TEXFORMAT_RGB32,                /* 32bpp 8-8-8 RGB */
    MYOSD_TEXFORMAT_ARGB32,               /* 32bpp 8-8-8-8 ARGB */
    MYOSD_TEXFORMAT_YUY16,                /* 16bpp 8-8 Y/Cb, Y/Cr in sequence */
    MYOSD_TEXFORMAT_MASK = 0x00F0,
};

/* blending modes */
enum
{
    MYOSD_BLENDMODE_NONE = 0,             /* no blending */
    MYOSD_BLENDMODE_ALPHA,                /* standard alpha blend */
    MYOSD_BLENDMODE_RGB_MULTIPLY,         /* apply source alpha to source pix, then multiply RGB values */
    MYOSD_BLENDMODE_ADD,                  /* apply source alpha to source pix, then add to destination */
    MYOSD_BLENDMODE_MASK = 0x0F00,
};

/* texorient */
enum
{
    MYOSD_ORIENTATION_FLIP_X  = 0x0001,  /* mirror everything in the X direction */
    MYOSD_ORIENTATION_FLIP_Y  = 0x0002,  /* mirror everything in the Y direction */
    MYOSD_ORIENTATION_SWAP_XY = 0x0004,  /* mirror along the top-left/bottom-right diagonal */
    MYOSD_ORIENTATION_MASK    = 0x000F,

    MYOSD_ORIENTATION_ROT0    = 0,
    MYOSD_ORIENTATION_ROT90   = (MYOSD_ORIENTATION_SWAP_XY | MYOSD_ORIENTATION_FLIP_X),   /* rotate clockwise 90 degrees */
    MYOSD_ORIENTATION_ROT180  = (MYOSD_ORIENTATION_FLIP_X  | MYOSD_ORIENTATION_FLIP_Y),   /* rotate 180 degrees */
    MYOSD_ORIENTATION_ROT270  = (MYOSD_ORIENTATION_SWAP_XY | MYOSD_ORIENTATION_FLIP_Y),   /* rotate counter-clockwise 90 degrees */
};

// MYOSD KEY CODES
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

// myosd_get and myosd_set - get and set global state from the MAME driver.

enum {
    MYOSD_VERSION,              // GET: MAME version number (ie 139 or 229)
    MYOSD_VERSION_STRING,       // GET: MAME version string (ie "0.139u1 (date)")
    MYOSD_DISPLAY_WIDTH,        // SET: maximum width and height of "screen" to display
    MYOSD_DISPLAY_HEIGHT,
    MYOSD_FPS,                  // GET, SET: show framerate
    MYOSD_SPEED,                // GET, SET: emulation speed (100 = 100%)
};
extern intptr_t myosd_get(int var);
extern void myosd_set(int var, intptr_t value);

// MYOSD app callback functions
typedef struct {

    void (*output_init)(void);
    void (*output_text)(int channel, const char* text);
    void (*output_exit)(void);

    void (*game_init)(myosd_game_info *info);
    void (*game_list)(myosd_game_info *games, int count);
    void (*game_exit)(void);
    
    void (*video_init)(int screen_width, int screen_height, int render_width, int render_height);
    void (*video_draw)(myosd_render_primitive* prim_list, int render_width, int render_height);
    void (*video_exit)(void);

    void (*input_init)(myosd_input_state* input, size_t state_size);
    void (*input_poll)(myosd_input_state* input, size_t state_size);
    void (*input_exit)(void);

    void (*sound_init)(int rate, int stereo);
    void (*sound_play)(void *buff, int len);
    void (*sound_exit)(void);

}   myosd_callbacks;

// main entry point
extern int myosd_main(int argc, char** argv, myosd_callbacks* callbacks, size_t callbacks_size);

#if defined(__cplusplus)
}
#endif

#endif
