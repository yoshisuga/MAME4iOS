//============================================================
//
//  droidsound.c - Implementation of MAME sound routines
//
//  Copyright (c) 1996-2007, Nicola Salmoria and the MAME Team.
//  Visit http://mamedev.org for licensing and usage restrictions.
//
//  MAME4DROID MAME4iOS by David Valdeita (Seleuco)
//
//============================================================


#include <unistd.h>
#include <math.h>

// MAME headers
#include "emu.h"
#include "osdepend.h"

#include "osdsound.h"
#include "myosd-internal.h"

static int attenuation = 0;

static int	audio_init(running_machine *machine);
static void audio_cleanup_audio(running_machine &machine);
//static void	audio_cleanup_audio(running_machine *machine);

//============================================================
//	osd_start_audio_stream
//============================================================
void droid_ios_init_sound(running_machine *machine)
{

	// skip if sound disabled
	if (machine->sample_rate != 0)
	{
		if (audio_init(machine))
			return;

		//add_exit_callback(machine, audio_cleanup_audio);
		machine->add_notifier(MACHINE_NOTIFY_EXIT, audio_cleanup_audio);

		// set the startup volume
		osd_set_mastervolume(attenuation);
	}
	return;

}

//============================================================
//	Apply attenuation
//============================================================

static void att_memcpy(void *dest, INT16 *data, int bytes_to_copy)
{	
	int level= (int) (pow(10.0, (float) attenuation / 20.0) * 128.0);
	INT16 *d = (INT16 *)dest;
	int count = bytes_to_copy/2;
	while (count>0)
	{	
		*d++ = (*data++ * level) >> 7; /* / 128 */
		count--;
	}
}

//============================================================
//	osd_update_audio_stream
//============================================================

void osd_update_audio_stream(running_machine *machine, INT16 *buffer, int samples_this_frame)
{
	static unsigned char bufferatt[882*2*2*10];

	if (machine->sample_rate != 0 )
	{
		if(attenuation!=0)
		{
		    att_memcpy(bufferatt, buffer, samples_this_frame * sizeof(INT16) * 2);
		    myosd_sound_play(bufferatt,samples_this_frame * sizeof(INT16) * 2);
		}
		else
		{
			myosd_sound_play(buffer,samples_this_frame * sizeof(INT16) * 2);
		}
	}
}

//============================================================
//	osd_set_mastervolume
//============================================================

void osd_set_mastervolume(int _attenuation)
{

	// clamp the attenuation to 0-32 range
	if (_attenuation > 0)
		_attenuation = 0;
	if (_attenuation < -32)
		_attenuation = -32;

	attenuation = _attenuation;

}


static int audio_init(running_machine *machine)
{
   myosd_closeSound();
   myosd_openSound(machine->sample_rate,1);

   return 0;
}

//static void audio_cleanup_audio(running_machine *machine)
static void audio_cleanup_audio(running_machine &machine)
{
	// if nothing to do, don't do it
	if (machine.sample_rate == 0)
		return;

	myosd_closeSound();
}


