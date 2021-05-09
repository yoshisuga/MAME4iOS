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

#include "emu.h"
#include "myosd.h"

#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>

/* Audio Resources */
//minimum required buffers for iOS AudioQueue

#define AUDIO_BUFFERS 3

int  myosd_display_width;
int  myosd_display_height;

int  myosd_fps = 0;
int  myosd_speed = 100;

static int lib_inited = 0;
static int soundInit = 0;

typedef struct AQCallbackStruct {
    AudioQueueRef queue;
    UInt32 frameCount;
    AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
    AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

AQCallbackStruct in;

static pthread_mutex_t sound_mutex     = PTHREAD_MUTEX_INITIALIZER;

static int global_low_latency_sound  = 1;

int sound_close_AudioQueue(void);
int sound_open_AudioQueue(int rate, int bits, int stereo);
int sound_close_AudioUnit(void);
int sound_open_AudioUnit(int rate, int bits, int stereo);
void queue(unsigned char *p,unsigned size);
unsigned short dequeue(unsigned char *p,unsigned size);
inline int emptyQueue(void);

static myosd_callbacks host_callbacks;
extern int ios_main(int argc, char**argv);  // in osdmain.c

// main LIBMAIN entry point, setup callbacks and then call main in osdmain
int myosd_main(int argc, char** argv, myosd_callbacks* callbacks, size_t callbacks_size)
{
    memcpy(&host_callbacks, callbacks, MIN(sizeof(host_callbacks), callbacks_size));
    if (argc == 0) {
        static char* args[] = {"libmame"};
        argc = 1;
        argv = args;
    }
    return ios_main(argc, argv);
}

// myosd_get
intptr_t myosd_get(int var)
{
    switch (var)
    {
        case MYOSD_VERSION:
            return 139;

        case MYOSD_VERSION_STRING:
            return (intptr_t)(void*)build_version;
            
        case MYOSD_FPS:
            return myosd_fps;
            
        case MYOSD_SPEED:
            return myosd_speed;
    }
    return 0;
}

// myosd_set
void myosd_set(int var, intptr_t value)
{
    switch (var)
    {
        case MYOSD_DISPLAY_WIDTH:
            myosd_display_width = value;
            break;
        case MYOSD_DISPLAY_HEIGHT:
            myosd_display_height = value;
            break;
        case MYOSD_FPS:
            myosd_fps = value;
            break;
        case MYOSD_SPEED:
            myosd_speed = value;
            break;
    }
}

void myosd_set_video_mode(int vis_width,int vis_height,int min_width,int min_height)
{
    mame_printf_debug("myosd_set_video_mode: %dx%d [%dx%d]\n",vis_width,vis_height,min_width,min_height);

    if (host_callbacks.video_init != NULL)
        host_callbacks.video_init(vis_width,vis_height,min_width,min_height);
}

void myosd_video_draw(render_primitive* prims, int width, int height)
{
    // myosd struct **must** match the internal render.h version.
    _Static_assert(sizeof(myosd_render_primitive) == sizeof(render_primitive), "");
    _Static_assert(offsetof(myosd_render_primitive, bounds_x0)    == offsetof(render_primitive, bounds), "");
    _Static_assert(offsetof(myosd_render_primitive, color_a)      == offsetof(render_primitive, color), "");
    _Static_assert(offsetof(myosd_render_primitive, texture_base) == offsetof(render_primitive, texture), "");
    _Static_assert(offsetof(myosd_render_primitive, texcoords)    == offsetof(render_primitive, texcoords), "");
    _Static_assert(offsetof(myosd_render_primitive, flags)        == offsetof(render_primitive, flags), "");
    _Static_assert(PRIMFLAG_TEXORIENT_MASK == MYOSD_ORIENTATION_MASK);
    _Static_assert(PRIMFLAG_TEXFORMAT_MASK == MYOSD_TEXFORMAT_MASK);
    _Static_assert(PRIMFLAG_BLENDMODE_MASK == MYOSD_BLENDMODE_MASK);
    _Static_assert(PRIMFLAG_ANTIALIAS_MASK == 0x1000);
    _Static_assert(PRIMFLAG_SCREENTEX_MASK == 0x2000);
    _Static_assert(PRIMFLAG_TEXWRAP_MASK   == 0x4000);

    _Static_assert(RENDER_PRIMITIVE_LINE == MYOSD_RENDER_PRIMITIVE_LINE);
    _Static_assert(RENDER_PRIMITIVE_QUAD == MYOSD_RENDER_PRIMITIVE_QUAD);
    
    _Static_assert(TEXFORMAT_PALETTE16   == MYOSD_TEXFORMAT_PALETTE16);
    _Static_assert(TEXFORMAT_PALETTEA16  == MYOSD_TEXFORMAT_PALETTEA16);
    _Static_assert(TEXFORMAT_RGB15       == MYOSD_TEXFORMAT_RGB15);
    _Static_assert(TEXFORMAT_RGB32       == MYOSD_TEXFORMAT_RGB32);
    _Static_assert(TEXFORMAT_ARGB32      == MYOSD_TEXFORMAT_ARGB32);
    _Static_assert(TEXFORMAT_YUY16       == MYOSD_TEXFORMAT_YUY16);

    _Static_assert(BLENDMODE_NONE        == MYOSD_BLENDMODE_NONE);
    _Static_assert(BLENDMODE_ALPHA       == MYOSD_BLENDMODE_ALPHA);
    _Static_assert(BLENDMODE_RGB_MULTIPLY== MYOSD_BLENDMODE_RGB_MULTIPLY);
    _Static_assert(BLENDMODE_ADD         == MYOSD_BLENDMODE_ADD);

    _Static_assert(ORIENTATION_FLIP_X    == MYOSD_ORIENTATION_FLIP_X);
    _Static_assert(ORIENTATION_FLIP_Y    == MYOSD_ORIENTATION_FLIP_Y);
    _Static_assert(ORIENTATION_SWAP_XY   == MYOSD_ORIENTATION_SWAP_XY);

    if (host_callbacks.video_draw != NULL)
        host_callbacks.video_draw((myosd_render_primitive*)prims, width, height);
}

// output channel callback, send output "up" to the app via myosd_output
static void myosd_output(void *param, const char *format, va_list argptr)
{
    _Static_assert(MYOSD_OUTPUT_ERROR == OUTPUT_CHANNEL_ERROR);
    _Static_assert(MYOSD_OUTPUT_WARNING == OUTPUT_CHANNEL_WARNING);
    _Static_assert(MYOSD_OUTPUT_INFO == OUTPUT_CHANNEL_INFO);
    _Static_assert(MYOSD_OUTPUT_DEBUG == OUTPUT_CHANNEL_DEBUG);
    _Static_assert(MYOSD_OUTPUT_VERBOSE == OUTPUT_CHANNEL_VERBOSE);

    if (host_callbacks.output_text != NULL)
    {
        char buffer[1204];
        vsnprintf(buffer, sizeof(buffer)-1, format, argptr);
        host_callbacks.output_text((int)(intptr_t)param, buffer);
    }
}

void myosd_poll_input_init(myosd_input_state* input)
{
    if (host_callbacks.input_init != NULL)
        host_callbacks.input_init(input, sizeof(myosd_input_state));
}

void myosd_poll_input(myosd_input_state* input)
{
    if (host_callbacks.input_poll != NULL)
        host_callbacks.input_poll(input, sizeof(myosd_input_state));
}

// convert game_driver to a myosd_game_info
static void get_game_info(myosd_game_info* info, const game_driver *driver)
{
    memset(info, 0, sizeof(myosd_game_info));
    info->type         = MYOSD_GAME_TYPE_ARCADE;
    info->source_file  = driver->source_file;
    info->parent       = driver->parent;
    info->name         = driver->name;
    info->description  = driver->description;
    info->year         = driver->year;
    info->manufacturer = driver->manufacturer;
    
    if (info->parent != NULL && info->parent[0] == '0' && info->parent[1] == 0)
        info->parent = "";
    
    if (driver->flags & (GAME_NOT_WORKING|GAME_UNEMULATED_PROTECTION))
        info->flags |= MYOSD_GAME_INFO_NOT_WORKING;

    if ((driver->flags & ORIENTATION_MASK) == ROT90 || (driver->flags & ORIENTATION_MASK) == ROT270)
        info->flags |= MYOSD_GAME_INFO_VERTICAL;
    
    if (driver->flags & (GAME_IS_BIOS_ROOT | GAME_NO_STANDALONE))
        info->flags |= MYOSD_GAME_INFO_BIOS;
    
    if (driver->flags & (GAME_WRONG_COLORS | GAME_IMPERFECT_COLORS | GAME_IMPERFECT_GRAPHICS | GAME_NO_COCKTAIL))
        info->flags |= MYOSD_GAME_INFO_IMPERFECT_GRAPHICS;

    if (driver->flags & (GAME_NO_SOUND | GAME_IMPERFECT_SOUND | GAME_NO_SOUND_HW))
        info->flags |= MYOSD_GAME_INFO_IMPERFECT_SOUND;

    if (driver->flags & GAME_SUPPORTS_SAVE)
        info->flags |= MYOSD_GAME_INFO_SUPPORTS_SAVE;

    // check for a vector game
    {
        machine_config *config = global_alloc(machine_config(driver->machine_config));
        for (const screen_device_config *devconfig = screen_first(*config); devconfig != NULL; devconfig = screen_next(devconfig))
        {
            if (devconfig->screen_type() == SCREEN_TYPE_VECTOR)
                info->flags |= MYOSD_GAME_INFO_VECTOR;
        }
        global_free(config);
    }
}

void myosd_set_game_info(const game_driver *driver_list[], int count)
{
    if (host_callbacks.game_list == NULL)
        return;

    myosd_game_info* myosd_games = (myosd_game_info*)malloc(sizeof(myosd_game_info) * count);

    // convert game_driver(s) to myosd_game_info(s)
    for (int i=0; i<count; i++)
        get_game_info(&myosd_games[i], driver_list[i]);

    host_callbacks.game_list(myosd_games, count);
    free(myosd_games);
}

void myosd_init(void)
{
	if (!lib_inited )
    {
        if (host_callbacks.output_init)
            host_callbacks.output_init();

        // capture all MAME output so we can send it to the app.
        for (int n=0; n<OUTPUT_CHANNEL_COUNT; n++)
            mame_set_output_channel((output_channel)n, myosd_output, (void*)n, NULL, NULL);

        mame_printf_debug("myosd_init\n");
        lib_inited = 1;
    }
}

void myosd_deinit(void)
{
    if (lib_inited)
    {
        mame_printf_debug("myosd_deinit\n");
        
        if (host_callbacks.output_exit)
            host_callbacks.output_exit();

        lib_inited = 0;
    }
}

void myosd_machine_init(running_machine *machine)
{
    int in_game = !(machine->gamedrv == &GAME_NAME(empty));
    
    if (host_callbacks.game_init != NULL && in_game)
    {
        myosd_game_info info;
        get_game_info(&info, machine->gamedrv);
        host_callbacks.game_init(&info);
    }
}

void myosd_machine_exit(running_machine *machine)
{
    int in_game = !(machine->gamedrv == &GAME_NAME(empty));

    if (host_callbacks.game_exit != NULL && in_game)
        host_callbacks.game_exit();
    
    if (host_callbacks.video_exit != NULL)
        host_callbacks.video_exit();

    if (host_callbacks.input_exit != NULL)
        host_callbacks.input_exit();
    
    // sound_exit is called in myosd_closeSound
}

void myosd_closeSound(void) {
    
    if (host_callbacks.sound_exit != NULL)
        return host_callbacks.sound_exit();
    
	if( soundInit == 1 )
	{
        mame_printf_debug("myosd_closeSound\n");

        if(global_low_latency_sound)
           sound_close_AudioUnit();
        else
           sound_close_AudioQueue();  

	   	soundInit = 0;
	}
}

void myosd_openSound(int rate,int stereo) {
    
    if (host_callbacks.sound_init != NULL)
        return host_callbacks.sound_init(rate, stereo);
    
	if( soundInit == 0)
	{
        if(global_low_latency_sound)
        {
            mame_printf_debug("myosd_openSound LOW LATENCY rate:%d stereo:%d \n",rate,stereo);
            sound_open_AudioUnit(rate, 16, stereo);
        }
        else
        {
            mame_printf_debug("myosd_openSound NORMAL rate:%d stereo:%d \n",rate,stereo);
            sound_open_AudioQueue(rate, 16, stereo);
        }
       
		soundInit = 1;
	}
}

void myosd_sound_play(void *buff, int len)
{
    if (host_callbacks.sound_play != NULL)
        return host_callbacks.sound_play(buff, len);

	queue((unsigned char *)buff,len);
}

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

