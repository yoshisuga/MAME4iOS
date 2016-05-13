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

#include "osdepend.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

//#include "render.h"
#include "clifront.h"
#include "emu.h"
#include "emuopts.h"
//#include "options.h"
#include "ui.h"
#include "uimenu.h"
//#include "driver.h"

#include "osdinput.h"
#include "osdsound.h"
#include "osdvideo.h"
#include "myosd.h"

#include "netplay.h"

/*
void mylog(char * msg){
	  FILE *f;
	  f=fopen("log.txt","a+");
	  if (f) {
		  fprintf(f,"%s\n",msg);
		  fclose(f);
		  sync();
	  }
}*/

//============================================================
//  GLOBALS
//============================================================

int isGridlee = 0;

const char *myosd_array_main_manufacturers[] = {
    "Alpha Denshi","Amcoe","American Laser Games","Arcadia Systems","Aristocrat","Atari","Atlus",
    "Barcrest","Bally/Sente","Banpresto","BFM","C.M.C.","Cal Omega",
    "Capcom","Century Electronics","Cinematronics","Comad","Data East","Dooyong",
    "Dynax","Exidy","Eolith","Face","Gaelco","Gremlin","Greyhound Electronics","Gottlieb",
    "High Video","Home Data","Igrosoft","Incredible Technologies","Impera","Irem","IGS",
    "IGT","Jaleco","JPM","Leland","Kaneko","Konami","Merit","Metro",
    "Midway","Mitchell","Namco","Nichibutsu","Nintendo","NMK","Noraut","Playmark","Psikyo","Rare","Raizing / Eighting",
    "Sammy","Sega","Seibu Kaihatsu","SemiCom",
    "Seta","SNK","Status Games","Stern","Subsino","Success","Sun Electronics","SunA","TAB Austria","TAD Corporation",
    "Taito","Technos","Tecmo","Tehran","Toaplan",
    "Universal","UPL","V-System","Video System","Visco","Williams","Yun Sung","Zaccaria",
    "Other",""
};


const char *myosd_array_years[] ={
    "1975","1976","1977","1978","1979","1980","1981","1982","1983","1984","1985",
    "1986","1987","1988","1989","1990","1991","1992","1993","1994","1995","1996",
    "1997","1998","1999","2000","2001","2002","2003","2004","2005","2006","2007",
    ""
};

const char *myosd_array_main_driver_source[] = {
    "8080bw","aerofgt","alpha68k","arcadia","aristmk4","armedf","astrocde","asuka","atarisy1","atarisy2","ataxx",
    "bagman","balsente","bfm_sc2","blockade","btime","calomega","cave","cclimber","centiped","champbas","cinemat",
    "cischeat","cojag","cosmic","cps1","cps2","cps3","cubocd32","cvs","ddenlovr","ddragon","dec0","dec8","deco32",
    "decocass","djmain","dkong","docastle","dooyong","dynax","eolith","equites","esd16","exidy","exidy440","fastfred",
    "fromance","funworld","galaxold","galdrvr","galpanic","gameplan","gei","goldnpkr","goldstar","gottlieb","harddriv",
    "highvdeo","homedata","igs011","igspoker","itech32","itech8","jack","jalmah","jpmimpct","kaneko16","konamigv",
    "konamigx","ksys573","kyugo","ladybug","leland","lethalj","liberate","m62","m72","m90","m92","mappy","marineb",
    "maxaflex","mcr","mcr3","mcr68","megaplay","megasys1","merit","meritm","metro","midtunit","midwunit","midyunit",
    "mitchell","ms32","multfish","multigam","mw8080bw","mystwarr","namcona1","namconb1","namcos1","namcos11","namcos12",
    "namcos2","namcos22","namcos86","nbmj8688","nbmj8891","nbmj8991","nbmj9195","nemesis","neodrvr","ninjakd2","nmg5",
    "nmk16","norautp","ojankohs","pacman","paradise","peplus","pgm","playch10","playmark","psikyo","psikyo4","psikyosh",
    "qix","rallyx","royalmah","scobra","scramble","seattle","segac2","segae","segag80r","segag80v","segas16a",
    "segas16b","segas18","segas24","segas32","segaxbd","segaybd","seibuspi","seta","seta2","sfbonus","simpl156",
    "snesb","snk","snk6502","snowbros","srmp2","ssv","statriv2","stv","subsino","suprnova","system1","taito_b",
    "taito_f2","taito_f3","taito_l","taito_x","taito_z","taitogn","taitosj","tetrisp2","thepit","tickee","tmaster",
    "tmnt","tnzs","toaplan1","toaplan2","tsamurai","tumbleb","usgames","vamphalf","vicdual","vsnes","warpwarp","williams",
    "zaxxon","zn","zodiack",
    "Other",""
};

const char *myosd_array_categories[] = {
    "Ball & Paddle","Breakout","Casino","Climbing",
    "Driving","Driving / 1st Person","Driving / Boat","Driving / Plane","Driving / Race","Driving / Race (chase view)",
    "Driving / Race (chase view) Bike","Driving / Race 1st P Bike","Driving / Race 1st Person","Driving / Race Bike","Driving / Race Track",
    "Fighter","Fighter / 2.5D","Fighter / 2D","Fighter / 3D","Fighter / Field","Fighter / Misc.","Fighter / Multiplay","Fighter / Versus",
    "Fighter / Versus Co-op","Fighter / Vertical",
    "Maze","Maze / Digging","Maze / Driving","Maze / Fighter","Maze / Outline","Maze / Shooter Large","Maze / Shooter Small","Maze / Surround",
    "Mini-Games","Misc.","Multiplay",
    "Pinball","Platform","Platform / Fighter","Platform / Fighter Scrolling","Platform / Run Jump","Platform / Run Jump Scrolling",
    "Platform / Shooter","Platform / Shooter Scrolling",
    "Puzzle","Puzzle / Cards","Puzzle / Drop","Puzzle / Match","Puzzle / Maze","Puzzle / Outline","Puzzle / Sliding","Puzzle / Toss",
    "Quiz","Quiz / Chinese","Quiz / English","Quiz / French","Quiz / German","Quiz / Italian","Quiz / Japanese","Quiz / Korean",
    "Quiz / Music English","Quiz / Music Japanese","Quiz / Spanish",
    "Rhythm","Rhythm / Dance","Rhythm / Instruments",
    "Shooter","Shooter / 1st Person","Shooter / 3rd Person","Shooter / Command","Shooter / Driving","Shooter / Driving (chase view)",
    "Shooter / Driving 1st Person","Shooter / Driving Diagonal","Shooter / Driving Horizontal","Shooter / Driving Vertical",
    "Shooter / Field","Shooter / Flying","Shooter / Flying (chase view)","Shooter / Flying 1st Person",
    "Shooter / Flying Diagonal","Shooter / Flying Horizontal","Shooter / Flying Vertical","Shooter / Gallery","Shooter / Gun",
    "Shooter / Misc.","Shooter / Misc. Horizontal","Shooter / Misc. Vertical","Shooter / Versus","Shooter / Walking","Sports",
    "Sports / Armwrestling","Sports / Baseball","Sports / Basketball","Sports / Bowling","Sports / Boxing","Sports / Bull Fighting",
    "Sports / Darts","Sports / Dodgeball","Sports / Fishing","Sports / Football Amer.","Sports / Football Rugby","Sports / Golf",
    "Sports / Handball","Sports / Hang Gliding","Sports / Hockey","Sports / Horse Racing","Sports / Horseshoes","Sports / Multiplay",
    "Sports / Ping pong","Sports / Pool","Sports / Shuffleboard","Sports / Skateboarding","Sports / Skiing","Sports / SkyDiving",
    "Sports / Soccer","Sports / Sumo","Sports / Swimming","Sports / Tennis","Sports / Track & Field","Sports / VolleyBall",
    "Sports / Wrestling",
    "Tabletop","Tabletop / Hanafuda","Tabletop / Mahjong","Tabletop / Othello","Tabletop / Renju","Tabletop / Shougi",
    ""
};

// a single rendering target
static render_target *our_target;


static const options_entry droid_mame_options[] =
{
	{ "initpath", ".;/mame", 0, "path to ini files" },
	{ NULL, NULL, OPTION_HEADER, "DROID OPTIONS" },
	{ "safearea(0.01-1)", "1.0", 0, "Adjust video for safe areas on older TVs (.9 or .85 are usually good values)" },
	{ NULL }
};

//============================================================
//  FUNCTION PROTOTYPES
//============================================================

//void osd_exit(running_machine *machine);
static void osd_exit(running_machine &machine);

//============================================================
//  main
//============================================================

#if defined(ANDROID)
extern "C"
int android_main  (int argc, char **argv)
#elif defined(IOS)
extern "C"
int iOS_main  (int argc, char **argv)
#else
int main(int argc, char **argv)
#endif
{
	static char *args[255];	int n=0;
	int ret;
	FILE *f;
    
	printf("Iniciando\n");
    
    
	myosd_init();
    
	while(1)
	{
		droid_ios_setup_video();
        
        // cli_execute does the heavy lifting; if we have osd-specific options, we
        // would pass them as the third parameter here
		n=0;
		args[n]= (char *)"mame4x";n++;

		//args[n]= (char *)"starforc"; n++;
		//args[n]= (char *)"1944"; n++;
		//args[n]= (char *)"mslug3"; n++;
        //args[n]= (char *)"dino"; n++;
		//args[n]= (char *)"outrun"; n++;
		//args[n]= (char *)"-autoframeskip"; n++;
		//args[n]= (char *)"-noautoframeskip"; n++;
		//args[n]= (char *)"-nosound"; n++;
		//args[n]= (char *)"-novideo"; n++;
		//args[n]= (char *)"-nosleep"; n++;
        //args[n]= (char *)"-autosave"; n++;
		//args[n]= (char *)"-sleep"; n++;
		//args[n]= (char *)"-jdz"; n++;args[n]= (char *)"0.0"; n++;
		//args[n]= (char *)"-jsat"; n++;args[n]= (char *)"1.0"; n++;
		//args[n]= (char *)"-joystick_deadzone"; n++;args[n]= (char *)"0.0"; n++;
		args[n]= (char *)"-nocoinlock"; n++;
        
        if(isGridlee){
            args[n]= (char *)"gridlee"; n++;
        }
        
        netplay_t *handle = netplay_get_handle();
        if(handle->has_connection)
        {
            if(!handle->has_begun_game)
            {
                args[n]= (char *)handle->game_name; n++;
            }
            else
            {
                char buf[256];
                sprintf(buf,"%s not found!",handle->game_name);
                handle->netplay_warn(buf);
                handle->has_begun_game = 0;
                handle->has_connection = 0;
            }
        }
                
        if(myosd_reset_filter==0)
        {
            f=fopen("mame4x.cfg","r");
            if (f) {
                fscanf(f,"%d",&myosd_last_game_selected);
                fclose(f);
            }
        }
        else
        {
            myosd_last_game_selected = 0;
            f=fopen("mame4x.cfg","w");
            if (f) {
                fprintf(f,"%d",myosd_last_game_selected);
                fclose(f);
                sync();
            }
            myosd_reset_filter = 0;
        }
        
        ret = cli_execute(n, args, droid_mame_options);
        
        f=fopen("mame4x.cfg","w");
        if (f) {
            fprintf(f,"%d",myosd_last_game_selected);
            fclose(f);
            sync();
        }
	}
    
	myosd_deinit();
    
	return ret;
}

//============================================================
//  osd_init
//============================================================

void osd_init(running_machine *machine)
{

	//add_exit_callback(machine, osd_exit);
	machine->add_notifier(MACHINE_NOTIFY_EXIT, osd_exit);

	our_target = render_target_alloc(machine, NULL, 0);
	if (our_target == NULL)
		fatalerror("Error creating render target");

	myosd_inGame = !(machine->gamedrv == &GAME_NAME(empty));
    
	options_set_bool(mame_options(), OPTION_CHEAT,myosd_cheat,OPTION_PRIORITY_CMDLINE);
    options_set_bool(mame_options(), OPTION_AUTOSAVE,myosd_autosave,OPTION_PRIORITY_CMDLINE);
    options_set_bool(mame_options(), OPTION_SOUND,myosd_sound_value != -1,OPTION_PRIORITY_CMDLINE);
    if(myosd_sound_value!=-1)
       options_set_int(mame_options(), OPTION_SAMPLERATE,myosd_sound_value,OPTION_PRIORITY_CMDLINE);
    
    options_set_float(mame_options(), OPTION_BEAM,myosd_vector_bean2x ? 2.5 : 1.0, OPTION_PRIORITY_CMDLINE);
    options_set_float(mame_options(), OPTION_FLICKER,myosd_vector_flicker ? 0.4 : 0.0, OPTION_PRIORITY_CMDLINE);
    options_set_bool(mame_options(), OPTION_ANTIALIAS,myosd_vector_antialias,OPTION_PRIORITY_CMDLINE);
    
	droid_ios_init_input(machine);
	droid_ios_init_sound(machine);
	droid_ios_init_video(machine);
    
    netplay_t *handle = netplay_get_handle();
        
    if(handle->has_connection)
    {
        handle->has_begun_game = 1;
    }
}

//void osd_exit(running_machine *machine)
static void osd_exit(running_machine &machine)
{
	if (our_target != NULL)
		render_target_free(our_target);
	our_target = NULL;
}

void osd_update(running_machine *machine, int skip_redraw)
{
    
    if (!skip_redraw && our_target!=NULL)
	{
		droid_ios_video_render(our_target);
	}
    
    netplay_t *handle = netplay_get_handle();
    
    attotime current_time = timer_get_time(machine);
    
    //char m[256];
    //sprintf(m,"fr: %d emutime sec:%d ms: %d\n",fr,current_time.seconds,(int)(current_time.attoseconds / ATTOSECONDS_PER_MILLISECOND));
    //mylog(m);
            
    netplay_pre_frame_net(handle);

	droid_ios_poll_input(machine);
    
    netplay_post_frame_net(handle);
    
    if(handle->has_connection && handle->has_begun_game && current_time.seconds==0 && current_time.attoseconds==0)
    {
        printf("Not emulation...\n");
        handle->frame = 0;
        handle->target_frame = 0;
    }

	myosd_check_pause();
}

//============================================================
//  osd_wait_for_debugger
//============================================================

void osd_wait_for_debugger(running_device *device, int firststop)
{
	// we don't have a debugger, so we just return here
}


