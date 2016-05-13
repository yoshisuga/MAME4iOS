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

#include "myosd.h"

#include <unistd.h>
#include <fcntl.h>
#ifdef ANDROID
#include <android/log.h>
#endif
#include <pthread.h>

//#include "ui.h"
//#include "driver.h"

int  myosd_fps = 1;
int  myosd_showinfo = 1;
int  myosd_sleep = 0;
int  myosd_inGame = 0;
int  myosd_exitGame = 0;
int  myosd_pause = 0;
int  myosd_exitPause = 0;
int  myosd_last_game_selected = 0;
int  myosd_frameskip_value = 2;
int  myosd_sound_value = 48000;
int  myosd_throttle = 1;
int  myosd_cheat = 0;
int  myosd_autosave = 0;
int  myosd_savestate = 0;
int  myosd_loadstate = 0;
int  myosd_video_width = 0;
int  myosd_video_height = 0;
int  myosd_vis_video_width = 0;
int  myosd_vis_video_height = 0;
int  myosd_in_menu = 0;
int  myosd_res = 1;
int  myosd_force_pxaspect = 0;
int  myosd_waysStick;
int  myosd_pxasp1 = 0;
int  myosd_service = 0;
int  myosd_num_buttons = 0;

int myosd_num_of_joys=1;
int myosd_video_threaded=1;

int myosd_filter_favorites = 0;
int myosd_filter_clones = 0;
int myosd_filter_not_working = 0;

int myosd_filter_manufacturer = -1;
int myosd_filter_gte_year = -1;
int myosd_filter_lte_year = -1;
int myosd_filter_driver_source= -1;
int myosd_filter_category = -1;
extern char myosd_filter_keyword[MAX_FILTER_KEYWORD] = {'\0'};

int myosd_reset_filter = 0;

int myosd_num_ways = 8;

int myosd_vsync = -1;
int myosd_dbl_buffer=1;
int myosd_autofire=0;
int myosd_hiscore=0;

int myosd_vector_bean2x = 1;
int myosd_vector_antialias = 1;
int myosd_vector_flicker = 0;

int  myosd_speed = 100;

char myosd_selected_game[MAX_GAME_NAME] = {'\0'};

float joy_analog_x[4];
float joy_analog_y[4];

static int lib_inited = 0;
static int soundInit = 0;
static int isPause = 0;

unsigned long myosd_pad_status = 0;
unsigned long myosd_joy_status[4];
unsigned short myosd_ext_status = 0;

unsigned short 	*myosd_screen15 = NULL;

//////////////////////// android

unsigned short prev_screenbuffer[1024 * 1024];
unsigned short screenbuffer[1024 * 1024];
char globalpath[247]="/sdcard/ROMs/MAME4droid/";

static pthread_mutex_t cond_mutex     = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  condition_var   = PTHREAD_COND_INITIALIZER;

void change_pause(int value);
void setDblBuffer(void);


void (*dumpVideo_callback)(int emulating) = NULL;
void (*initVideo_callback)(void *buffer) = NULL;
void (*changeVideo_callback)(int newWidth,int newHeight,int newVisWidth,int newVisHeight) = NULL;

void (*openSound_callback)(int rate,int stereo) = NULL;
void (*dumpSound_callback)(void *buffer,int size) = NULL;
void (*closeSound_callback)(void) = NULL;

extern "C" void setVideoCallbacks(void (*init_video_java)(void *),void (*dump_video_java)(int), void (*change_video_java)(int,int,int,int))
{
#ifdef ANDROID
	__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "setVideoCallbacks");
#endif
	initVideo_callback = init_video_java;
	dumpVideo_callback = dump_video_java;
	changeVideo_callback = change_video_java;
}

extern "C" void setAudioCallbacks(void (*open_sound_java)(int,int), void (*dump_sound_java)(void *,int), void (*close_sound_java)())
{
#ifdef ANDROID
	__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "setAudioCallbacks");
#endif
    openSound_callback = open_sound_java;
    dumpSound_callback = dump_sound_java;
    closeSound_callback = close_sound_java;
}

extern "C"
void setPadStatus(int i, unsigned long pad_status)
{
	if(i==0)
	   myosd_pad_status = pad_status;

	myosd_joy_status[i]=pad_status;

	if(i==1 && pad_status && MYOSD_SELECT && myosd_num_of_joys<2)
		myosd_num_of_joys = 2;
	else if(i==2 && pad_status && MYOSD_SELECT && myosd_num_of_joys<3)
		myosd_num_of_joys = 3;
	else if(i==3 && pad_status && MYOSD_SELECT && myosd_num_of_joys<4)
		myosd_num_of_joys = 4;

	//__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "set_pad %ld",pad_status);
}

extern "C" void setGlobalPath(const char *path){

	int ret;
	/*
	char *directory = (char *)"/mnt/sdcard/app-data/com.seleuco.mame4droid2/";
	ret = chdir (directory);
    */
#ifdef ANDROID
	__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "setGlobalPath %s",path);
#endif

	strcpy(globalpath,path);
	ret = chdir (globalpath);
}

extern "C"
void setMyValue(int key,int value){


	//__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "setMyValue  %d %d",key,value);

	switch(key)
	{
	    case 1:
	    	myosd_fps = value;break;
	    case 2:
	    	myosd_exitGame = value;break;
	    case 8:
	    	myosd_showinfo = value;break;
	    case 9:
	 	    myosd_exitPause = value;break;
	    case 10:
	    	myosd_sleep = value;break;
	    case 11:
	    	change_pause(value);break;
	    case 12:
	    	myosd_frameskip_value = value;break;
	    case 13:
	    	myosd_sound_value = value;break;
	    case 14:
	    	myosd_throttle = value;break;
	    case 15:
	    	myosd_cheat = value;break;
	    case 16:
	    	myosd_autosave = value;break;
	    case 17:
	    	myosd_savestate = value;break;
	    case 18:
	    	myosd_loadstate = value;break;
	    case 20:
	    	myosd_res = value;break;
	    case 21:
	    	myosd_force_pxaspect = value;break;
	    case 22:
	    	myosd_video_threaded = value;break;
	    case 23:
	    	myosd_dbl_buffer = value;setDblBuffer();break;
	    case 24:
	    	myosd_pxasp1 = value;break;

	}
}

extern "C"
int getMyValue(int key){
	//__android_log_print(ANDROID_LOG_DEBUG, "libMAME4droid.so", "getMyValue  %d",key);

	switch(key)
	{
	    case 1:
	         return myosd_fps;
	    case 2:
	         return myosd_exitGame;
	    case 6:
	    	 return myosd_waysStick;
	    case 7:
	    	 return 0;
	    case 8:
	    	 return myosd_showinfo;
	    case 19:
	    	 return myosd_in_menu;
	    default :
	         return -1;
	}

}

extern "C"
void setMyAnalogData(int i, float v1, float v2){
	joy_analog_x[i]=v1;
	joy_analog_y[i]=v2;
	//__android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "set analog %d %f %f",i,v1,v2);
}

static void dump_video(void)
{
#ifdef ANDROID
    // __android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "dump_video");
#endif
	if(myosd_dbl_buffer)
	   memcpy(screenbuffer,prev_screenbuffer, myosd_video_width * myosd_video_height * 2);

	if(dumpVideo_callback!=NULL)
	   dumpVideo_callback(myosd_inGame);
}

/////////////

void myosd_video_flip(void)
{
	dump_video();
}

unsigned long myosd_joystick_read(int n)
{
    unsigned long res=0;

	if(myosd_num_of_joys==1)
	{
        if(myosd_pxasp1 || n==0)
		   res = myosd_pad_status;
	}
	else
	{
	   if (n<myosd_num_of_joys)
	   {
		  //res |= iOS_wiimote_check(&joys[n]);
		  res |= myosd_joy_status[n];
	   }
	}
  	
	return res;
}

float myosd_joystick_read_analog(int n, char axis)
{
	float res = 0.0;

	if(myosd_num_of_joys==1)
	{
		if(myosd_pxasp1 || n==0)
		{
			if(axis=='x')
				res = joy_analog_x[0];
			else if (axis=='y')
				res = joy_analog_y[0];
		}
	}
	else
	{
	    if (n<myosd_num_of_joys)
		{
		    if(axis=='x')
				res = joy_analog_x[n];
			else if (axis=='y')
				res = joy_analog_y[n];
		}
	}
    return res;
}

void myosd_set_video_mode(int width,int height,int vis_width, int vis_height)
{
#ifdef ANDROID
     __android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "set_video_mode: %d %d ",width,height);
#endif
    myosd_video_width = width;
    myosd_video_height = height;
    myosd_vis_video_width = vis_width;
    myosd_vis_video_height = vis_height;
    if(screenbuffer!=NULL)
	   memset(screenbuffer, 0, 1024*1024*2);
    if(prev_screenbuffer!=NULL)
	   memset(prev_screenbuffer, 0, 1024*1024*2);
    if(changeVideo_callback!=NULL)
	     changeVideo_callback(width, height,vis_width,vis_height);


  	myosd_video_flip();
}

void setDblBuffer(){
	if(myosd_dbl_buffer)
	   myosd_screen15=prev_screenbuffer;
	else
       myosd_screen15=screenbuffer;
}

void myosd_init(void)
{
    if (!lib_inited )
    {
#ifdef ANDROID
		__android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "init");
#endif
		setDblBuffer();

	   if(initVideo_callback!=NULL)
          initVideo_callback((void *)&screenbuffer);

	   myosd_set_video_mode(320,240,320,240);

   	   lib_inited = 1;
    }
}

void myosd_deinit(void)
{
    if (lib_inited )
    {
#ifdef ANDROID
		__android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "deinit");
#endif
    	lib_inited = 0;
    }
}

void myosd_closeSound(void) {
	if( soundInit == 1 )
	{
#ifdef ANDROID
		__android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "closeSound");
#endif
	   	if(closeSound_callback!=NULL)
		  closeSound_callback();
	   	soundInit = 0;
	}
}

void myosd_openSound(int rate,int stereo) {
	if( soundInit == 0)
	{
#ifdef ANDROID
		__android_log_print(ANDROID_LOG_DEBUG, "MAME4droid.so", "openSound rate:%d stereo:%d",rate,stereo);
#endif
		if(openSound_callback!=NULL)
		  openSound_callback(rate,stereo);
		soundInit = 1;
	}
}

void myosd_sound_play(void *buff, int len)
{
	if(dumpSound_callback!=NULL)
	   dumpSound_callback(buff,len);
}

void change_pause(int value){
	pthread_mutex_lock( &cond_mutex );

	isPause = value;

    if(!isPause)
    {
		pthread_cond_signal( &condition_var );
    }

	pthread_mutex_unlock( &cond_mutex );
}

void myosd_check_pause(void){

	pthread_mutex_lock( &cond_mutex );

	while(isPause)
	{
		pthread_cond_wait( &condition_var, &cond_mutex );
	}

	pthread_mutex_unlock( &cond_mutex );
}
