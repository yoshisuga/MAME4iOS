/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */

#include "myosd.h"
#import "EmulatorController.h"
#import "HelpController.h"
#import "OptionsController.h"
#import "DonateController.h"
#import "iCadeView.h"
#import "DebugView.h"
#import "AnalogStick.h"
#import "AnalogStick.h"
#import "LayoutView.h"
#import "LayoutData.h"
#ifdef BTJOY
#import "BTJoyHelper.h"
#endif
#import <pthread.h>
#import "NetplayGameKit.h"
#import "UIView+Toast.h"
#import "DeviceScreenResolver.h"
#import "Bootstrapper.h"

// mfi Controllers
NSMutableArray *controllers;
int mfiBtnStates[10][NUM_BUTTONS];
int mfiCyclesAfterButtonPressed[10][NUM_BUTTONS];

// Turbo functionality
int cyclesAfterButtonPressed[NUM_BUTTONS];
int turboBtnEnabled[NUM_BUTTONS];

// On-screen touch gamepad button states
int btnStates[NUM_BUTTONS];

// Touch Directional Input tracking
int touchDirectionalCyclesAfterMoved = 0;

int g_isIpad = 0;
int g_isIphone5 = 0;

int g_emulation_paused = 0;
int g_emulation_initiated=0;

int g_joy_used = 0;
int g_iCade_used = 0;
#ifdef BTJOY
int g_btjoy_available = 1;
#else
int g_btjoy_available = 0;
#endif
int g_menu_option = MENU_NONE;

int g_enable_debug_view = 0;
int g_controller_opacity = 50;

int g_device_is_landscape = 0;

int g_pref_smooth_land = 0;
int g_pref_smooth_port = 0;
int g_pref_keep_aspect_ratio_land = 0;
int g_pref_keep_aspect_ratio_port = 0;

int g_pref_tv_filter_land = 0;
int g_pref_tv_filter_port = 0;

int g_pref_scanline_filter_land = 0;
int g_pref_scanline_filter_port = 0;

int g_pref_animated_DPad = 0;
int g_pref_4buttonsLand = 0;
int g_pref_full_screen_land = 1;
int g_pref_full_screen_port = 1;

int g_pref_hide_LR=0;
int g_pref_BplusX=0;
int g_pref_full_num_buttons=4;
int g_pref_skin = 1;
int g_pref_BT_DZ_value = 2;
int g_pref_touch_DZ = 1;

int g_pref_input_touch_type = TOUCH_INPUT_DSTICK;
int g_pref_analog_DZ_value = 2;
int g_pref_ext_control_type = 1;

int g_pref_aplusb = 0;

int g_pref_nativeTVOUT = 1;
int g_pref_overscanTVOUT = 1;

int g_pref_lightgun_enabled = 1;
int g_pref_lightgun_bottom_reload = 0;

int g_pref_touch_analog_enabled = 1;
int g_pref_touch_analog_hide_dpad = 1;
int g_pref_touch_analog_hide_buttons = 0;
float g_pref_touch_analog_sensitivity = 500.0;

int g_pref_touch_directional_enabled = 0;

int g_skin_data = 1;

float g_buttons_size = 1.0f;
float g_stick_size = 1.0f;

int global_low_latency_sound = 0;
static int main_thread_priority = 46;
int video_thread_priority = 46;
static int main_thread_priority_type = 1;
int video_thread_priority_type = 1;

int prev_myosd_light_gun = 0;
int prev_myosd_mouse = 0;
        
static pthread_t main_tid;

static int enable_menu_exit_option = 0;
static int actionPending=0;
static int wantExit = 0;
static int old_pref_num_buttons = 0;
static int old_filter_manufacturer = 0;
static int old_filter_gte_year = 0;
static int old_filter_lte_year = 0;
static int old_filter_driver_source = 0;
static int old_filter_category = 0;
static int old_myosd_num_buttons = 0;
static int button_auto = 0;
static int ways_auto = 0;
static int change_layout=0;

static int exit_status = 0;

static EmulatorController *sharedInstance = nil;

static NSUInteger buttonPressReleaseCycles = 2;

EmulatorController *GetSharedInstance()
{
    return sharedInstance;
}

void iphone_Reset_Views(void)
{
   if(sharedInstance==nil) return;
#ifndef JAILBREAK
   if(!myosd_inGame)
      [sharedInstance performSelectorOnMainThread:@selector(moveROMS) withObject:nil waitUntilDone:NO];
#endif
   [sharedInstance performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];  
}

void* app_Thread_Start(void* args)
{
    g_emulation_initiated = 1;
	
	iOS_main(0,NULL);

	return NULL;
}

@implementation UINavigationController(KeyboardDismiss)

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

@end

@interface EmulatorController() {
    CSToastStyle *toastStyle;
    CGPoint mouseTouchStartLocation;
    CGPoint mouseInitialLocation;
    CGPoint touchDirectionalMoveStartLocation;
    CGPoint touchDirectionalMoveInitialLocation;
}
@end

@implementation EmulatorController

@synthesize dpad_state;
@synthesize num_debug_rects;
@synthesize externalView;
@synthesize rExternalView;
@synthesize stick_radio;
@synthesize rStickWindow;
@synthesize rStickArea;
@synthesize rDPadImage;


- (int *)getBtnStates{
    return btnStates;
}

- (CGRect *)getInputRects{
    return rInput;
}

- (CGRect *)getButtonRects{
    return rButtonImages;
}

- (UIView **)getButtonViews{
    return buttonViews;
}
- (UIView *)getDPADView{
    return dpadView;
}
- (UIView *)getStickView{
    return analogStickView;
}

- (void)startEmulation{
    
    sharedInstance = self;
	     		    				
    pthread_create(&main_tid, NULL, app_Thread_Start, NULL);
		
	struct sched_param param;
 
    printf("main priority %d\n",main_thread_priority);
    param.sched_priority = main_thread_priority;
    int policy;
    if(main_thread_priority_type == 1)
      policy = SCHED_OTHER;
    else if(main_thread_priority_type == 2)
      policy = SCHED_RR;
    else
      policy = SCHED_FIFO;
           
    if(pthread_setschedparam(main_tid, policy, &param) != 0)    
             fprintf(stderr, "Error setting pthread priority\n");
    
    _impactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    _selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
    	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 999)
    {
        return;
    }
    
    int loadsave = myosd_inGame * 2;
  
    
    if(buttonIndex == 0 && enable_menu_exit_option)
    {
       g_menu_option = MENU_EXIT;
       myosd_exitGame = 0;
       wantExit = 1;	            
       UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                              message:@"are you sure you want to exit the game?"
                                                             delegate:self cancelButtonTitle:nil
                                                    otherButtonTitles:@"Yes",@"No",nil];                                                        
       [exitAlertView show];
       [exitAlertView release];           
       
    }   
    else if((buttonIndex == 0 && !enable_menu_exit_option && loadsave) || (buttonIndex == 1 && enable_menu_exit_option && loadsave))
    {
       myosd_loadstate = 1;
       [self endMenu];
    }
    else if((buttonIndex == 1 && !enable_menu_exit_option && loadsave) || (buttonIndex == 2 && enable_menu_exit_option && loadsave))
    {
       myosd_savestate = 1;
       [self endMenu];
    }     
    else if(buttonIndex == 0 + enable_menu_exit_option + loadsave)
    {
       g_menu_option = MENU_OPTIONS;
       
       OptionsController *addController =[[OptionsController alloc] init];
        
       addController.emuController = self;
                               
       UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:addController] autorelease];
        
       //[navController setModalPresentationStyle: /*UIModalPresentationFormSheet*/ UIModalPresentationPageSheet];

        [navController setModalPresentationStyle:UIModalPresentationPageSheet];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self presentViewController:navController animated:YES completion:nil];
        });

//        [self presentModalViewController:navController animated:YES];
        
       //[self presentModalViewController:addController animated:YES];

       [addController release];
    }
#ifdef BTJOY
    else if(buttonIndex == 1 + enable_menu_exit_option + loadsave)
    {
       g_menu_option = MENU_BTJOY;

       [BTJoyHelper startBTJoy:self];
    }
#endif    
    else   	    
    {
       [self endMenu];
    }
  	      
    [menu release];
    menu = nil;
                          
}

- (void)runMenu
{
    if(g_menu_option != MENU_NONE)
       return;

    if(menu!=nil)
    {
       [menu dismissWithClickedButtonIndex:999 animated:YES];
       [menu release];
       menu = nil;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    actionPending=1;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    g_emulation_paused = 1;
    change_pause(1);
  
    enable_menu_exit_option  = g_iCade_used && myosd_inGame && myosd_in_menu==0;
    
    menu = [[UIActionSheet alloc] initWithTitle:
            @"Choose an option from the menu. Press cancel to go back." delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
                              otherButtonTitles: nil];
    if(enable_menu_exit_option)
       [menu addButtonWithTitle:@"Exit Game"];
    if(myosd_inGame)
    {
       [menu addButtonWithTitle:@"Load State"];
       [menu addButtonWithTitle:@"Save State"];
    }
    [menu addButtonWithTitle:@"Settings"];
    if(g_btjoy_available)
       [menu addButtonWithTitle:@"WiiMote/Sixaxis"];
    [menu addButtonWithTitle:@"Cancel"];
    	   
    [menu showInView:self.view];
	   
    [pool release];   
}

- (void)endMenu{
	  	
	  int old = g_joy_used;
	  g_joy_used = myosd_num_of_joys!=0;
	    
	  if(((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land)) && g_joy_used && old!=g_joy_used)
	  {
	      [self changeUI]; 
	  }
	  if(((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land)) && !g_joy_used && old!=g_joy_used)
	  { 
	      [self changeUI];
	  }
	    
	  actionPending=0;
	  myosd_exitPause = 1;
      g_emulation_paused = 0;
      change_pause(0);
      g_menu_option = MENU_NONE;
    

      icadeView.active = FALSE;
      if(g_pref_ext_control_type != EXT_CONTROL_NONE)
      {
         icadeView.active = TRUE;//force renable
      }
      else if(g_iCade_used)//ensure is off
      {
          g_iCade_used = 0;
          g_joy_used = 0;
          myosd_num_of_joys = 0;
          [self changeUI];
      }
    
      [UIApplication sharedApplication].idleTimerDisabled = (myosd_inGame || g_joy_used) ? YES : NO;//so atract mode dont sleep
}

-(void)updateOptions{
    
    //printf("load options\n");
    
    Options *op = [[Options alloc] init];
    
    g_pref_keep_aspect_ratio_land = [op keepAspectRatioLand];
    g_pref_keep_aspect_ratio_port = [op keepAspectRatioPort];
    g_pref_smooth_land = [op smoothedLand];
    g_pref_smooth_port = [op smoothedPort];
    
    g_pref_tv_filter_land = [op tvFilterLand];
    g_pref_tv_filter_port = [op tvFilterPort];
    
    g_pref_scanline_filter_land = [op scanlineFilterLand];
    g_pref_scanline_filter_port = [op scanlineFilterPort];
    
    myosd_fps = [op showFPS];
    myosd_showinfo =  isGridlee ? 0 : [op showINFO];
    g_pref_animated_DPad  = [op animatedButtons];
    g_pref_full_screen_land  = isGridlee ? 0 : [op fullLand];
    g_pref_full_screen_port  = [op fullPort];
    
    myosd_pxasp1 = [op p1aspx];
    
    // always use skin 1
    g_pref_skin = 1;
    g_skin_data = g_pref_skin;
    if(g_pref_skin == 2 && g_isIpad)
        g_pref_skin = 3;
    
    g_pref_BT_DZ_value = [op btDeadZoneValue];
    g_pref_touch_DZ = [op touchDeadZone];
    
    g_pref_nativeTVOUT = [op tvoutNative];
    g_pref_overscanTVOUT = [op overscanValue];
    
    g_pref_input_touch_type = isGridlee ? 0 : [op touchtype];
    g_pref_analog_DZ_value = [op analogDeadZoneValue];
    g_pref_ext_control_type = [op controltype];
    
    switch  ([op soundValue]){
        case 0: myosd_sound_value=-1;break;
        case 1: myosd_sound_value=11025;break;
        case 2: myosd_sound_value=22050;break;
        case 3: myosd_sound_value=32000;break;
        case 4: myosd_sound_value=44100;break;
        case 5: myosd_sound_value=48000;break;
        default:myosd_sound_value=-1;}
    
    myosd_throttle = [op throttle];
    myosd_cheat = [op cheats];
    myosd_vsync = [op vsync] == 1 ? 6000 : -1;
   
    
    myosd_sleep = [op sleep];
    
    old_pref_num_buttons = [op numbuttons];
    g_pref_aplusb = [op aplusb];
    
    int nbuttons = [op numbuttons];
    
    if(nbuttons != 0)
    {
       nbuttons = nbuttons - 1;
       if(nbuttons>4)
       {
          g_pref_hide_LR=0;
          g_pref_full_num_buttons=4;
       }
       else
       {
          g_pref_hide_LR=1;
          g_pref_full_num_buttons=nbuttons;
       }
        button_auto = 0;
    }
    else
    {
       if(myosd_num_buttons==0)
          myosd_num_buttons = 2;
    
       if(myosd_num_buttons >4)
       {
          g_pref_hide_LR=0;
          g_pref_full_num_buttons=4;
       }
       else
       {
          g_pref_hide_LR=1;
          g_pref_full_num_buttons=myosd_num_buttons;
       }
        nbuttons = myosd_num_buttons;
        old_myosd_num_buttons = myosd_num_buttons;
        button_auto = 1;
    }
    
    if([op aplusb] == 1 && nbuttons==2)
    {
        g_pref_BplusX = 1;
        g_pref_full_num_buttons = 3;
        g_pref_hide_LR=1;
    }
    else
    {
        g_pref_BplusX = 0;
    }
        
    //////
    ways_auto = 0;
    if([op sticktype]==0)
    {
        ways_auto = 1;
        myosd_waysStick = myosd_num_ways;
    }
    else if([op sticktype]==1)
    {
        myosd_waysStick = 2;
    }
    else if([op sticktype]==2)
    {
        myosd_waysStick = 4;
    }
    else
    {
        myosd_waysStick = 8;
    }
    
    if([op fsvalue] == 0)
    {
        myosd_frameskip_value = -1;
    }
    else 
    {
        myosd_frameskip_value = [op fsvalue]-1;
    }
    
    myosd_force_pxaspect = [op forcepxa];
    
    myosd_res = [op emures]+1;
    
    myosd_filter_clones = op.filterClones;
    myosd_filter_favorites = op.filterFavorites;
    myosd_filter_not_working = op.filterNotWorking;
    
    old_filter_manufacturer =  op.manufacturerValue;
    old_filter_gte_year = op.yearGTEValue;
    old_filter_lte_year = op.yearLTEValue;
    old_filter_driver_source = op.driverSourceValue;
    old_filter_category = op.categoryValue;
    myosd_filter_manufacturer = op.manufacturerValue == 0 ? -1 : op.manufacturerValue -1;
    myosd_filter_gte_year = op.yearGTEValue == 0 ? -1 : op.yearGTEValue -1;
    myosd_filter_lte_year = op.yearLTEValue == 0 ? -1 : op.yearLTEValue -1;
    myosd_filter_driver_source = op.driverSourceValue == 0 ? -1 : op.driverSourceValue -1;
    myosd_filter_category = op.categoryValue == 0 ? -1 : op.categoryValue -1;
    
    if(op.filterKeyword == nil)
       myosd_filter_keyword[0] = '\0';
    else
       strcpy(myosd_filter_keyword, [op.filterKeyword UTF8String]);
    
    global_low_latency_sound = [op lowlsound];
    if(myosd_video_threaded==-1)
    {
          
        myosd_video_threaded = [op threaded];
        main_thread_priority =  MAX(1,[op mainPriority] * 10);
        video_thread_priority = MAX(1,[op videoPriority] * 10);
        myosd_dbl_buffer = [op dblbuff];
        main_thread_priority_type = [op mainThreadType]+1;
        main_thread_priority_type = [op videoThreadType]+1;
        printf("thread Type %d %d\n",main_thread_priority_type,main_thread_priority_type);
    }
    
    myosd_autofire = [op autofire];
    myosd_hiscore = [op hiscore];
    
    switch ([op buttonSize]) {
        case 0: g_buttons_size = 0.8; break;
        case 1: g_buttons_size = 0.9; break;
        case 2: g_buttons_size = 1.0; break;
        case 3: g_buttons_size = 1.1; break;
        case 4: g_buttons_size = 1.2; break;
    }
    
    switch ([op stickSize]) {
        case 0: g_stick_size = 0.8; break;
        case 1: g_stick_size = 0.9; break;
        case 2: g_stick_size = 1.0; break;
        case 3: g_stick_size = 1.1; break;
        case 4: g_stick_size = 1.2; break;
    }
    
    myosd_vector_bean2x = [op vbean2x];
    myosd_vector_antialias = [op vantialias];
    myosd_vector_flicker = [op vflicker];

    switch ([op emuspeed]) {
        case 0: myosd_speed = -1; break;
        case 1: myosd_speed = 50; break;
        case 2: myosd_speed = 60; break;
        case 3: myosd_speed = 70; break;
        case 4: myosd_speed = 80; break;
        case 5: myosd_speed = 85; break;
        case 6: myosd_speed = 90; break;
        case 7: myosd_speed = 95; break;
        case 8: myosd_speed = 100; break;
        case 9: myosd_speed = 105; break;
        case 10: myosd_speed = 110; break;
        case 11: myosd_speed = 115; break;
        case 12: myosd_speed = 120; break;
        case 13: myosd_speed = 130; break;
        case 14: myosd_speed = 140; break;
        case 15: myosd_speed = 150; break;
    }
    
    g_pref_lightgun_enabled = [op lightgunEnabled];
    g_pref_lightgun_bottom_reload = [op lightgunBottomScreenReload];
    
    turboBtnEnabled[BTN_X] = [op turboXEnabled];
    turboBtnEnabled[BTN_Y] = [op turboYEnabled];
    turboBtnEnabled[BTN_A] = [op turboAEnabled];
    turboBtnEnabled[BTN_B] = [op turboBEnabled];
    turboBtnEnabled[BTN_L1] = [op turboLEnabled];
    turboBtnEnabled[BTN_R1] = [op turboREnabled];
    
    g_pref_touch_analog_enabled = [op touchAnalogEnabled];
    g_pref_touch_analog_hide_dpad = [op touchAnalogHideTouchDirectionalPad];
    g_pref_touch_analog_hide_buttons = [op touchAnalogHideTouchButtons];
    g_pref_touch_analog_sensitivity = [op touchAnalogSensitivity];
    g_controller_opacity = [op touchControlsOpacity];
    
    g_pref_touch_directional_enabled = [op touchDirectionalEnabled];
    
    [op release];
}

-(void)done:(id)sender {
    
    
    if(!change_layout)
      [self dismissModalViewControllerAnimated:YES];

	Options *op = [[Options alloc] init];
           
        
       if(g_pref_overscanTVOUT != [op overscanValue])
       {

           UIAlertView *warnAlert = [[UIAlertView alloc] initWithTitle:@"Pending unplug/plug TVOUT!" 
															  
 
           message:[NSString stringWithFormat: @"You need to unplug/plug TVOUT for the changes to take effect"]
														 
															 delegate:self 
													cancelButtonTitle:@"Dismiss" 
													otherButtonTitles: nil];
	
	       [warnAlert show];
	       [warnAlert release];
       }

    
    int keyword_changed = 0;    
    if(myosd_filter_keyword[0]!='\0' && [op.filterKeyword UTF8String] != nil)
        keyword_changed = strcmp(myosd_filter_keyword,[op.filterKeyword UTF8String])!=0;
    else if(myosd_filter_keyword[0]=='\0' && [op.filterKeyword UTF8String] == nil)
        keyword_changed = 0;
    else
        keyword_changed = 1;
    
    //printf("%d %s %s\n",keyword_changed,myosd_filter_keyword,[op.filterKeyword UTF8String]);
    
    if (myosd_filter_clones != op.filterClones ||
        myosd_filter_favorites!= op.filterFavorites ||
        myosd_filter_not_working != op.filterNotWorking ||
        old_filter_manufacturer != op.manufacturerValue ||
        old_filter_gte_year != op.yearGTEValue ||
        old_filter_lte_year != op.yearLTEValue ||
        old_filter_driver_source != op.driverSourceValue ||
        old_filter_category != op.categoryValue ||
        keyword_changed
        
        )
    {
        if(!(myosd_in_menu==0 && myosd_inGame)){
            myosd_reset_filter = 1;
        }
        myosd_last_game_selected = 0;
    }
    
    if(global_low_latency_sound != [op lowlsound])
    {
        if(myosd_sound_value!=-1)
        {
           myosd_closeSound();
           global_low_latency_sound = [op lowlsound];
           myosd_openSound(myosd_sound_value, 1);
        }
    }
    
    [op release];
    
    [self updateOptions];
    
    [self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
    
    [self endMenu];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(change_layout)
    {
        if(buttonIndex == 0)
           [LayoutData removeLayoutData];
        
        change_layout = 0;
        
        [self done:self];
        
    }
    else
    {
        
        myosd_exitPause = 1;
        g_emulation_paused = 0;
        change_pause(0);
        if(g_menu_option == MENU_EXIT)
        {
            [self endMenu];
        }
        
        if(buttonIndex == 0 && wantExit )
        {
            myosd_exitGame = 1;
        }
        actionPending=0;
        wantExit = 0;
    }
}

- (void)handle_MENU
{
    if(/*btnStates[BTN_L2] == BUTTON_PRESS*/exit_status==2 && !actionPending)
    {				  				

        exit_status = 0;
        
        if(myosd_in_menu==0 && myosd_inGame)
        {
            actionPending=1;
            myosd_exitGame = 0;
            wantExit = 1;	
            usleep(100000);	            
            g_emulation_paused = 1;
            change_pause(1);
            
            UIAlertView* exitAlertView = nil;
            
            if(myosd_inGame)
	              exitAlertView=[[UIAlertView alloc] initWithTitle:nil
	                                                                  message:@"are you sure you want to exit the game?"
	                                                                 delegate:self cancelButtonTitle:nil
	                                                        otherButtonTitles:@"Yes",@"No",nil];
	                                                        	                                                        
	        [exitAlertView show];
	        [exitAlertView release];
        }
        else
        { 
            myosd_exitGame = 1;  
        }
    } 
    
    if(btnStates[BTN_R2] == BUTTON_PRESS && !actionPending)
    {
         [self runMenu];
    }					
}	

- (void)loadView {

	struct CGRect rect = [[UIScreen mainScreen] bounds];
	rect.origin.x = rect.origin.y = 0.0f;
	UIView *view= [[UIView alloc] initWithFrame:rect];
	self.view = view;
	[view release];
     self.view.backgroundColor = [UIColor blackColor];	
    externalView = nil;
    printf("loadView\n");
}

-(void)viewDidLoad{	
    printf("viewDidLoad\n");
    
    controllers = [[NSMutableArray alloc] initWithCapacity:4];
    
   nameImgButton_NotPress[BTN_B] = @"button_NotPress_B.png";
   nameImgButton_NotPress[BTN_X] = @"button_NotPress_X.png";
   nameImgButton_NotPress[BTN_A] = @"button_NotPress_A.png";
   nameImgButton_NotPress[BTN_Y] = @"button_NotPress_Y.png";
   nameImgButton_NotPress[BTN_START] = @"button_NotPress_start.png";
   nameImgButton_NotPress[BTN_SELECT] = @"button_NotPress_select.png";
   nameImgButton_NotPress[BTN_L1] = @"button_NotPress_R_L1.png";
   nameImgButton_NotPress[BTN_R1] = @"button_NotPress_R_R1.png";
   nameImgButton_NotPress[BTN_L2] = @"button_NotPress_R_L2.png";
   nameImgButton_NotPress[BTN_R2] = @"button_NotPress_R_R2.png";
   
   nameImgButton_Press[BTN_B] = @"button_Press_B.png";
   nameImgButton_Press[BTN_X] = @"button_Press_X.png";
   nameImgButton_Press[BTN_A] = @"button_Press_A.png";
   nameImgButton_Press[BTN_Y] = @"button_Press_Y.png";
   nameImgButton_Press[BTN_START] = @"button_Press_start.png";
   nameImgButton_Press[BTN_SELECT] = @"button_Press_select.png";
   nameImgButton_Press[BTN_L1] = @"button_Press_R_L1.png";
   nameImgButton_Press[BTN_R1] = @"button_Press_R_R1.png";
   nameImgButton_Press[BTN_L2] = @"button_Press_R_L2.png";
   nameImgButton_Press[BTN_R2] = @"button_Press_R_R2.png";
         
   nameImgDPad[DPAD_NONE]=@"DPad_NotPressed.png";
   nameImgDPad[DPAD_UP]= @"DPad_U.png";
   nameImgDPad[DPAD_DOWN]= @"DPad_D.png";
   nameImgDPad[DPAD_LEFT]= @"DPad_L.png";
   nameImgDPad[DPAD_RIGHT]= @"DPad_R.png";
   nameImgDPad[DPAD_UP_LEFT]= @"DPad_UL.png";
   nameImgDPad[DPAD_UP_RIGHT]= @"DPad_UR.png";
   nameImgDPad[DPAD_DOWN_LEFT]= @"DPad_DL.png";
   nameImgDPad[DPAD_DOWN_RIGHT]= @"DPad_DR.png";
      
   dpadView=nil;
   analogStickView = nil;
      
   int i;
   for(i=0; i<NUM_BUTTONS;i++)
      buttonViews[i]=nil;
      
   screenView=nil;
   imageBack=nil;   			
   dview = nil;
   
   menu = nil;

   
   [ self getConf];

	//[self.view addSubview:self.imageBack];
 	
	//[ self getControllerCoords:0 ];
	
	//self.navigationItem.hidesBackButton = YES;
	
	
    self.view.opaque = YES;
	self.view.clearsContextBeforeDrawing = NO; //Performance?
	
	self.view.userInteractionEnabled = YES;
	
	self.view.multipleTouchEnabled = YES;
	self.view.exclusiveTouch = NO;
	
    //self.view.multipleTouchEnabled = NO; investigar porque se queda
	//self.view.contentMode = UIViewContentModeTopLeft;
	
	//[[self.view layer] setMagnificationFilter:kCAFilterNearest];
	//[[self.view layer] setMinificationFilter:kCAFilterNearest];

	//kito
	[NSThread setThreadPriority:1.0];
	
	g_menu_option = MENU_NONE;
		
	//self.view.frame = [[UIScreen mainScreen] bounds];//rMainViewFrame;
		
    [self updateOptions];

    // Button to hide/show onscreen controls for lightgun games
    // Also functions as a show menu button when a game controller is used
    hideShowControlsForLightgun = [[UIButton alloc] initWithFrame:CGRectZero];
    hideShowControlsForLightgun.hidden = YES;
    [hideShowControlsForLightgun.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"dpad"] forState:UIControlStateNormal];
    [hideShowControlsForLightgun addTarget:self action:@selector(toggleControlsForLightgunButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    hideShowControlsForLightgun.alpha = 0.2f;
    hideShowControlsForLightgun.translatesAutoresizingMaskIntoConstraints = NO;
    [hideShowControlsForLightgun addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant: UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 30.0f : 20.0f]];
    [hideShowControlsForLightgun addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 30.0f :20.0f]];
    [self.view addSubview:hideShowControlsForLightgun];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:8.0f]];
    areControlsHidden = NO;

    
    [self changeUI];
    
    icadeView = [[iCadeView alloc] initWithFrame:CGRectZero withEmuController:self];
    [self.view addSubview:icadeView];
    
    if(g_pref_ext_control_type!=EXT_CONTROL_NONE)
       icadeView.active = YES;
    
    if(0)
    {
		   UIAlertView *loadAlert = [[UIAlertView alloc] initWithTitle:nil 
	   																										
		           message:[NSString stringWithFormat: @"\n\n\nLoading.\nPlease Wait..."]
															 
																 delegate: nil 
														cancelButtonTitle: nil 
														otherButtonTitles: nil];
			   			      
		   [loadAlert show];
	       [loadAlert release];
	 }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(MFIControllerConnected:)
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(MFIControllerDisconnected:)
                                                 name:GCControllerDidDisconnectNotification
                                               object:nil];
    
    if ([[GCController controllers] count] != 0) {
        [self setupMFIControllers];
    }
    else {
        [self scanForDevices];
    }
    toastStyle = [[CSToastStyle alloc] initWithDefaultStyle];
    toastStyle.backgroundColor = [UIColor darkGrayColor];
    toastStyle.messageColor = [UIColor whiteColor];
    
    mouseInitialLocation = CGPointMake(9111, 9111);
    mouseTouchStartLocation = mouseInitialLocation;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeBottom;
}

-(BOOL)prefersHomeIndicatorAutoHidden
{
    return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCControllerDidConnectNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCControllerDidDisconnectNotification
                                                  object:nil];
    
    [self removeTouchControllerViews];
    
    [screenView release];
    screenView = nil;
    
    [imageBack release];
    imageBack = nil;
    
    [imageOverlay release];
    imageOverlay = nil;
    
    [dview release];
    dview= nil;
    
    [icadeView release];
    icadeView = nil;
}

- (void)drawRect:(CGRect)rect
{
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return change_layout ? NO : YES;
}

- (BOOL)shouldAutorotate {
    return change_layout ? NO : YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if(isGridlee)
      return UIInterfaceOrientationMaskLandscape;
    else
      return UIInterfaceOrientationMaskAll;
}

/*
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //printf("llaman al preferredInterfaceOrientationForPresentation\n");
    return UIInterfaceOrientationPortrait;
}
*/

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
   
    [self changeUI];
    if(menu!=nil)
    {         
         [self runMenu];
    }        
}

-(void) toggleControlsForLightgunButtonPressed:(id)sender {
    // hack for when using a game controller - it will display the menu
    if ( g_joy_used ) {
        [self runMenu];
        return;
    }
    areControlsHidden = !areControlsHidden;
    if(dpadView!=nil)
    {
        dpadView.hidden = areControlsHidden;
    }
    
    if(analogStickView!=nil)
    {
        analogStickView.hidden = areControlsHidden;
    }
    
    for(int i=0; i<NUM_BUTTONS;i++)
    {
        if(buttonViews[i]!=nil)
        {
            buttonViews[i].hidden = areControlsHidden;
        }
    }
}

- (void)changeUI{
   NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
  int prev_emulation_paused = g_emulation_paused;
   
  g_emulation_paused = 1;
  change_pause(1);
  
  [self getConf];
    
  //printf("%d %d %d\n",ways_auto,myosd_num_ways,myosd_waysStick);
    
  if((ways_auto && myosd_num_ways!=myosd_waysStick) || (button_auto && old_myosd_num_buttons != myosd_num_buttons))
  {
     [self updateOptions];
  }
    
  usleep(150000);//ensure some frames displayed

  if(screenView != nil)
  {
     [screenView removeFromSuperview];
     [screenView release];
  }

  if(imageBack!=nil)
  {
     [imageBack removeFromSuperview];
     [imageBack release];
     imageBack = nil;
  }
   
  //si tiene overlay
   if(imageOverlay!=nil)
   {
     [imageOverlay removeFromSuperview];
     [imageOverlay release];
     imageOverlay = nil;
   }
    
    // Support iCade in external screens
    if ( externalView != nil && icadeView != nil && ![externalView.subviews containsObject:icadeView] ) {
        [externalView addSubview:icadeView];
    }
    
   [[UIApplication sharedApplication]   setStatusBarOrientation:self.interfaceOrientation];
   
   if((self.interfaceOrientation ==  UIDeviceOrientationLandscapeLeft) || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)){
	          
       [self buildLandscape];
   } else	if((self.interfaceOrientation == UIDeviceOrientationPortrait) || (self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)){
              
       [self buildPortrait];
   }

    if ( g_joy_used ) {
        [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
    } else {
        [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"dpad"] forState:UIControlStateNormal];
    }
    
   //self.view.backgroundColor = [UIColor blackColor];
   [self.view setNeedsDisplay];
   	
   myosd_exitPause = 1;
	
   if(prev_emulation_paused!=1)
   {
	   g_emulation_paused = 0;
	   change_pause(0);
   }
    
   [UIApplication sharedApplication].idleTimerDisabled = (myosd_inGame || g_joy_used) ? YES : NO;//so atract mode dont sleep

    if ( prev_myosd_light_gun == 0 && myosd_light_gun == 1 && g_pref_lightgun_enabled ) {
        [self.view makeToast:@"Touch Lightgun Mode Enabled!" duration:2.0 position:CSToastPositionCenter style:toastStyle];
    }
    prev_myosd_light_gun = myosd_light_gun;
    
    if ( prev_myosd_mouse == 0 && myosd_mouse == 1 && g_pref_touch_analog_enabled ) {
        [self.view makeToast:@"Touch Mouse Mode Enabled!" duration:2.0 position:CSToastPositionCenter style:toastStyle];
        [self buildTouchControllerViews];
    }
    
    areControlsHidden = NO;
    
    for (int i = 0; i < NUM_BUTTONS; i++) {
        cyclesAfterButtonPressed[i] = 0;
    }
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < NUM_BUTTONS; j++) {
            mfiCyclesAfterButtonPressed[i][j] = 0;
            mfiBtnStates[i][j] = 0;
        }
    }

   [pool release];
}

void myosd_handle_turbo() {
    if ( !myosd_inGame ) {
        return;
    }
    NSArray *supportedTurboButtons = @[ @[ [NSNumber numberWithInt:BTN_X], [NSNumber numberWithInt:MYOSD_A] ],
                                           @[ [NSNumber numberWithInt:BTN_Y], [NSNumber numberWithInt:MYOSD_Y] ],
                                           @[ [NSNumber numberWithInt:BTN_A], [NSNumber numberWithInt:MYOSD_B] ],
                                           @[ [NSNumber numberWithInt:BTN_B], [NSNumber numberWithInt:MYOSD_X] ],
                                           @[ [NSNumber numberWithInt:BTN_L1], [NSNumber numberWithInt:MYOSD_L1] ],
                                           @[ [NSNumber numberWithInt:BTN_R1], [NSNumber numberWithInt:MYOSD_R1] ]
                                           ];

    // poll mfi controllers and read state of button presses
    for (int index = 0; index < controllers.count; index++) {
        GCController *mfiController = [controllers objectAtIndex:index];
        GCExtendedGamepad *extendedGamepad = mfiController.extendedGamepad;
        GCGamepad *gamepad = mfiController.gamepad;
        if ( extendedGamepad.buttonX.isPressed || gamepad.buttonX.isPressed ) {
            mfiBtnStates[index][BTN_X] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_X] = BUTTON_NO_PRESS;
        }
        if ( extendedGamepad.buttonY.isPressed || gamepad.buttonY.isPressed ) {
            mfiBtnStates[index][BTN_Y] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_Y] = BUTTON_NO_PRESS;
        }
        if ( extendedGamepad.buttonA.isPressed || gamepad.buttonA.isPressed ) {
            mfiBtnStates[index][BTN_A] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_A] = BUTTON_NO_PRESS;
        }
        if ( extendedGamepad.buttonB.isPressed || gamepad.buttonB.isPressed ) {
            mfiBtnStates[index][BTN_B] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_B] = BUTTON_NO_PRESS;
        }
        if ( extendedGamepad.leftShoulder.isPressed || gamepad.leftShoulder.isPressed ) {
            mfiBtnStates[index][BTN_L1] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_L1] = BUTTON_NO_PRESS;
        }
        if ( extendedGamepad.rightShoulder.isPressed || gamepad.rightShoulder.isPressed ) {
            mfiBtnStates[index][BTN_R1] = BUTTON_PRESS;
        } else {
            mfiBtnStates[index][BTN_R1] = BUTTON_NO_PRESS;
        }
    }
    
    
    for (NSArray *buttonData in supportedTurboButtons) {
        int button = [(NSNumber*)[buttonData objectAtIndex:0] intValue];
        int myosdButton = [(NSNumber*)[buttonData objectAtIndex:1] intValue];
        
        if ( controllers.count > 0 ) {
            // For mFi Controllers
            for (int i = 0; i < controllers.count; i++) {
                if ( turboBtnEnabled[button] && mfiBtnStates[i][button] == BUTTON_PRESS ) {
                    if ( mfiCyclesAfterButtonPressed[i][button] > buttonPressReleaseCycles ) {
                        NSLog(@"Turbo enabled! (mfi)");
                        if ( myosd_joy_status[i] & myosdButton ) {
                            myosd_joy_status[i] &= ~myosdButton;
                        } else {
                            myosd_joy_status[i] |= myosdButton;
                        }
                        mfiCyclesAfterButtonPressed[i][button] = 0;
                    }
                    mfiCyclesAfterButtonPressed[i][button]++;
                }
            }
            
        } else {
            // For the on-screen touch gamepad
            if ( turboBtnEnabled[button] && btnStates[button] == BUTTON_PRESS ) {
                if ( cyclesAfterButtonPressed[button] > buttonPressReleaseCycles ) {
                    NSLog(@"Turbo enabled!");
                    if ( myosd_pad_status & myosdButton ) {
                        myosd_pad_status &= ~myosdButton;
                    } else {
                        myosd_pad_status |= myosdButton;
                    }
                    cyclesAfterButtonPressed[button] = 0;
                }
                cyclesAfterButtonPressed[button]++;
            }
            
        }
    }
}

- (void)removeTouchControllerViews{
   
   int i;
   
   if(dpadView!=nil)
   {
      [dpadView removeFromSuperview];
      [dpadView release];
      dpadView=nil;
   }
   
   if(analogStickView!=nil)
   {
      [analogStickView removeFromSuperview];
      [analogStickView release];
      analogStickView=nil;   
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {
      if(buttonViews[i]!=nil)
      {
         [buttonViews[i] removeFromSuperview];
         [buttonViews[i] release];     
         buttonViews[i] = nil; 
      }
   }
      
}

- (void)buildTouchControllerViews {

   int i;
   
   
   [self removeTouchControllerViews];
    
   g_joy_used = myosd_num_of_joys!=0; 
   
   if(g_joy_used && ((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land)))
     return;
   
   NSString *name;
    
    BOOL touch_dpad_disabled = (myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_dpad) ||
                               (g_pref_touch_directional_enabled && g_pref_touch_analog_hide_dpad);
    if ( !touch_dpad_disabled || !myosd_inGame ) {
        if(g_pref_input_touch_type == TOUCH_INPUT_DPAD)
        {
            name = [NSString stringWithFormat:@"./SKIN_%d/%@",g_pref_skin,nameImgDPad[DPAD_NONE]];
            dpadView = [ [ UIImageView alloc ] initWithImage:[self loadImage:name]];
            dpadView.frame = rDPadImage;
            if( (!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land))
                [dpadView setAlpha:((float)g_controller_opacity / 100.0f)];
            [self.view addSubview: dpadView];
            dpad_state = old_dpad_state = DPAD_NONE;
        }
        else
        {
            //analogStickView
            analogStickView = [[AnalogStickView alloc] initWithFrame:rStickWindow withEmuController:self];
            [self.view addSubview:analogStickView];
            [analogStickView setNeedsDisplay];
        }
    }
   
    BOOL touch_buttons_disabled = myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_buttons;
    for(i=0; i<NUM_BUTTONS;i++)
    {
        if(!change_layout &&  (g_device_is_landscape || (!g_device_is_landscape && g_pref_full_screen_port)))
        {
            if(i==BTN_Y && (g_pref_full_num_buttons < 4 || !myosd_inGame))continue;
            if(i==BTN_A && (g_pref_full_num_buttons < 3 || !myosd_inGame))continue;
            if(i==BTN_X && (g_pref_full_num_buttons < 2 && myosd_inGame))continue;
            if(i==BTN_B && (g_pref_full_num_buttons < 1 && myosd_inGame))continue;
            
            if(i==BTN_L1 && (g_pref_hide_LR || !myosd_inGame))continue;
            if(i==BTN_R1 && (g_pref_hide_LR || !myosd_inGame))continue;
            
            if (touch_buttons_disabled && (i != BTN_SELECT && i != BTN_START && i != BTN_L2 && i != BTN_R2 )) continue;
        }
        
        if(isGridlee && (i==BTN_L2 || i==BTN_R2))
            continue;
        
        
        name = [NSString stringWithFormat:@"./SKIN_%d/%@",g_pref_skin,nameImgButton_NotPress[i]];
        buttonViews[i] = [ [ UIImageView alloc ] initWithImage:[self loadImage:name]];
        buttonViews[i].frame = rButtonImages[i];
        
        if((g_device_is_landscape && (g_pref_full_screen_land /*|| i==BTN_Y || i==BTN_A*/)) || (!g_device_is_landscape && g_pref_full_screen_port))
            [buttonViews[i] setAlpha:((float)g_controller_opacity / 100.0f)];
        
        if(g_device_is_landscape && !g_pref_full_screen_land && g_isIphone5 /*&& skin_data==1*/ && (i==BTN_Y || i==BTN_A || i==BTN_L1 || i==BTN_R1))
            [buttonViews[i] setAlpha:((float)g_controller_opacity / 100.0f)];
        
        [self.view addSubview: buttonViews[i]];
        btnStates[i] = old_btnStates[i] = BUTTON_NO_PRESS;
    }
    
}

- (void)buildPortraitImageBack {

   if(!g_pref_full_screen_port)
   {
	   if(g_isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPad.png",g_pref_skin]]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPhone.png",g_pref_skin]]];
	   
	   imageBack.frame = rFrames[PORTRAIT_IMAGE_BACK]; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   
}


- (void)buildPortraitImageOverlay {
   
   if((g_pref_scanline_filter_port || g_pref_tv_filter_port) && externalView==nil)
   {
                                                                                                                                                       
       CGRect r = g_pref_full_screen_port ? rScreenView : rFrames[PORTRAIT_IMAGE_OVERLAY];
       
       UIGraphicsBeginImageContext(r.size);  
       
       //[image1 drawInRect: rPortraitImageOverlayFrame];
       
       CGContextRef uiContext = UIGraphicsGetCurrentContext();
             
       CGContextTranslateCTM(uiContext, 0, r.size.height);
	
       CGContextScaleCTM(uiContext, 1.0, -1.0);

       if(g_pref_scanline_filter_port)
       {
          UIImage *image2 = [self loadImage:[NSString stringWithFormat: @"scanline-1.png"]];
                        
          CGImageRef tile = CGImageRetain(image2.CGImage);
                   
          CGContextSetAlpha(uiContext,((float)22 / 100.0f));   
              
          CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image2.size.width, image2.size.height), tile);
       
          CGImageRelease(tile);       
       }

       if(g_pref_tv_filter_port)
       {                        
          UIImage *image3 = [self loadImage:[NSString stringWithFormat: @"crt-1.png"]];
          
          CGImageRef tile = CGImageRetain(image3.CGImage);
              
          CGContextSetAlpha(uiContext,((float)19 / 100.0f));     
          
          CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image3.size.width, image3.size.height), tile);
       
          CGImageRelease(tile);       
       }
     
       if(g_isIpad /*&& externalView==nil*/ && (!g_pref_full_screen_port /*|| 1*/))
       {
          UIImage *image1;
          if(g_isIpad)          
            image1 = [self loadImage:[NSString stringWithFormat:@"border-iPad.png"]];
          else
            image1 = [self loadImage:[NSString stringWithFormat:@"border-iPhone.png"]];
         
          CGImageRef img = CGImageRetain(image1.CGImage);
       
          CGContextSetAlpha(uiContext,((float)100 / 100.0f));  
   
          CGContextDrawImage(uiContext,rFrames[PORTRAIT_IMAGE_OVERLAY], img);
   
          CGImageRelease(img);  
       }
             
       UIImage *finishedImage = UIGraphicsGetImageFromCurrentImageContext();
                                                            
       UIGraphicsEndImageContext();
       
       imageOverlay = [ [ UIImageView alloc ] initWithImage: finishedImage];
         
       imageOverlay.frame = r;
            		    			
       [self.view addSubview: imageOverlay];
                                    
   }  

  //DPAD---   
  [self buildTouchControllerViews];   
  /////
   
  /////////////////
  if(g_enable_debug_view)
  {
	  if(dview!=nil)
	  {
	    [dview removeFromSuperview];
	    [dview release];
	  }  	 
	
	  dview = [[DebugView alloc] initWithFrame:self.view.bounds withEmuController:self];
	  
	  [self.view addSubview:dview];   
	
	  [self filldebugRects];
	  
	  [dview setNeedsDisplay];
  }
  ////////////////
}

- (void)buildPortrait {

   g_device_is_landscape = 0;
   [ self getControllerCoords:0 ];
    
   [ self adjustSizes];
    
   [LayoutData loadLayoutData:self];
   
   [self buildPortraitImageBack];
   
   CGRect r;
   
   if(externalView!=nil)   
   {
        r = rExternalView;
   }
   else if(!g_pref_full_screen_port)
   {
	    r = rFrames[PORTRAIT_VIEW_NOT_FULL];
   }		  
   else
   {
        r = rFrames[PORTRAIT_VIEW_FULL];
   }
   
    if(g_pref_keep_aspect_ratio_port)
    {

       int tmp_height = r.size.height;// > emulated_width ?
       int tmp_width = ((((tmp_height * myosd_vis_video_width) / myosd_vis_video_height)+7)&~7);
       		       
       if(tmp_width > r.size.width) //y no crop
       {
          tmp_width = r.size.width;
          tmp_height = ((((tmp_width * myosd_vis_video_height) / myosd_vis_video_width)+7)&~7);
       }   
       
       r.origin.x = r.origin.x + ((r.size.width - tmp_width) / 2);      
       
       if(!g_pref_full_screen_port || g_joy_used)
       {
          r.origin.y = r.origin.y + ((r.size.height - tmp_height) / 2);
       }
       else
       {
          int tmp = r.size.height - (r.size.height/5);
          if(tmp_height < tmp)                                
             r.origin.y = r.origin.y + ((tmp - tmp_height) / 2);
       }
              
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   
   }
    
    // Handle Safe Area (iPhone X)
    if ( @available(iOS 11, *) ) {
        if ( externalView == nil ) {
            UIEdgeInsets inset = [[UIApplication sharedApplication] keyWindow].safeAreaInsets;
            NSLog(@"safe area insets: top %f, bottom %f, left %f, right %f", inset.top, inset.bottom, inset.left, inset.right);
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            CGRect newFrame = r;
            if ( orientation == UIInterfaceOrientationPortrait ) {
                newFrame = CGRectMake(r.origin.x, r.origin.y + inset.top, r.size.width, r.size.height - inset.top);
            }
            r = newFrame;
        }
    }

   rScreenView = r;
       
   screenView = [ [ScreenView alloc] initWithFrame: rScreenView];
                  
   if(externalView==nil)
   {             		    			
      [self.view addSubview: screenView];
   }  
   else
   {   
      [externalView addSubview: screenView];
   }  
      
   [self buildPortraitImageOverlay];

    hideShowControlsForLightgun.hidden = YES;
}

- (void)buildLandscapeImageBack {

   if(!g_pref_full_screen_land)
   {
	   if(g_isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPad.png",g_pref_skin]]];
       else if(g_isIphone5)
         imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone_5.png",g_pref_skin]]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone.png",g_pref_skin]]];
	   
	   imageBack.frame = rFrames[LANDSCAPE_IMAGE_BACK]; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   
}

- (void)buildLandscapeImageOverlay{
 
   if((g_pref_scanline_filter_land || g_pref_tv_filter_land) &&  externalView==nil)
   {                                                                                                                                              
	   CGRect r;

       if(g_pref_full_screen_land)
          r = rScreenView;
       else
          r = rFrames[LANDSCAPE_IMAGE_OVERLAY];
	
	   UIGraphicsBeginImageContext(r.size);
	
	   CGContextRef uiContext = UIGraphicsGetCurrentContext();  
	   
	   CGContextTranslateCTM(uiContext, 0, r.size.height);
		
	   CGContextScaleCTM(uiContext, 1.0, -1.0);
	   
	   if(g_pref_scanline_filter_land)
	   {       	       
	      UIImage *image2;
	      
	      if(g_isIpad)
	        image2 =  [self loadImage:[NSString stringWithFormat: @"scanline-2.png"]];
	      else
	        image2 =  [self loadImage:[NSString stringWithFormat: @"scanline-1.png"]];
	                        
	      CGImageRef tile = CGImageRetain(image2.CGImage);
	      
	      if(g_isIpad)             
	         CGContextSetAlpha(uiContext,((float)10 / 100.0f));
	      else
	         CGContextSetAlpha(uiContext,((float)22 / 100.0f));
	              
	      CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image2.size.width, image2.size.height), tile);
	       
	      CGImageRelease(tile);       
	    }
	
	    if(g_pref_tv_filter_land)
	    {              
	       UIImage *image3 = [self loadImage:[NSString stringWithFormat: @"crt-1.png"]];
	          
	       CGImageRef tile = CGImageRetain(image3.CGImage);
	              
	       CGContextSetAlpha(uiContext,((float)20 / 100.0f));     
	          
	       CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image3.size.width, image3.size.height), tile);
	       
	       CGImageRelease(tile);       
	    }

	       
	    UIImage *finishedImage = UIGraphicsGetImageFromCurrentImageContext();
	                  
	    UIGraphicsEndImageContext();
	    
	    imageOverlay = [ [ UIImageView alloc ] initWithImage: finishedImage];
	    
	    imageOverlay.frame = r; // Set the frame in which the UIImage should be drawn in.
      
        imageOverlay.userInteractionEnabled = NO;
        imageOverlay.multipleTouchEnabled = NO;
        imageOverlay.clearsContextBeforeDrawing = NO;
   
        //[imageBack setOpaque:YES];
                                         
        [self.view addSubview: imageOverlay];
	  	   
    }
   
    //DPAD---   
    [self buildTouchControllerViews];   
    /////
  
   //////////////////
   if(g_enable_debug_view)
   {
	  if(dview!=nil)
	  {
        [dview removeFromSuperview];
        [dview release];
      }	 	  
	  
	  dview = [[DebugView alloc] initWithFrame:self.view.bounds withEmuController:self];
		 	  
	  [self filldebugRects];
	  
	  [self.view addSubview:dview];   
	  [dview setNeedsDisplay];
	  
	 
  }
  /////////////////	
}

- (void)buildLandscape{
	
   g_device_is_landscape = 1;
      
   [self getControllerCoords:1 ];
    
   [self adjustSizes];
    
   [LayoutData loadLayoutData:self];
   
   [self buildLandscapeImageBack];
        
   CGRect r;
   
   if(externalView!=nil)
   {
        r = rExternalView;
   }
   else if(!g_pref_full_screen_land)
   {
        r = rFrames[LANDSCAPE_VIEW_NOT_FULL];
   }     
   else
   {
        r = rFrames[LANDSCAPE_VIEW_FULL];
   }     
   
   if(g_pref_keep_aspect_ratio_land)
   {
       //printf("%d %d\n",myosd_video_width,myosd_video_height);

       int tmp_width = r.size.width;// > emulated_width ?
       int tmp_height = ((((tmp_width * myosd_vis_video_height) / myosd_vis_video_width)+7)&~7);
       
       //printf("%d %d\n",tmp_width,tmp_height);
       
       if(tmp_height > r.size.height) //y no crop
       {
          tmp_height = r.size.height;
          tmp_width = ((((tmp_height * myosd_vis_video_width) / myosd_vis_video_height)+7)&~7);
       }   
       
       //printf("%d %d\n",tmp_width,tmp_height);
                
       r.origin.x = r.origin.x +(((int)r.size.width - tmp_width) / 2);             
       r.origin.y = r.origin.y +(((int)r.size.height - tmp_height) / 2);
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   }
   
   rScreenView = r;
   
   screenView = [ [ScreenView alloc] initWithFrame: rScreenView];
          
   if(externalView==nil)
   {             		    			      
      [self.view addSubview: screenView];
   }  
   else
   {               
      [externalView addSubview: screenView];
   }   
           
   [self buildLandscapeImageOverlay];
    
    if ( g_pref_full_screen_land &&
        (
         (myosd_light_gun && g_pref_lightgun_enabled) ||
         (myosd_mouse && g_pref_touch_analog_enabled)
        )) {
        // make a button to hide/display the controls
        hideShowControlsForLightgun.hidden = NO;
        [self.view bringSubviewToFront:hideShowControlsForLightgun];
    }
	
}

////////////////


- (void)handle_DPAD{

    if(!g_pref_animated_DPad /*|| !show_controls*/)return;

    if(dpad_state!=old_dpad_state)
    {
       //printf("cambia depad %d %d\n",old_dpad_state,dpad_state);
       NSString *imgName; 
       imgName = nameImgDPad[dpad_state];
       if(imgName!=nil)
       {  
         NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",g_pref_skin,imgName];   
         //printf("%s\n",[name UTF8String]);
         UIImage *img = [self loadImage: name];
         [dpadView setImage:img];
         [dpadView setNeedsDisplay];
       }           
       old_dpad_state = dpad_state;
        
        NSLog(@"dpad moved");
        if (dpad_state == DPAD_NONE) {
            [self.selectionFeedback selectionChanged];
        } else {
            [self.impactFeedback impactOccurred];
        }
    }
    
    int i = 0;
    for(i=0; i< NUM_BUTTONS;i++)
    {
        if(btnStates[i] != old_btnStates[i])
        {
           NSString *imgName;
           if(btnStates[i] == BUTTON_PRESS)
           {
               NSLog(@"button pressed");
               [self.impactFeedback impactOccurred];
               imgName = nameImgButton_Press[i];
           }
           else
           {
               NSLog(@"button released");
               [self.selectionFeedback selectionChanged];
               imgName = nameImgButton_NotPress[i];
           } 
           if(imgName!=nil)
           {  
              NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",g_pref_skin,imgName];
              UIImage *img = [self loadImage:name];
              [buttonViews[i] setImage:img];
              [buttonViews[i] setNeedsDisplay];              
           }
           old_btnStates[i] = btnStates[i]; 
        }
    }
    
}

#pragma mark Touch Handling
-(NSSet*)touchHandler:(NSSet *)touches withEvent:(UIEvent *)event {
    if(change_layout)
    {
        [layoutView handleTouches:touches withEvent: event];
    }
    else if((g_joy_used &&
             (
              (!g_device_is_landscape && g_pref_full_screen_port) ||
              (g_device_is_landscape && g_pref_full_screen_land))
             )
            )
    {
        // If controller is connected and display is full screen:
        // handle lightgun touches or
        // analog touches
        // else show the menu if touched
        NSSet *allTouches = [event allTouches];
        UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
        
        if ( myosd_light_gun == 1 && g_pref_lightgun_enabled ) {
            [self handleLightgunTouchesBegan:touches];
            return nil;
        }
        
        if ( myosd_mouse == 1 && g_pref_touch_analog_enabled ) {
            return nil;
        }
        
        if(touch.phase == UITouchPhaseBegan)
        {
            [self runMenu];
        }
    }
    else
    {
        return [self touchesController:touches withEvent:event];
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"👉👉👉👉👉👉 Touch Began!!! 👉👉👉👉👉👉👉");
    NSSet *handledTouches = [self touchHandler:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    NSMutableSet *unhandledTouches = [NSMutableSet set];
    for (int i =0; i < allTouches.count; i++) {
        UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
        if ( ![handledTouches containsObject:touch] ) {
            [unhandledTouches addObject:touch];
        }
    }
    if ( g_pref_touch_analog_enabled && myosd_mouse == 1 && unhandledTouches.count > 0 ) {
        [self handleMouseTouchesBegan:unhandledTouches];
    }
    if ( g_pref_touch_directional_enabled && unhandledTouches.count > 0 ) {
        [self handleTouchMovementTouchesBegan:unhandledTouches];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"👋👋👋👋👋👋👋 Touch Moved!!! 👋👋👋👋👋👋👋👋");
    NSSet *handledTouches = [self touchHandler:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    NSMutableSet *unhandledTouches = [NSMutableSet set];
    for (int i =0; i < allTouches.count; i++) {
        UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
        if ( ![handledTouches containsObject:touch] ) {
            [unhandledTouches addObject:touch];
        }
    }
    if ( g_pref_touch_analog_enabled && myosd_mouse == 1 && unhandledTouches.count > 0 ) {
        [self handleMouseTouchesMoved:unhandledTouches];
    }
    if ( g_pref_touch_directional_enabled && unhandledTouches.count > 0 ) {
        [self handleTouchMovementTouchesMoved:unhandledTouches];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"👊👊👊👊👊👊 Touch Cancelled!!! 👊👊👊👊👊👊");
    NSSet *handledTouches = [self touchHandler:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    NSMutableSet *unhandledTouches = [NSMutableSet set];
    for (int i =0; i < allTouches.count; i++) { 
        UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
        if ( ![handledTouches containsObject:touch] ) {
            [unhandledTouches addObject:touch];
        }
    }
    if ( g_pref_touch_analog_enabled && myosd_mouse == 1 && unhandledTouches.count > 0 ) {
        [self handleMouseTouchesBegan:unhandledTouches];
    }
    if ( g_pref_touch_directional_enabled && unhandledTouches.count > 0 ) {
        [self handleTouchMovementTouchesBegan:unhandledTouches];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"🖐🖐🖐🖐🖐🖐🖐 Touch Ended!!! 🖐🖐🖐🖐🖐🖐");
    [self touchHandler:touches withEvent:event];
    
    // light gun release?
    if ( myosd_light_gun == 1 && g_pref_lightgun_enabled ) {
        myosd_pad_status &= ~MYOSD_B;
        myosd_joy_status[0] &= ~MYOSD_B;
        myosd_pad_status &= ~MYOSD_X;
        myosd_joy_status[0] &= ~MYOSD_X;
    }
    
    if ( g_pref_touch_analog_enabled && myosd_mouse == 1 ) {
        mouse_x[0] = 0.0f;
        mouse_y[0] = 0.0f;
    }
    
    if ( g_pref_touch_directional_enabled ) {
        myosd_pad_status &= ~MYOSD_DOWN;
        myosd_pad_status &= ~MYOSD_UP;
        myosd_pad_status &= ~MYOSD_LEFT;
        myosd_pad_status &= ~MYOSD_RIGHT;
    }
}

- (NSSet*)touchesController:(NSSet *)touches withEvent:(UIEvent *)event {
    
    int i;
    static UITouch *stickTouch = nil;
    BOOL stickWasTouched = NO;
    BOOL buttonTouched = NO;
    NSMutableSet *handledTouches = [NSMutableSet set];
    
    //Get all the touches.
    NSSet *allTouches = [event allTouches];
    NSUInteger touchcount = [allTouches count];
    
    //myosd_pad_status = 0;
    myosd_pad_status &= ~MYOSD_X;
    myosd_pad_status &= ~MYOSD_Y;
    myosd_pad_status &= ~MYOSD_A;
    myosd_pad_status &= ~MYOSD_B;
    myosd_pad_status &= ~MYOSD_SELECT;
    myosd_pad_status &= ~MYOSD_START;
    myosd_pad_status &= ~MYOSD_L1;
    myosd_pad_status &= ~MYOSD_R1;
    
    for(i=0; i<NUM_BUTTONS;i++)
    {
        btnStates[i] = BUTTON_NO_PRESS;
    }
    
    if ( areControlsHidden && g_pref_lightgun_enabled && g_device_is_landscape) {
        [self handleLightgunTouchesBegan:touches];
        return NO;
    }
    
    for (i = 0; i < touchcount; i++)
    {
        UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
        
        if(touch == nil)
        {
            continue;
        }
        
        if( touch.phase == UITouchPhaseBegan        ||
           touch.phase == UITouchPhaseMoved        ||
           touch.phase == UITouchPhaseStationary    )
        {
            struct CGPoint point;
            point = [touch locationInView:self.view];
            BOOL touch_dpad_disabled =
                // touch mouse is enabled and hiding dpad
                (myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_dpad) ||
                // OR directional touch is enabled and hiding dpad, and running a game
                (g_pref_touch_directional_enabled && g_pref_touch_analog_hide_dpad && myosd_inGame);
            if(g_pref_input_touch_type == TOUCH_INPUT_DPAD && !touch_dpad_disabled )
            {
                if (MyCGRectContainsPoint(rInput[DPAD_UP_RECT], point) && !STICK2WAY) {
                    //NSLog(@"MYOSD_UP");
                    myosd_pad_status |= MYOSD_UP;
                    dpad_state = DPAD_UP;
                    
                    myosd_pad_status &= ~MYOSD_DOWN;
                    myosd_pad_status &= ~MYOSD_LEFT;
                    myosd_pad_status &= ~MYOSD_RIGHT;
                    
                    stickTouch = touch;
                    stickWasTouched = YES;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_DOWN_RECT], point) && !STICK2WAY) {
                    //NSLog(@"MYOSD_DOWN");
                    myosd_pad_status |= MYOSD_DOWN;
                    dpad_state = DPAD_DOWN;
                    
                    myosd_pad_status &= ~MYOSD_UP;
                    myosd_pad_status &= ~MYOSD_LEFT;
                    myosd_pad_status &= ~MYOSD_RIGHT;
                    
                    stickTouch = touch;
                    stickWasTouched = YES;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_LEFT_RECT], point)) {
                    //NSLog(@"MYOSD_LEFT");
                    myosd_pad_status |= MYOSD_LEFT;
                    dpad_state = DPAD_LEFT;
                    
                    myosd_pad_status &= ~MYOSD_UP;
                    myosd_pad_status &= ~MYOSD_DOWN;
                    myosd_pad_status &= ~MYOSD_RIGHT;
                    
                    stickTouch = touch;
                    stickWasTouched = YES;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_RIGHT_RECT], point)) {
                    //NSLog(@"MYOSD_RIGHT");
                    myosd_pad_status |= MYOSD_RIGHT;
                    dpad_state = DPAD_RIGHT;
                    
                    myosd_pad_status &= ~MYOSD_UP;
                    myosd_pad_status &= ~MYOSD_DOWN;
                    myosd_pad_status &= ~MYOSD_LEFT;
                    
                    stickTouch = touch;
                    stickWasTouched = YES;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_UP_LEFT_RECT], point)) {
                    //NSLog(@"MYOSD_UP | MYOSD_LEFT");
                    if(!STICK2WAY && !STICK4WAY)
                    {
                        myosd_pad_status |= MYOSD_UP | MYOSD_LEFT;
                        dpad_state = DPAD_UP_LEFT;
                        
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_RIGHT;
                    }
                    else
                    {
                        myosd_pad_status |= MYOSD_LEFT;
                        dpad_state = DPAD_LEFT;
                        
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_RIGHT;
                    }
                    stickWasTouched = YES;
                    stickTouch = touch;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_UP_RIGHT_RECT], point)) {
                    //NSLog(@"MYOSD_UP | MYOSD_RIGHT");
                    
                    if(!STICK2WAY && !STICK4WAY)
                    {
                        myosd_pad_status |= MYOSD_UP | MYOSD_RIGHT;
                        dpad_state = DPAD_UP_RIGHT;
                        
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_LEFT;
                    }
                    else
                    {
                        myosd_pad_status |= MYOSD_RIGHT;
                        dpad_state = DPAD_RIGHT;
                        
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_LEFT;
                    }
                    stickWasTouched = YES;
                    stickTouch = touch;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_DOWN_LEFT_RECT], point)) {
                    //NSLog(@"MYOSD_DOWN | MYOSD_LEFT");
                    
                    if(!STICK2WAY && !STICK4WAY)
                    {
                        myosd_pad_status |= MYOSD_DOWN | MYOSD_LEFT;
                        dpad_state = DPAD_DOWN_LEFT;
                        
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_RIGHT;
                    }
                    else
                    {
                        myosd_pad_status |= MYOSD_LEFT;
                        dpad_state = DPAD_LEFT;
                        
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_RIGHT;
                    }
                    stickWasTouched = YES;
                    stickTouch = touch;
                    [handledTouches addObject:touch];
                }
                else if (MyCGRectContainsPoint(rInput[DPAD_DOWN_RIGHT_RECT], point)) {
                    //NSLog(@"MYOSD_DOWN | MYOSD_RIGHT");
                    if(!STICK2WAY && !STICK4WAY)
                    {
                        myosd_pad_status |= MYOSD_DOWN | MYOSD_RIGHT;
                        dpad_state = DPAD_DOWN_RIGHT;
                        
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_LEFT;
                    }
                    else
                    {
                        myosd_pad_status |= MYOSD_RIGHT;
                        dpad_state = DPAD_RIGHT;
                        
                        myosd_pad_status &= ~MYOSD_DOWN;
                        myosd_pad_status &= ~MYOSD_UP;
                        myosd_pad_status &= ~MYOSD_LEFT;
                    }
                    stickWasTouched = YES;
                    stickTouch = touch;
                    [handledTouches addObject:touch];
                }
            }
            else
            {
                if(MyCGRectContainsPoint(analogStickView.frame, point) || stickTouch == touch)
                {
                    //if(stickTouch==nil)
                    stickTouch = touch;
                    //if(touch == stickTouch)
                    [analogStickView analogTouches:touch withEvent:event];
                }
            }
            
            if(touch == stickTouch) continue;
            
            BOOL touch_buttons_disabled = myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_buttons;
            
            if (buttonViews[BTN_Y] != nil &&
                !buttonViews[BTN_Y].hidden && MyCGRectContainsPoint(rInput[BTN_Y_RECT], point) &&
                !touch_buttons_disabled) {
                myosd_pad_status |= MYOSD_Y;
                btnStates[BTN_Y] = BUTTON_PRESS;
                buttonTouched = YES;
                //NSLog(@"MYOSD_Y");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_X] != nil &&
                     !buttonViews[BTN_X].hidden && MyCGRectContainsPoint(rInput[BTN_X_RECT], point) &&
                     !touch_buttons_disabled) {
                myosd_pad_status |= MYOSD_X;
                btnStates[BTN_X] = BUTTON_PRESS;
                buttonTouched = YES;
                //NSLog(@"MYOSD_X");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_A] != nil &&
                     !buttonViews[BTN_A].hidden && MyCGRectContainsPoint(rInput[BTN_A_RECT], point) &&
                     !touch_buttons_disabled) {
                if(g_pref_BplusX)
                {
                    myosd_pad_status |= MYOSD_X | MYOSD_B;
                    btnStates[BTN_B] = BUTTON_PRESS;
                    btnStates[BTN_X] = BUTTON_PRESS;
                    btnStates[BTN_A] = BUTTON_PRESS;
                }
                else
                {
                    myosd_pad_status |= MYOSD_A;
                    btnStates[BTN_A] = BUTTON_PRESS;
                }
                buttonTouched = YES;
                //NSLog(@"MYOSD_A");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_B] != nil && !buttonViews[BTN_B].hidden && MyCGRectContainsPoint(rInput[BTN_B_RECT], point) &&
                     !touch_buttons_disabled) {
                myosd_pad_status |= MYOSD_B;
                btnStates[BTN_B] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_B");
            }
            else if (buttonViews[BTN_A] != nil &&
                     buttonViews[BTN_Y] != nil &&
                     !buttonViews[BTN_A].hidden &&
                     !buttonViews[BTN_Y].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_A_Y_RECT], point) &&
                     !touch_buttons_disabled) {
                myosd_pad_status |= MYOSD_Y | MYOSD_A;
                btnStates[BTN_Y] = BUTTON_PRESS;
                btnStates[BTN_A] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_Y | MYOSD_A");
            }
            else if (buttonViews[BTN_X] != nil &&
                     buttonViews[BTN_A] != nil &&
                     !buttonViews[BTN_X].hidden &&
                     !buttonViews[BTN_A].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_X_A_RECT], point) &&
                     !touch_buttons_disabled) {
                
                myosd_pad_status |= MYOSD_X | MYOSD_A;
                btnStates[BTN_A] = BUTTON_PRESS;
                btnStates[BTN_X] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_X | MYOSD_A");
            }
            else if (buttonViews[BTN_Y] != nil &&
                     buttonViews[BTN_B] != nil &&
                     !buttonViews[BTN_Y].hidden &&
                     !buttonViews[BTN_B].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_B_Y_RECT], point) &&
                     !touch_buttons_disabled) {
                myosd_pad_status |= MYOSD_Y | MYOSD_B;
                btnStates[BTN_B] = BUTTON_PRESS;
                btnStates[BTN_Y] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_Y | MYOSD_B");
            }
            else if (!buttonViews[BTN_B].hidden &&
                     !buttonViews[BTN_X].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_B_X_RECT], point) &&
                     !touch_buttons_disabled) {
                if(!g_pref_BplusX /*&& g_pref_land_num_buttons>=3*/)
                {
                    myosd_pad_status |= MYOSD_X | MYOSD_B;
                    btnStates[BTN_B] = BUTTON_PRESS;
                    btnStates[BTN_X] = BUTTON_PRESS;
                    buttonTouched = YES;
                    [handledTouches addObject:touch];
                }
                //NSLog(@"MYOSD_X | MYOSD_B");
            }
            else if (MyCGRectContainsPoint(rInput[BTN_SELECT_RECT], point)) {
                //NSLog(@"MYOSD_SELECT");
                myosd_pad_status |= MYOSD_SELECT;
                btnStates[BTN_SELECT] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                if(isGridlee && (myosd_pad_status & MYOSD_START))
                    myosd_pad_status &= ~MYOSD_START;
                
            }
            else if (MyCGRectContainsPoint(rInput[BTN_START_RECT], point)) {
                //NSLog(@"MYOSD_START");
                myosd_pad_status |= MYOSD_START;
                btnStates[BTN_START] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                if(isGridlee && (myosd_pad_status & MYOSD_SELECT))
                    myosd_pad_status &= ~MYOSD_SELECT;
            }
            else if (buttonViews[BTN_L1] != nil && !buttonViews[BTN_L1].hidden && MyCGRectContainsPoint(rInput[BTN_L1_RECT], point) && !touch_buttons_disabled) {
                //NSLog(@"MYOSD_L");
                myosd_pad_status |= MYOSD_L1;
                btnStates[BTN_L1] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_R1] != nil && !buttonViews[BTN_R1].hidden && MyCGRectContainsPoint(rInput[BTN_R1_RECT], point) && !touch_buttons_disabled ) {
                //NSLog(@"MYOSD_R");
                myosd_pad_status |= MYOSD_R1;
                btnStates[BTN_R1] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_L2] != nil && !buttonViews[BTN_L2].hidden && MyCGRectContainsPoint(rInput[BTN_L2_RECT], point)) {
                //NSLog(@"MYOSD_L2");
                if(isGridlee)continue;
                btnStates[BTN_L2] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
                exit_status = 1;
            }
            else if (buttonViews[BTN_R2] != nil && !buttonViews[BTN_R2].hidden && MyCGRectContainsPoint(rInput[BTN_R2_RECT], point) ) {
                //NSLog(@"MYOSD_R2");
                if(isGridlee)continue;
                btnStates[BTN_R2] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
            }
            else if (MyCGRectContainsPoint(rInput[BTN_MENU_RECT], point)) {
                /*
                 myosd_pad_status |= MYOSD_SELECT;
                 btnStates[BTN_SELECT] = BUTTON_PRESS;
                 myosd_pad_status |= MYOSD_START;
                 btnStates[BTN_START] = BUTTON_PRESS;
                 */
            } else if ( myosd_light_gun == 1 && g_pref_lightgun_enabled ) {
                [self handleLightgunTouchesBegan:touches];
            }
            
        }
        else
        {
            if(touch == stickTouch)
            {
                if(g_pref_input_touch_type == TOUCH_INPUT_DPAD)
                {
                    myosd_pad_status &= ~MYOSD_UP;
                    myosd_pad_status &= ~MYOSD_DOWN;
                    myosd_pad_status &= ~MYOSD_LEFT;
                    myosd_pad_status &= ~MYOSD_RIGHT;
                    dpad_state = DPAD_NONE;
                }
                else
                {
                    [analogStickView analogTouches:touch withEvent:event];
                    stickWasTouched = YES;
                }
                stickTouch = nil;
            }
            else if(exit_status==1)
            {
                exit_status=2;
            }
        }
    }
    
    [self handle_MENU];
    [self handle_DPAD];
    
//    BOOL touchWasHandled = stickTouch != nil || buttonTouched;
//    NSLog(@"touchController touch stick touch =  %@ , buttonTouched = %@, wasStickTouched = %@",stickTouch != nil ? @"YES" : @"NO",buttonTouched ? @"YES" : @"NO",stickWasTouched ? @"YES" : @"NO");
    return handledTouches;
}


#pragma mark - Lightgun Touch Handler

- (void) handleLightgunTouchesBegan:(NSSet *)touches {
    NSUInteger touchcount = touches.count;
    if ( screenView != nil ) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint touchLoc = [touch locationInView:screenView];
        CGFloat newX = (touchLoc.x - (screenView.bounds.size.width / 2.0f)) / (screenView.bounds.size.width / 2.0f);
        CGFloat newY = (touchLoc.y - (screenView.bounds.size.height / 2.0f)) / (screenView.bounds.size.height / 2.0f) * -1.0f;
//        NSLog(@"touch began light gun? loc: %f, %f",touchLoc.x, touchLoc.y);
//        NSLog(@"new loc = %f , %f",newX,newY);
        myosd_joy_status[0] |= MYOSD_B;
        myosd_pad_status |= MYOSD_B;
        if ( touchcount > 3 ) {
            // 4 touches = insert coin
            myosd_pad_status |= MYOSD_SELECT;
            myosd_joy_status[0] |= MYOSD_SELECT;
            [self performSelector:@selector(releaseCoin:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.1];
        } else if ( touchcount > 2 ) {
            // 3 touches = press start
            myosd_pad_status |= MYOSD_START;
            myosd_joy_status[0] |= MYOSD_START;
            [self performSelector:@selector(releaseStart:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.1];
        } else if ( touchcount > 1 ) {
            // more than one touch means secondary button press
            myosd_pad_status |= MYOSD_X;
            myosd_joy_status[0] |= MYOSD_X;
            myosd_pad_status &= ~MYOSD_B;
            myosd_joy_status[0] &= ~MYOSD_B;
        } else if ( touchcount == 1 ) {
            if ( g_pref_lightgun_bottom_reload && newY < -0.80 ) {
                newY = -12.1f;
            }
            lightgun_x[0] = newX;
            lightgun_y[0] = newY;
        }
    }
}

#pragma mark - Mouse Touch Support

-(void) handleMouseTouchesBegan:(NSSet *)touches {
    if ( screenView != nil ) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        mouseTouchStartLocation = [touch locationInView:screenView];
    }
}

- (void) handleMouseTouchesMoved:(NSSet *)touches {
    if ( screenView != nil && !CGPointEqualToPoint(mouseTouchStartLocation, mouseInitialLocation) ) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint currentLocation = [touch locationInView:screenView];
        CGFloat dx = currentLocation.x - mouseTouchStartLocation.x;
        CGFloat dy = currentLocation.y - mouseTouchStartLocation.y;
        mouse_x[0] = dx * g_pref_touch_analog_sensitivity;
        mouse_y[0] = dy * g_pref_touch_analog_sensitivity;
        NSLog(@"mouse x = %f , mouse y = %f",mouse_x[0],mouse_y[0]);
        mouseTouchStartLocation = [touch locationInView:screenView];
    }
}

#pragma mark - Touch Movement Support
-(void) handleTouchMovementTouchesBegan:(NSSet *)touches {
    if ( screenView != nil ) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        touchDirectionalMoveStartLocation = [touch locationInView:screenView];
    }
}

-(void) handleTouchMovementTouchesMoved:(NSSet *)touches {
    if ( screenView != nil && !CGPointEqualToPoint(touchDirectionalMoveStartLocation, mouseInitialLocation) ) {
        myosd_pad_status &= ~MYOSD_DOWN;
        myosd_pad_status &= ~MYOSD_UP;
        myosd_pad_status &= ~MYOSD_LEFT;
        myosd_pad_status &= ~MYOSD_RIGHT;
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint currentLocation = [touch locationInView:screenView];
        CGFloat dx = currentLocation.x - touchDirectionalMoveStartLocation.x;
        CGFloat dy = currentLocation.y - touchDirectionalMoveStartLocation.y;
        int threshold = 2;
        if ( dx > threshold ) {
            myosd_pad_status |= MYOSD_RIGHT;
            myosd_pad_status &= ~MYOSD_LEFT;
        } else if ( dx < -threshold ) {
            myosd_pad_status &= ~MYOSD_RIGHT;
            myosd_pad_status |= MYOSD_LEFT;
        }
        if ( dy > threshold ) {
            myosd_pad_status |= MYOSD_DOWN;
            myosd_pad_status &= ~MYOSD_UP;
        } else if (dy < -threshold ) {
            myosd_pad_status &= ~MYOSD_DOWN;
            myosd_pad_status |= MYOSD_UP;
        }
        if ( touchDirectionalCyclesAfterMoved++ > 5 ) {
            touchDirectionalMoveStartLocation = [touch locationInView:screenView];
            touchDirectionalCyclesAfterMoved = 0;
        }
    }
}


- (void)getControllerCoords:(int)orientation {
    char string[256];
    FILE *fp;
    
    DeviceScreenType screenType = [DeviceScreenResolver resolve];
    NSString *deviceName = nil;
	
    if ( screenType == IPHONE_XR_XS_MAX ) {
        deviceName = @"iPhone_xr_xs_max";
    } else if ( screenType == IPHONE_X_XS ) {
        deviceName = @"iPhone_x";
    } else if ( screenType == IPHONE_6_7_8_PLUS ) {
        deviceName = @"iPhone_6_plus";
    } else if ( screenType == IPHONE_6_7_8 ) {
        deviceName = @"iPhone_6";
    } else if ( screenType == IPHONE_5 ) {
        deviceName = @"iPhone_5";
    } else if ( screenType == IPHONE_4_OR_LESS ) {
        deviceName = @"iPhone";
    } else if ( g_isIpad ) {
        if ( screenType == IPAD_PRO_12_9 ) {
            deviceName = @"iPad_pro_12_9";
        } else if ( screenType == IPAD_PRO_10_5 ) {
            deviceName = @"iPad_pro_10_5";
        } else if ( screenType == IPAD ) {
            deviceName = @"iPad";
        } else {
            deviceName = @"config_iPad_pro_12_9";
        }
    } else {
        // default to the largest iPhone if unknown
        deviceName = @"iPhone_xr_xs_max";
    }
    
	if(!orientation)
	{
        if(g_pref_full_screen_port)
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_portrait_full_%@.txt", g_skin_data, deviceName] UTF8String]];
        else
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_portrait_%@.txt", g_skin_data, deviceName] UTF8String]];
    }
	else
	{
        if(g_pref_full_screen_land)
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_landscape_full_%@.txt", g_skin_data,deviceName] UTF8String]];
        else
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_landscape_%@.txt", g_skin_data, deviceName] UTF8String]];
	}
	
	if (fp) 
	{

		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 39) 
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
						
			switch(i)
			{
    		case 0:    rInput[DPAD_DOWN_LEFT_RECT]   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 1:    rInput[DPAD_DOWN_RECT]   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 2:    rInput[DPAD_DOWN_RIGHT_RECT]    = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 3:    rInput[DPAD_LEFT_RECT]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 4:    rInput[DPAD_RIGHT_RECT]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 5:    rInput[DPAD_UP_LEFT_RECT]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 6:    rInput[DPAD_UP_RECT]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 7:    rInput[DPAD_UP_RIGHT_RECT]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 8:    rInput[BTN_SELECT_RECT] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 9:    rInput[BTN_START_RECT]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 10:   rInput[BTN_L1_RECT]   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 11:   rInput[BTN_R1_RECT]   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 12:   rInput[BTN_MENU_RECT]   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 13:   rInput[BTN_X_A_RECT]   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 14:   rInput[BTN_X_RECT]   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 15:   rInput[BTN_B_X_RECT]    	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 16:   rInput[BTN_A_RECT]  		= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 17:   rInput[BTN_B_RECT]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 18:   rInput[BTN_A_Y_RECT]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 19:   rInput[BTN_Y_RECT]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 20:   rInput[BTN_B_Y_RECT]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 21:   rInput[BTN_L2_RECT]   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 22:   rInput[BTN_R2_RECT]   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 23:    break;
    		
    		case 24:   rButtonImages[BTN_B] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 25:   rButtonImages[BTN_X]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 26:   rButtonImages[BTN_A]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 27:   rButtonImages[BTN_Y]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 28:   rDPadImage  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 29:   rButtonImages[BTN_SELECT]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 30:   rButtonImages[BTN_START]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 31:   rButtonImages[BTN_L1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 32:   rButtonImages[BTN_R1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 33:   rButtonImages[BTN_L2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 34:   rButtonImages[BTN_R2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            
            case 35:   rStickWindow = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 36:   rStickArea = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); rStickWindow = rStickArea;break;
            case 37:   stick_radio =coords[0]; break;            
//            case 38:   g_controller_opacity= coords[0]; break;
			}
      i++;
    }
    fclose(fp);
    
    if(g_pref_touch_DZ)
    {
        //ajustamos
        if(!g_isIpad)
        {
           if(!orientation)
           {
             rInput[DPAD_LEFT_RECT].size.width -= 17;//Left.size.width * 0.2;
             rInput[DPAD_RIGHT_RECT].origin.x += 17;//Right.size.width * 0.2;
             rInput[DPAD_RIGHT_RECT].size.width -= 17;//Right.size.width * 0.2;
           }
           else
           {
             rInput[DPAD_LEFT_RECT].size.width -= 14;
             rInput[DPAD_RIGHT_RECT].origin.x += 20;
             rInput[DPAD_RIGHT_RECT].size.width -= 20;
           }
        }
        else
        {
           if(!orientation)
           {
             rInput[DPAD_LEFT_RECT].size.width -= 22;//Left.size.width * 0.2;
             rInput[DPAD_RIGHT_RECT].origin.x += 22;//Right.size.width * 0.2;
             rInput[DPAD_RIGHT_RECT].size.width -= 22;//Right.size.width * 0.2;
           }
           else
           {
             rInput[DPAD_LEFT_RECT].size.width -= 22;
             rInput[DPAD_RIGHT_RECT].origin.x += 22;
             rInput[DPAD_RIGHT_RECT].size.width -= 22;
           }
        }    
    }
  }
}

- (void)getConf{
    char string[256];
    FILE *fp;
    
    DeviceScreenType screenType = [DeviceScreenResolver resolve];
	
    if ( screenType == IPHONE_XR_XS_MAX ) {
        fp = [self loadFile:"config_iPhone_xr_xs_max.txt"];
    } else if ( screenType == IPHONE_X_XS ) {
        fp = [self loadFile:"config_iPhone_x.txt"];
    } else if ( screenType == IPHONE_6_7_8_PLUS ) {
        fp = [self loadFile:"config_iPhone_6_plus.txt"];
    } else if ( screenType == IPHONE_6_7_8 ) {
        fp = [self loadFile:"config_iPhone_6.txt"];
    } else if ( screenType == IPHONE_5 ) {
        fp = [self loadFile:"config_iPhone_5.txt"];
    } else if ( screenType == IPHONE_4_OR_LESS ) {
        fp = [self loadFile:"config_iPhone.txt"];
    } else if ( g_isIpad ) {
        if ( screenType == IPAD_PRO_12_9 ) {
            fp  = [self loadFile:"config_iPad_pro_12_9.txt"];
        } else if ( screenType == IPAD_PRO_10_5 ) {
            fp  = [self loadFile:"config_iPad_pro_10_5.txt"];
        } else if ( screenType == IPAD ) {
            fp = [self loadFile:"config_iPad.txt"];
        } else {
            fp = [self loadFile:"config_iPad_pro_12_9.txt"];
        }
    } else {
        // default to the largest iPhone if unknown
       fp = [self loadFile:"config_iPhone_xr_xs_max.txt"];
    }

	if (fp) 
	{
		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 14)
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
						
			switch(i)
			{
	    		case 0:    rFrames[PORTRAIT_VIEW_FULL]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 1:    rFrames[PORTRAIT_VIEW_NOT_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 2:    rFrames[PORTRAIT_IMAGE_BACK]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 3:    rFrames[PORTRAIT_IMAGE_OVERLAY]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		
                case 4:    rFrames[LANDSCAPE_VIEW_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 5:    rFrames[LANDSCAPE_VIEW_NOT_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 6:    rFrames[LANDSCAPE_IMAGE_BACK]  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
	    		case 7:    rFrames[LANDSCAPE_IMAGE_OVERLAY]     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                    
	            case 8:    g_enable_debug_view = coords[0]; break;
	            //case 9:    main_thread_priority_type = coords[0]; break;
	            //case 10:   video_thread_priority_type = coords[0]; break;
			}
      i++;
    }
    fclose(fp);
  }
}


- (void)didReceiveMemoryWarning {
	//[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {

    [self removeTouchControllerViews];

    [screenView release];
    
    [imageBack release];
      
    [imageOverlay release];
 
    [dview release];
    
    [icadeView release];
	   
	[super dealloc];
}

- (CGRect *)getDebugRects{
    return debug_rects;
}

- (void)filldebugRects {

	    	debug_rects[0]=rInput[BTN_X_A_RECT];
	    	debug_rects[1]=rInput[BTN_X_RECT];
	    	debug_rects[2]=rInput[BTN_B_X_RECT];
	    	debug_rects[3]=rInput[BTN_A_RECT];
	    	debug_rects[4]=rInput[BTN_B_RECT];
	    	debug_rects[5]=rInput[BTN_A_Y_RECT];
	    	debug_rects[6]=rInput[BTN_Y_RECT];
	        debug_rects[7]=rInput[BTN_B_Y_RECT];
    		debug_rects[8]=rInput[BTN_SELECT_RECT];
    		debug_rects[9]=rInput[BTN_START_RECT];
    		debug_rects[10]=rInput[BTN_L1_RECT];
    		debug_rects[11]=rInput[BTN_R1_RECT];
    		debug_rects[12]=rInput[BTN_MENU_RECT];
    		debug_rects[13]=rInput[BTN_L2_RECT];
    		debug_rects[14]=rInput[BTN_R2_RECT];
    		debug_rects[15]= CGRectZero;
    		
    		if(g_pref_input_touch_type==TOUCH_INPUT_DPAD)
    		{
				debug_rects[16]=rInput[DPAD_DOWN_LEFT_RECT];
				debug_rects[17]=rInput[DPAD_DOWN_RECT];
				debug_rects[18]=rInput[DPAD_DOWN_RIGHT_RECT];
				debug_rects[19]=rInput[DPAD_LEFT_RECT];
				debug_rects[20]=rInput[DPAD_RIGHT_RECT];
				debug_rects[21]=rInput[DPAD_UP_LEFT_RECT];
				debug_rects[22]=rInput[DPAD_UP_RECT];
				debug_rects[23]=rInput[DPAD_UP_RIGHT_RECT];
	    		
	            num_debug_rects = 24;     
            }
            else
            {
  	    		debug_rects[16]=rStickWindow;
	    		debug_rects[17]=rStickArea;
	    		
	            num_debug_rects = 18;
            }   
}

- (UIImage *)loadImage:(NSString *)name{
    
    NSString *path = nil;
    UIImage *img = nil;
    
    path=[NSString stringWithUTF8String:get_documents_path((char *)[name UTF8String])];
    
    img = [UIImage imageWithContentsOfFile:path];
    
    if(img==nil)
    {
       path=[NSString stringWithUTF8String:get_resource_path((char *)[name UTF8String])];
       img = [UIImage imageWithContentsOfFile:path];
    }
    return img;
}

-(FILE *)loadFile:(const char *)name{
    NSString *path = nil;
    FILE *fp;
    
    path = [NSString stringWithFormat:@"%s%s", get_documents_path("/"),name];
    fp = fopen([path UTF8String], "r");
    
    if(!fp)
    {
        path = [NSString stringWithFormat:@"%s%s", get_resource_path("/"),name];
        fp = fopen([path UTF8String], "r");
    }
    
    return fp;
}

-(void)moveROMS {
    NSFileManager *filemgr;
    NSArray *filelist;
    int count;
    int i;
    
    //NSLog(@"checking roms!");
    
    filemgr = [[NSFileManager alloc] init];
    
    NSString *fromPath = [NSString stringWithUTF8String:get_documents_path("")];
    filelist = [filemgr contentsOfDirectoryAtPath:fromPath error:nil];
    count = [filelist count];
    
    NSMutableArray *romlist = [[NSMutableArray alloc] init];
    for (i = 0; i < count; i++)
    {
        NSString *file = [filelist objectAtIndex: i];
        if([file isEqualToString:@"cheat.zip"])
            continue;
        if(![file hasSuffix:@".zip"])
            continue;
        [romlist addObject: file];
    }
    count = [romlist count];
    
    [filemgr release];
    
    if(count!=0)
    {
        UIAlertView *progressAlert = [[UIAlertView alloc] initWithTitle: @"Moving Newer ROMs"
                                                                message: @"Please wait..."
                                                               delegate: self
                                                      cancelButtonTitle: nil
                                                      otherButtonTitles: nil];
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
        [progressAlert addSubview:progressView];
        [progressView setProgressViewStyle: UIProgressViewStyleBar];
        
        [progressAlert show];
        [progressView setProgress:0.0f];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSFileManager *filemgr = [[NSFileManager alloc] init];
            NSError *error = nil;
            int i=0;
            
            NSString *fromPath = [NSString stringWithUTF8String:get_documents_path("")];
            NSString *toPath  = [NSString stringWithUTF8String:get_documents_path("roms")];
            [NSThread sleepForTimeInterval:1.5];
            
            BOOL err = FALSE;            
            for (i = 0; i < count; i++)
            {
                NSString *romName = [romlist objectAtIndex: i];
                //NSLog(@"%@", romName);
                
                //first attemp to delete de old one
                [filemgr removeItemAtPath:[toPath stringByAppendingPathComponent:romName] error:&error];
                
                //now move it
                error = nil;
                [filemgr moveItemAtPath: [fromPath stringByAppendingPathComponent:romName]
                                 toPath: [toPath stringByAppendingPathComponent:romName]
                                  error:&error];
                if(error!=nil)
                {
                    NSLog(@"Unable to move rom: %@", [error localizedDescription]);
                    err = TRUE;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progressView setProgress:(i / (float)count)];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
                [progressAlert release];
                [progressView release];
                if(err == FALSE)
                {
                   if(!(myosd_in_menu==0 && myosd_inGame)){
                      myosd_reset_filter = 1;
                   }
                   myosd_last_game_selected = 0;
                }
            });
            
            [filemgr release];
            [romlist release];
        });
        
    }
    else
    {
        [romlist release];
    }
}
     
-(void)beginCustomizeCurrentLayout{
    
    
    if((g_joy_used && ((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land))))
    {
        UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                              message:@"You cannot customize current layout when using a external controller!"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Dismiss"
                                                    otherButtonTitles:nil];
        [exitAlertView show];
        [exitAlertView release];
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
        
        [self changeUI]; //ensure GUI
        
        [screenView removeFromSuperview];
        [screenView release];
        screenView = nil;
        
        layoutView = [[LayoutView alloc] initWithFrame:self.view.bounds withEmuController:self];
        
        change_layout = 1;
        
        [self removeTouchControllerViews];
        
        [self buildTouchControllerViews];
        
        [self.view addSubview:layoutView];
    }
    
}

-(void)finishCustomizeCurrentLayout{
    
    [layoutView removeFromSuperview];
    [layoutView release];
    
    change_layout = 0;

    [self done:self];
        
}

-(void)resetCurrentLayout{
    
    if((g_joy_used && ((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land))))
    {
        UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                              message:@"You cannot reset current layout when using a external controller!"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Dismiss"
                                                    otherButtonTitles:nil];
        [exitAlertView show];
        [exitAlertView release];
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
        
        [self changeUI]; //ensure GUI
        
        [screenView removeFromSuperview];
        [screenView release];
        screenView = nil;
        
        change_layout = 1;
        
        [self removeTouchControllerViews];
        
        [self buildTouchControllerViews];
        
        
        UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                              message:@"Do you want to reset current layout to default?"
                                                             delegate:self cancelButtonTitle:nil
                                                    otherButtonTitles:@"Yes",@"No",nil];
        [exitAlertView show];
        [exitAlertView release];
    }
}

-(void)adjustSizes{
    
    int i= 0;
    
    for(i=0;i<INPUT_LAST_VALUE;i++)
    {
        if(i==BTN_Y_RECT ||
           i==BTN_A_RECT ||
           i==BTN_X_RECT ||
           i==BTN_B_RECT ||
           i==BTN_A_Y_RECT ||
           i==BTN_B_X_RECT ||
           i==BTN_B_Y_RECT ||
           i==BTN_X_A_RECT ||
           i==BTN_L1_RECT ||
           i==BTN_R1_RECT
           ){
        
              rInput[i].size.height *= g_buttons_size;
              rInput[i].size.width *= g_buttons_size;
        }
    }
    
    for(i=0;i<NUM_BUTTONS;i++)
    {
        if(i==BTN_A || i==BTN_B || i==BTN_X || i==BTN_Y || i==BTN_R1 || i==BTN_L1)
        {
           rButtonImages[i].size.height *= g_buttons_size;
           rButtonImages[i].size.width *= g_buttons_size;
        }
    }
    
    if((!g_device_is_landscape && g_pref_full_screen_port) || (g_device_is_landscape && g_pref_full_screen_land))
    {
       rStickWindow.size.height *= g_stick_size;
       rStickWindow.size.width *= g_stick_size;
    }
}

#pragma mark - MFI Controller

-(float) getDeadZone {
    float deadZone = 0;
    
    switch(g_pref_analog_DZ_value)
    {
        case 0:
            deadZone = 0.01f;
            break;
        case 1:
            deadZone = 0.05f;
            break;
        case 2:
            deadZone = 0.1f;
            break;
        case 3:
            deadZone = 0.15f;
            break;
        case 4:
            deadZone = 0.2f;
            break;
        case 5:
            deadZone = 0.3f;
            break;
    }
    
    return deadZone;
}

-(void)setupMFIControllers{
    
    g_joy_used = 1;
    myosd_num_of_joys = 8;
    [self removeTouchControllerViews];
    [self.view setNeedsDisplay];
    
    for (int index = 0; index < controllers.count; index++) {

        GCController *MFIController = [controllers objectAtIndex:index];
        
        [MFIController setPlayerIndex:GCControllerPlayerIndexUnset];
        [MFIController setPlayerIndex:index];
        
        NSLog(@" PlayerIndex: %li", (long)MFIController.playerIndex);
        
        MFIController.gamepad.dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            if (directionpad.up.pressed) {
                myosd_joy_status[index] |= MYOSD_UP;
            }
            else {
                myosd_joy_status[index] &= ~MYOSD_UP;
            }
            if (directionpad.down.pressed) {
                myosd_joy_status[index] |= MYOSD_DOWN;
            }
            else {
                myosd_joy_status[index] &= ~MYOSD_DOWN;
            }
            if (directionpad.left.pressed) {
                myosd_joy_status[index] |= MYOSD_LEFT;
            }
            else {
                myosd_joy_status[index] &= ~MYOSD_LEFT;
            }
            if (directionpad.right.pressed) {
                myosd_joy_status[index] |= MYOSD_RIGHT;
            }
            else {
                myosd_joy_status[index] &= ~MYOSD_RIGHT;
            }
        };
        
        MFIController.extendedGamepad.dpad.valueChangedHandler = MFIController.gamepad.dpad.valueChangedHandler;
        
        MFIController.gamepad.valueChangedHandler = ^(GCGamepad* gamepad, GCControllerElement* element) {
            
            if (element == gamepad.buttonA) {
                if (gamepad.buttonA.pressed) {
                    myosd_joy_status[index] |= MYOSD_B;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_B;
                }
            }
            if (element == gamepad.buttonB) {
                if (gamepad.buttonB.pressed) {
                    myosd_joy_status[index] |= MYOSD_X;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_X;
                }
            }
            if (element == gamepad.buttonX) {
                if (gamepad.buttonX.pressed) {
                    myosd_joy_status[index] |= MYOSD_A;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_A;
                }
            }
            if (element == gamepad.buttonY) {
                if (gamepad.buttonY.pressed) {
                    myosd_joy_status[index] |= MYOSD_Y;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_Y;
                }
            }
            if (element == gamepad.leftShoulder) {
                if (gamepad.leftShoulder.pressed) {
                    myosd_joy_status[index] |= MYOSD_L1;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_L1;
                }
            }
            if (element == gamepad.rightShoulder) {
                if (gamepad.rightShoulder.pressed) {
                    myosd_joy_status[index] |= MYOSD_R1;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_R1;
                }
            }
        };
        
        MFIController.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
            
            if (element == gamepad.buttonA) {
                if (gamepad.buttonA.pressed) {
                    myosd_joy_status[index] |= MYOSD_B;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_B;
                }
            }
            if (element == gamepad.buttonB) {
                if (gamepad.buttonB.pressed) {
                    myosd_joy_status[index] |= MYOSD_X;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_X;
                }
            }
            if (element == gamepad.buttonX) {
                if (gamepad.buttonX.pressed) {
                    myosd_joy_status[index] |= MYOSD_A;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_A;
                }
            }
            if (element == gamepad.buttonY) {
                if (gamepad.buttonY.pressed) {
                    myosd_joy_status[index] |= MYOSD_Y;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_Y;
                }
            }
            if (element == gamepad.leftShoulder) {
                if (gamepad.leftShoulder.pressed) {
                    myosd_joy_status[index] |= MYOSD_L1;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_L1;
                }
            }
            if (element == gamepad.rightShoulder) {
                if (gamepad.rightShoulder.pressed) {
                    myosd_joy_status[index] |= MYOSD_R1;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_R1;
                }
            }
            
            if (element == gamepad.leftTrigger) {
                joy_analog_x[index][2] = gamepad.leftTrigger.value;
            }
            if (element == gamepad.rightTrigger) {
                joy_analog_x[index][3] = gamepad.rightTrigger.value;
            }
        };
        
        MFIController.extendedGamepad.leftThumbstick.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            float deadZone = [self getDeadZone];
            
            
            if (xValue < -deadZone)
            {
                joy_analog_x[index][0] = xValue;
            }
            if (xValue > deadZone)
            {
                joy_analog_x[index][0] = xValue;
            }
            if ( xValue <= deadZone && xValue >= -deadZone ) {
                joy_analog_x[index][0] = 0.0f;
            }
            if (yValue > deadZone)
            {
                joy_analog_y[index][0] = yValue;
            }
            if (yValue < -deadZone)
            {
                joy_analog_y[index][0] = yValue;
            }
            if ( yValue <= deadZone && yValue >= -deadZone ) {
                joy_analog_y[index][0] = 0.0f;
            }
            
        };
        
        MFIController.extendedGamepad.rightThumbstick.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            float deadZone = [self getDeadZone];
            
            
            if (xValue < -deadZone)
            {
                joy_analog_x[index][1] = xValue;
            }
            if (xValue > deadZone)
            {
                joy_analog_x[index][1] = xValue;
            }
            if ( xValue <= deadZone && xValue >= -deadZone ) {
                joy_analog_x[index][1] = 0.0f;
            }
            if (yValue > deadZone)
            {
                joy_analog_y[index][1] = yValue;
            }
            if (yValue < -deadZone)
            {
                joy_analog_y[index][1] = yValue;
            }
            if ( yValue <= deadZone && yValue >= -deadZone ) {
                joy_analog_y[index][1] = 0.0f;
            }
            
        };
        
        MFIController.controllerPausedHandler = ^(GCController *controller) {
            //Add Coin
            myosd_joy_status[index] |= MYOSD_START;
            [self performSelector:@selector(releaseStart:) withObject:[NSNumber numberWithInteger:MFIController.playerIndex] afterDelay:0.1];
            
            if (MFIController.gamepad.leftShoulder.pressed) {
                myosd_joy_status[index] &= ~MYOSD_START;
                myosd_joy_status[index] &= ~MYOSD_L1;
                myosd_joy_status[index] |= MYOSD_SELECT;
                [self performSelector:@selector(releaseCoin:) withObject:[NSNumber numberWithInteger:MFIController.playerIndex] afterDelay:0.1];
            }
            //Show Mame menu (Start + Coin)
            if (MFIController.gamepad.rightShoulder.pressed) {
                myosd_joy_status[index] &= ~MYOSD_R1;
                myosd_joy_status[index] &= ~MYOSD_START;
                myosd_joy_status[index] |= MYOSD_SELECT;
                myosd_joy_status[index] |= MYOSD_START;
                [self performSelector:@selector(releaseMenu:) withObject:MFIController afterDelay:0.1];
            }
            //Exit Game
            else if (MFIController.gamepad.buttonX.pressed) {
                if (myosd_inGame && myosd_in_menu == 0) {
                    myosd_joy_status[index] &= ~MYOSD_START;
                    myosd_joy_status[index] &= ~MYOSD_X;
                    exit_status=2;
                    actionPending=0;
                    [self handle_MENU];
                }
            }
            // Show Action Sheet Menu
            else if ( MFIController.gamepad.buttonY.pressed) {
                if (myosd_inGame && myosd_in_menu == 0) {
                    myosd_joy_status[index] &= ~MYOSD_START;
                    myosd_joy_status[index] &= ~MYOSD_Y;
                    [self runMenu];
                }
            }
        };
    }
    
}

-(void)releaseMenu:(GCController *)controller{
    myosd_joy_status[controller.playerIndex] &= ~MYOSD_START;
    myosd_joy_status[controller.playerIndex] &= ~MYOSD_SELECT;
    
}

-(void)releaseCoin:(NSNumber*)playerIndex {
    myosd_joy_status[playerIndex.integerValue] &= ~MYOSD_SELECT;
    myosd_pad_status &= ~MYOSD_SELECT;
}

-(void)releaseStart:(NSNumber *)playerIndex {
    myosd_joy_status[playerIndex.integerValue] &= ~MYOSD_START;
    myosd_pad_status &= ~MYOSD_START;
}

-(void)scanForDevices{
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
}

-(void)MFIControllerConnected:(NSNotification*)notif{
    GCController *controller = (GCController *)[notif object];
    
    NSLog(@"Hello %@", controller.vendorName);
    
    [controller setPlayerIndex:GCControllerPlayerIndexUnset];
    
    [controllers addObject:controller];
    [self setupMFIControllers];
}

-(void)MFIControllerDisconnected:(NSNotification*)notif{
    GCController *controller = (GCController *)[notif object];
    
    NSLog(@"Goodbye %@", controller.vendorName);
    
    [controllers removeObject:controller];
    
    if(!controllers.count){
        g_joy_used = 0;
        myosd_num_of_joys = 0;
        
        [self changeUI];
    }
    else {
        [self setupMFIControllers];
    }
}

@end
