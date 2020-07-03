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

#include "bt_joy.h"

#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>

/* Audio Resources */
//minimum required buffers for iOS AudioQueue

#define AUDIO_BUFFERS 3

int  myosd_fps = 1;
int  myosd_showinfo = 0;
int  myosd_sleep = 1;
int  myosd_inGame = 0;
int  myosd_exitGame = 0;
int  myosd_pause = 0;
int  myosd_exitPause = 0;
int  myosd_last_game_selected = 0;
int  myosd_frameskip_value = -1;
int  myosd_sound_value = 44100;
int  myosd_throttle = 1;
int  myosd_cheat = 1;
int  myosd_autosave = 0;
int  myosd_savestate = 0;
int  myosd_loadstate = 0;
int  myosd_waysStick = 8;
int  myosd_video_width = 320;
int  myosd_video_height = 240;
int  myosd_vis_video_width = 320;
int  myosd_vis_video_height = 240;
int  myosd_display_width;
int  myosd_display_height;
int  myosd_in_menu = 0;
int  myosd_res = 1;
int  myosd_force_pxaspect = 0;

int  myosd_pxasp1 = 1;
int  myosd_service = 0;
int  myosd_configure = 0;
int  myosd_mame_pause = 0;
int  myosd_reset = 0;

int myosd_video_threaded=-1;
int myosd_dbl_buffer=1;

int myosd_light_gun = 0;

int myosd_num_of_joys=0;

//int m4all_BplusX = 0;
//int m4all_hide_LR = 0;
//int m4all_landscape_buttons = 4;

int myosd_filter_favorites = 0;
int myosd_filter_clones = 0;
int myosd_filter_not_working = 0;

int myosd_filter_manufacturer = -1;
int myosd_filter_gte_year = -1;
int myosd_filter_lte_year = -1;
int myosd_filter_driver_source= -1;
int myosd_filter_category = -1;
char myosd_filter_keyword[MAX_FILTER_KEYWORD] = {'\0'};

int myosd_reset_filter = 0;

int myosd_num_buttons = 0;
int myosd_num_ways = 8;
int myosd_num_players = 0;
int myosd_num_coins = 0;
int myosd_num_inputs = 0;


int myosd_vsync = -1;
int myosd_autofire=1;
int myosd_hiscore=1;

int myosd_vector_bean2x = 1;
int myosd_vector_antialias = 1;
int myosd_vector_flicker = 0;

int  myosd_speed = 100;

char myosd_selected_game[MAX_GAME_NAME] = {'\0'};

extern "C" unsigned long read_mfi_controller(unsigned long res);

/*extern */float joy_analog_x[NUM_JOY][4];
/*extern */float joy_analog_y[NUM_JOY][2];

float lightgun_x[NUM_JOY];
float lightgun_y[NUM_JOY];

float mouse_x[NUM_JOY];
float mouse_y[NUM_JOY];

int myosd_mouse = 0;

static int lib_inited = 0;
static int soundInit = 0;
static int isPause = 0;
static int videot_running = 0;

unsigned long myosd_pad_status = 0;
unsigned long myosd_joy_status[NUM_JOY];
unsigned short myosd_ext_status = 0;

unsigned short *myosd_curr_screen = NULL;
unsigned short *myosd_prev_screen = NULL;
unsigned short myosd_screen[MYOSD_BUFFER_WIDTH * MYOSD_BUFFER_HEIGHT * 2];

typedef struct AQCallbackStruct {
    AudioQueueRef queue;
    UInt32 frameCount;
    AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
    AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

AQCallbackStruct in;

static pthread_t main_tid;
static pthread_mutex_t cond_mutex     = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  condition_var   = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t sound_mutex     = PTHREAD_MUTEX_INITIALIZER;

extern int video_thread_priority;
extern int video_thread_priority_type;
extern int global_low_latency_sound;

// OSD functions located in the iOS/tvOS app
extern "C" void iphone_Reset_Views(void);
extern "C" void iphone_UpdateScreen(void);
extern "C" int  iphone_DrawScreen(void*);
extern "C" void droid_ios_video_thread(void);

extern "C" void change_pause(int value);
void* threaded_video(void* args);
int sound_close_AudioQueue(void);
int sound_open_AudioQueue(int rate, int bits, int stereo);
int sound_close_AudioUnit(void);
int sound_open_AudioUnit(int rate, int bits, int stereo);
void queue(unsigned char *p,unsigned size);
unsigned short dequeue(unsigned char *p,unsigned size);
inline int emptyQueue(void);

void myosd_video_flip(void)
{
    if (myosd_dbl_buffer)
    {
        myosd_prev_screen = myosd_curr_screen;
        
        if (myosd_curr_screen != myosd_screen)
            myosd_curr_screen = myosd_screen;
        else
            myosd_curr_screen = myosd_screen + (MYOSD_BUFFER_WIDTH * MYOSD_BUFFER_HEIGHT);
    }

    iphone_UpdateScreen();
}

void myosd_set_video_mode(int width,int height,int vis_width,int vis_height)
{
     printf("myosd_set_video_mode: %dx%d [%dx%d]\n",width,height,vis_width,vis_height);

     myosd_video_width = width;
     myosd_video_height = height;
     myosd_vis_video_width = vis_width;
     myosd_vis_video_height = vis_height;

     iphone_Reset_Views();

  	 myosd_video_flip();
}

int myosd_video_draw(void* prims)
{
    return iphone_DrawScreen(prims);
}

unsigned long myosd_joystick_read(int n)
{
    unsigned long res=0;

    if(n==0 || myosd_pxasp1 && (myosd_num_of_joys==0 || myosd_num_of_joys==1))
    {
       res = myosd_pad_status;
        
       if(myosd_pxasp1 && myosd_num_of_joys==1)
       {
#ifdef BTJOY
           res |= bt_joy_poll(0);
#endif
    	   res |= myosd_joy_status[0];
       }

    }

#ifdef BTJOY
	if (n<myosd_num_of_joys)
        res |= bt_joy_poll(n);
#endif

    res |= myosd_joy_status[n];

	return res;
}

float myosd_joystick_read_analog(int n, char axis)
{
    float res = 0.0;
    
    if(n==0 || myosd_pxasp1 && (myosd_num_of_joys==0 || myosd_num_of_joys==1))
    {
#ifdef BTJOY
        if(myosd_pxasp1 && myosd_num_of_joys==1)
        {
            bt_joy_poll(0);
        }
#endif
        if(axis=='x') res = joy_analog_x[0][0];
        else if (axis=='y') res = joy_analog_y[0][0];
        else if(axis=='X') res = joy_analog_x[0][1];
        else if (axis=='Y') res = joy_analog_y[0][1];
        else if(axis=='z') res = joy_analog_x[0][2];
        else if(axis=='Z') res = joy_analog_x[0][3];
    }
    
    if (n<myosd_num_of_joys)
    {
#ifdef BTJOY
        bt_joy_poll(n);
#endif
        if(axis=='x') res = joy_analog_x[n][0];
        else if (axis=='y') res = joy_analog_y[n][0];
        else if(axis=='X') res = joy_analog_x[n][1];
        else if (axis=='Y') res = joy_analog_y[n][1];
        else if(axis=='z') res = joy_analog_x[n][2];
        else if(axis=='Z') res = joy_analog_x[n][3];
    }
    
    return res;
}

void myosd_init(void)
{
	int res = 0;
	struct sched_param param;

	if (!lib_inited )
    {
	   printf("myosd_init\n");

	   //myosd_set_video_mode(320,240,320,240);
        
       printf("myosd_dbl_buffer %d\n",myosd_dbl_buffer);
       myosd_curr_screen = myosd_screen;
       myosd_prev_screen = myosd_screen;

	   if(videot_running==0)
	   {
		   res = pthread_create(&main_tid, NULL, threaded_video, NULL);
		   if(res!=0)printf("Error setting creating pthread %d \n",res);

		   //param.sched_priority = 67;
		   //param.sched_priority = 50;
		   //param.sched_priority = 46;
		   //param.sched_priority = 100;
           
            printf("video priority %d\n",video_thread_priority);
		    param.sched_priority = video_thread_priority;
		    int policy;
		    if(video_thread_priority_type == 1)
		      policy = SCHED_OTHER;
		    else if(video_thread_priority_type == 2)
		      policy = SCHED_RR;
		    else
		      policy = SCHED_FIFO;

		   if(pthread_setschedparam(main_tid, policy, &param) != 0)
			  printf("Error setting pthread priority\n");
		   videot_running = 1;
	   }

   	   lib_inited = 1;
    }
}

void myosd_deinit(void)
{
    if (lib_inited )
    {
		printf("myosd_deinit\n");

    	lib_inited = 0;
    }
}

void myosd_closeSound(void) {
	if( soundInit == 1 )
	{
		printf("myosd_closeSound\n");

		
        if(global_low_latency_sound)
           sound_close_AudioUnit();
        else
           sound_close_AudioQueue();  

	   	soundInit = 0;
	}
}

void myosd_openSound(int rate,int stereo) {
	if( soundInit == 0)
	{
        if(global_low_latency_sound)
        {
            printf("myosd_openSound LOW LATENCY rate:%d stereo:%d \n",rate,stereo);
            sound_open_AudioUnit(rate, 16, stereo);
        }
        else
        {
		    printf("myosd_openSound NORMAL rate:%d stereo:%d \n",rate,stereo);
            sound_open_AudioQueue(rate, 16, stereo);
        }
       
		soundInit = 1;
	}
}

void myosd_sound_play(void *buff, int len)
{
	queue((unsigned char *)buff,len);
}

void change_pause(int value){
	pthread_mutex_lock( &cond_mutex );

	isPause = value;

    if(!isPause)
    {
		myosd_exitPause = 1;
        pthread_cond_signal( &condition_var );
    }

	pthread_mutex_unlock( &cond_mutex );
}

void myosd_check_pause(void){

	pthread_mutex_lock( &cond_mutex );

	while(isPause)
	{
		myosd_pause = 1;
        pthread_cond_wait( &condition_var, &cond_mutex );
	}
    myosd_pause = 0;

	pthread_mutex_unlock( &cond_mutex );
}

void* threaded_video(void* args)
{
	droid_ios_video_thread();
	return 0;
}

/////////////

//SQ buffers for sound between MAME and iOS AudioQueue. AudioQueue
//SQ callback reads from these.
//SQ Size: (48000/30fps) * bytesize * stereo * (3 buffers)
#define TAM (1600 * 2 * 2 * 3)
unsigned char ptr_buf[TAM];
unsigned head = 0;
unsigned tail = 0;

inline int fullQueue(unsigned short size){

    if(head < tail)
	{
		return head + size >= tail;
	}
	else if(head > tail)
	{
		return (head + size) >= TAM ? (head + size)- TAM >= tail : false;
	}
	else return false;
}

inline int emptyQueue(){
	return head == tail;
}

void queue(unsigned char *p,unsigned size){
        unsigned newhead;
		if(head + size < TAM)
		{
			memcpy(ptr_buf+head,p,size);
			newhead = head + size;
		}
		else
		{
			memcpy(ptr_buf+head,p, TAM -head);
			memcpy(ptr_buf,p + (TAM-head), size - (TAM-head));
			newhead = (head + size) - TAM;
		}
		pthread_mutex_lock(&sound_mutex);

		head = newhead;

		pthread_mutex_unlock(&sound_mutex);
}

unsigned short dequeue(unsigned char *p,unsigned size){

    	unsigned real;
    	unsigned datasize;

		if(emptyQueue())
		{
	    	memset(p,0,size);//TODO ver si quito para que no petardee
			return size;
		}

		pthread_mutex_lock(&sound_mutex);

		datasize = head > tail ? head - tail : (TAM - tail) + head ;
		real = datasize > size ? size : datasize;

		if(tail + real < TAM)
		{
			memcpy(p,ptr_buf+tail,real);
			tail+=real;
		}
		else
		{
			memcpy(p,ptr_buf + tail, TAM - tail);
			memcpy(p+ (TAM-tail),ptr_buf , real - (TAM-tail));
			tail = (tail + real) - TAM;
		}

		pthread_mutex_unlock(&sound_mutex);

        return real;
}

void checkStatus(OSStatus status){}


static void AQBufferCallback(void *userdata,
							 AudioQueueRef outQ,
							 AudioQueueBufferRef outQB)
{
	unsigned char *coreAudioBuffer;
	coreAudioBuffer = (unsigned char*) outQB->mAudioData;

	dequeue(coreAudioBuffer, in.mDataFormat.mBytesPerFrame * in.frameCount);
	outQB->mAudioDataByteSize = in.mDataFormat.mBytesPerFrame * in.frameCount;

	AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}


int sound_close_AudioQueue(){

	if( soundInit == 1 )
	{
		AudioQueueDispose(in.queue, true);
		soundInit = 0;
        head = 0;
        tail = 0;
	}
	return 1;
}

int sound_open_AudioQueue(int rate, int bits, int stereo){

    Float64 sampleRate = 48000.0;
    int i;
    UInt32 err;
    int fps;
    int bufferSize;

    if(rate==44100)
    	sampleRate = 44100.0;
    if(rate==32000)
    	sampleRate = 32000.0;
    else if(rate==22050)
    	sampleRate = 22050.0;
    else if(rate==11025)
    	sampleRate = 11025.0;

	//SQ Roundup for games like Galaxians
    //fps = ceil(Machine->drv->frames_per_second);
    fps = 60;//TODO

    if( soundInit == 1 )
    {
    	sound_close_AudioQueue();
    }

    soundInit = 0;
    memset (&in.mDataFormat, 0, sizeof (in.mDataFormat));
    in.mDataFormat.mSampleRate = sampleRate;
    in.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    in.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked;
    in.mDataFormat.mBytesPerPacket =  (stereo == 1 ? 4 : 2 );
    in.mDataFormat.mFramesPerPacket = 1;
    in.mDataFormat.mBytesPerFrame = (stereo ==  1? 4 : 2);
    in.mDataFormat.mChannelsPerFrame = (stereo == 1 ? 2 : 1);
    in.mDataFormat.mBitsPerChannel = 16;
	in.frameCount = rate / fps;

    err = AudioQueueNewOutput(&in.mDataFormat,
							  AQBufferCallback,
							  NULL,
							  NULL,
							  kCFRunLoopCommonModes,
							  0,
							  &in.queue);

    //printf("res %ld",err);

    bufferSize = in.frameCount * in.mDataFormat.mBytesPerFrame;

	for (i=0; i<AUDIO_BUFFERS; i++)
	{
		err = AudioQueueAllocateBuffer(in.queue, bufferSize, &in.mBuffers[i]);
		in.mBuffers[i]->mAudioDataByteSize = bufferSize;
		AudioQueueEnqueueBuffer(in.queue, in.mBuffers[i], 0, NULL);
	}

	soundInit = 1;
	err = AudioQueueStart(in.queue, NULL);

	return 0;

}

///////// AUDIO UNIT
#define kOutputBus 0
static AudioComponentInstance audioUnit;

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
	unsigned  char *coreAudioBuffer;
    
    int i;
    for (i = 0 ; i < ioData->mNumberBuffers; i++)
    {
        coreAudioBuffer = (unsigned char*) ioData->mBuffers[i].mData;
        //ioData->mBuffers[i].mDataByteSize = dequeue(coreAudioBuffer,inNumberFrames * 4);
        dequeue(coreAudioBuffer,inNumberFrames * 4);
        ioData->mBuffers[i].mDataByteSize = inNumberFrames * 4;
    }
    
    return noErr;
}

int sound_close_AudioUnit(){
    
	if( soundInit == 1 )
	{
		OSStatus status = AudioOutputUnitStop(audioUnit);
		checkStatus(status);
        
		AudioUnitUninitialize(audioUnit);
		soundInit = 0;
        head = 0;
        tail = 0;
	}
    
	return 1;
}

int sound_open_AudioUnit(int rate, int bits, int stereo){
    Float64 sampleRate = 48000.0;

    if( soundInit == 1 )
    {
        sound_close_AudioUnit();
    }
    
    if(rate==44100)
        sampleRate = 44100.0;
    if(rate==32000)
        sampleRate = 32000.0;
    else if(rate==22050)
        sampleRate = 22050.0;
    else if(rate==11025)
        sampleRate = 11025.0;
    
    //audioBufferSize =  (rate / 60) * 2 * (stereo==1 ? 2 : 1) ;
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    UInt32 flag = 1;
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    AudioStreamBasicDescription audioFormat;
    
    memset (&audioFormat, 0, sizeof (audioFormat));
    
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked;
    audioFormat.mBytesPerPacket =  (stereo == 1 ? 4 : 2 );
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerFrame = (stereo ==  1? 4 : 2);
    audioFormat.mChannelsPerFrame = (stereo == 1 ? 2 : 1);
    audioFormat.mBitsPerChannel = 16;
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    struct AURenderCallbackStruct callbackStruct;
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = NULL;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
    //ARRANCAR
    soundInit = 1;
    status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
    
    return 1;
}

