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
#import <GameController/GameController.h>
#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_IOS
#import <Intents/Intents.h>
#import "HelpController.h"
#import "OptionsController.h"
#import "AnalogStick.h"
#import "AnalogStick.h"
#import "LayoutView.h"
#import "LayoutData.h"
#import "NetplayGameKit.h"
#endif

#import "ChooseGameController.h"

#if TARGET_OS_TV
#import "TVOptionsController.h"
#endif

#import "iCadeView.h"
#import "DebugView.h"
#ifdef BTJOY
#import "BTJoyHelper.h"
#endif
#import <pthread.h>
#import "UIView+Toast.h"
#import "DeviceScreenResolver.h"
#import "Bootstrapper.h"
#import "Options.h"
#import "WebServer.h"
#import "Alert.h"
#import "ZipFile.h"
#import "SystemImage.h"

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

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

int g_enable_debug_view = 0;
int g_controller_opacity = 50;

int g_device_is_landscape = 0;
int g_device_is_fullscreen = 0;

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
int g_pref_full_screen_land_joy = 1;
int g_pref_full_screen_port_joy = 1;

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

static int old_myosd_num_buttons = 0;
static int button_auto = 0;
static int ways_auto = 0;
#if TARGET_OS_IOS
static int change_layout=0;
#endif

#define kSelectedGameKey @"selected_game"
static char g_mame_game[MAX_GAME_NAME];     // game MAME should run (or empty is menu)
static char g_mame_game_error[MAX_GAME_NAME];
static BOOL g_no_roms_found = FALSE;

static EmulatorController *sharedInstance = nil;

static NSUInteger buttonPressReleaseCycles = 2;

void iphone_Reset_Views(void)
{
   if(sharedInstance==nil) return;
#ifndef JAILBREAK
   if(!myosd_inGame)
      [sharedInstance performSelectorOnMainThread:@selector(moveROMS) withObject:nil waitUntilDone:NO];
#endif
   [sharedInstance performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];  
}

// run MAME (or pass NULL for main menu)
int run_mame(char* game)
{
    char* argv[] = {"mame4ios", game};
    return iOS_main((game && *game) ? 2 : 1,argv);
}

void* app_Thread_Start(void* args)
{
    g_emulation_initiated = 1;
    
    while (1) {
        prev_myosd_mouse = myosd_mouse = 0;
        prev_myosd_light_gun = myosd_light_gun = 0;
        
        if (run_mame(g_mame_game) != 0 && g_mame_game[0]) {
            strncpy(g_mame_game_error, g_mame_game, sizeof(g_mame_game_error));
            g_mame_game[0] = 0;
        }
    }
}

// find the category for a game/rom using Category.ini (a copy of a similar function from uimenu.c)
NSString* find_category(NSString* name)
{
    static NSDictionary* g_category_dict = nil;
    
    if (g_category_dict == nil)
    {
        g_category_dict = [[NSMutableDictionary alloc] init];
        FILE* file = fopen(get_documents_path("Category.ini"), "r");
        if (file != NULL)
        {
            char line[256];
            NSString* curcat = @"";

            while (fgets(line, sizeof(line), file) != NULL)
            {
                if (line[strlen(line) - 1] == '\n') line[strlen(line) - 1] = '\0';
                if (line[strlen(line) - 1] == '\r') line[strlen(line) - 1] = '\0';
                
                if (line[0] == '\0')
                    continue;
                
                if (line[0] == '[')
                {
                    line[strlen(line) - 1] = '\0';
                    curcat = [NSString stringWithUTF8String:line+1];
                    continue;
                }
                
                [(NSMutableDictionary*)g_category_dict setObject:curcat forKey:[NSString stringWithUTF8String:line]];
            }
            fclose(file);
        }
    }
    return g_category_dict[name] ?: @"Unkown";
}

// called from deep inside MAME select_game menu, to give us the valid list of games/drivers
void myosd_set_game_info(myosd_game_info* game_info[], int game_count)
{
    @autoreleasepool {
        NSMutableArray* games = [[NSMutableArray alloc] init];
        
        for (int i=0; i<game_count; i++)
        {
            if (game_info[i] == NULL)
                continue;
            [games addObject:@{
                kGameInfoParent:      [NSString stringWithUTF8String:game_info[i]->parent ?: ""],
                kGameInfoName:        [NSString stringWithUTF8String:game_info[i]->name],
                kGameInfoDescription: [NSString stringWithUTF8String:game_info[i]->description],
                kGameInfoYear:        [NSString stringWithUTF8String:game_info[i]->year],
                kGameInfoManufacturer:[NSString stringWithUTF8String:game_info[i]->manufacturer],
                kGameInfoCategory:    find_category([NSString stringWithUTF8String:game_info[i]->name]),
            }];
        }
        
        [sharedInstance performSelectorOnMainThread:@selector(chooseGame:) withObject:games waitUntilDone:FALSE];
    }
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
    CGSize  layoutSize;
#if TARGET_OS_IOS
    OptionsController *optionsController;
#elif TARGET_OS_TV
    TVOptionsController *optionsController;
#endif
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

#if TARGET_OS_IOS
- (CGRect *)getInputRects{
    return rInput;
}

- (CGRect *)getButtonRects{
    return rButtonImages;
}

- (UIView *)getButtonView:(int)i {
    return buttonViews[i];
}
- (UIView *)getDPADView{
    return dpadView;
}

- (UIView *)getStickView{
    return analogStickView;
}

#endif

- (void)startEmulation {
    NSParameterAssert(g_emulation_initiated == 0);
    
    sharedInstance = self;
    
    NSDictionary* game = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSelectedGameKey];
    NSString* name = game[kGameInfoName] ?: @"";
    if ([name isEqualToString:kGameInfoNameMameMenu])
        name = @" ";
    strncpy(g_mame_game, [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(g_mame_game));
    g_mame_game_error[0] = 0;
	     		    				
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
    
#if TARGET_OS_IOS
    _impactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    _selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
#endif
}

- (void)startMenu
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    g_emulation_paused = 1;
    change_pause(1);
}

- (void)runLoadSaveState:(BOOL)load
{
    if (self.presentedViewController) {
        NSLog(@"runLoadSaveState: BUSY!");
        return;
    }
    
    NSString* message = [NSString stringWithFormat:@"Select State to %@", load ? @"Load" : @"Save"];
    
#if TARGET_OS_TV
    NSString* state1 = @"State 1";
    NSString* state2 = @"State 2";
#else
    NSString* state1 = controllers.count > 0 ? @"Ⓐ State A" : @"State 1";
    NSString* state2 = controllers.count > 0 ? @"Ⓑ State B" : @"State 2";
#endif
    
    [self showAlertWithTitle:nil message:message buttons:@[state1, state2] handler:^(NSUInteger button) {
        if (load)
            myosd_loadstate = 1;
        else
            myosd_savestate = 1;

        if (button == 0)
            push_mame_buttons(0, MYOSD_NONE, MYOSD_B);       // delay, slot 1
        else
            push_mame_buttons(0, MYOSD_NONE, MYOSD_X);       // delay, slot 2
        
        [self endMenu];
    }];
}
- (void)runLoadState
{
    [self runLoadSaveState:TRUE];
}
- (void)runSaveState
{
    [self runLoadSaveState:FALSE];
}

- (void)runMenu:(int)player
{
    if (self.presentedViewController != nil)
        return;
    
    [self startMenu];

    int enable_menu_exit_option = myosd_inGame && myosd_in_menu==0;
    
    menu = [UIAlertController alertControllerWithTitle:@"MAME4iOS" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    CGFloat size = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 1.5;

    if(myosd_inGame)
    {
        // MENU item to insert a coin and do a start. usefull for fullscreen and AppleTV siri remote, and discoverability on a GameController
        [menu addAction:[UIAlertAction actionWithTitle:@"Coin+Start" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"centsign.circle" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
            push_mame_buttons(player, MYOSD_SELECT, MYOSD_SELECT); // some games need 2 credits to play, so enter two coins
            push_mame_button(player, MYOSD_START);
            [self endMenu];
        }]];
        [menu addAction:[UIAlertAction actionWithTitle:@"Load State" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"bookmark.fill" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
            [self runLoadState];
        }]];
        [menu addAction:[UIAlertAction actionWithTitle:@"Save State" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"bookmark" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
            [self runSaveState];
        }]];
        [menu addAction:[UIAlertAction actionWithTitle:@"MAME Menu" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"slider.horizontal.3" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
            push_mame_button(0, (MYOSD_SELECT|MYOSD_START));
            [self endMenu];
        }]];
    }
    [menu addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"gear" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
        [self runSettings];
    }]];

    /* Start Server is in Settings (no need for it to be on the in-game menu)
    [menu addAction:[UIAlertAction actionWithTitle:@"Upload Files" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
        [[WebServer sharedInstance] startUploader];
        [WebServer sharedInstance].webUploader.delegate = self;
        [self endMenu];
    }]];
    */

    if(enable_menu_exit_option) {
        [menu addAction:[UIAlertAction actionWithTitle:@"Exit Game" style:UIAlertActionStyleDestructive image:[UIImage systemImageNamed:@"arrow.uturn.left.circle" withPointSize:size] handler:^(UIAlertAction * _Nonnull action) {
            //[self runExit];   -- the user just selected "Exit Game" from a menu, dont ask again
            if (g_mame_game[0] != ' ')
                g_mame_game[0] = 0;
            myosd_exitGame = 1;
            [self endMenu];
        }]];
    }
    
    [menu addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self endMenu];
    }]];
#if TARGET_OS_IOS // UIPopoverPresentationController does not exist on tvOS.
    UIPopoverPresentationController *popoverController = menu.popoverPresentationController;
    if ( popoverController != nil ) {
        popoverController.sourceView = self.view;
        popoverController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);
        popoverController.permittedArrowDirections = 0;
    }
#endif
    [self presentViewController:menu animated:YES completion:nil];
}
- (void)runMenu
{
    [self runMenu:0];
}

- (void)runExit
{
    if (self.presentedViewController != nil)
        return;

    if (myosd_inGame && myosd_in_menu == 0)
    {
        [self startMenu];
        
#if TARGET_OS_TV
        NSString* yes = @"Yes";
        NSString* no  = @"No";
#else
        NSString* yes = controllers.count > 0 ? @"Ⓐ Yes" : @"Yes";
        NSString* no  = controllers.count > 0 ? @"Ⓑ No" : @"No";
#endif
        UIAlertController *exitAlertController = [UIAlertController alertControllerWithTitle:@"" message:@"Are you sure you want to exit the game?" preferredStyle:UIAlertControllerStyleAlert];
        [exitAlertController addAction:[UIAlertAction actionWithTitle:yes style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self endMenu];
            if (g_mame_game[0] != ' ')
                g_mame_game[0] = 0;
            myosd_exitGame = 1;
        }]];
        [exitAlertController addAction:[UIAlertAction actionWithTitle:no style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self endMenu];
        }]];
        exitAlertController.preferredAction = exitAlertController.actions.firstObject;
        [self presentViewController:exitAlertController animated:YES completion:nil];
    }
    else if (myosd_inGame && myosd_in_menu != 0)
    {
        myosd_exitGame = 1;
    }
    else
    {
        g_mame_game[0] = 0;
        myosd_exitGame = 1;
    }
}

- (void)runPause
{
    if (self.presentedViewController != nil || g_emulation_paused)
        return;

    [self startMenu];
    [self showAlertWithTitle:@"MAME4iOS" message:@"Game is PAUSED" buttons:@[@"Continue"] handler:^(NSUInteger button) {
        [self endMenu];
    }];
}

- (void)runSettings {

    [self startMenu];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:optionsController];
#if TARGET_OS_IOS
    [navController setModalPresentationStyle:UIModalPresentationPageSheet];
#endif
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        navController.modalInPresentation = YES;    // disable iOS 13 swipe to dismiss...
    }
    [(self.presentedViewController ?: self) presentViewController:navController animated:YES completion:nil];
}

- (void)endMenu{
    int old_joy_used = g_joy_used;
    g_joy_used = myosd_num_of_joys!=0;
    
    if (old_joy_used != g_joy_used)
        [self changeUI];
    
    myosd_exitPause = 1;
    g_emulation_paused = 0;
    change_pause(0);
    
    // always enable iCadeView so we can get input from a Hardware keyboard.
    icadeView.active = TRUE; //force renable
    
    [UIApplication sharedApplication].idleTimerDisabled = (myosd_inGame || g_joy_used) ? YES : NO;//so atract mode dont sleep
}

-(void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSLog(@"PRESENT VIEWCONTROLLER: %@", viewControllerToPresent);

#if TARGET_OS_TV
    self.controllerUserInteractionEnabled = YES;
#endif
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}
-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    NSLog(@"DISMISS VIEWCONTROLLER: %@", [self presentedViewController]);
#if TARGET_OS_TV
    self.controllerUserInteractionEnabled = NO;
#endif
    [super dismissViewControllerAnimated:flag completion:completion];
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
    myosd_showinfo =  [op showINFO];
    g_pref_animated_DPad  = [op animatedButtons];
    g_pref_full_screen_land  = [op fullLand];
    g_pref_full_screen_port  = [op fullPort];
    g_pref_full_screen_land_joy = [op fullLandJoy];
    g_pref_full_screen_port_joy = [op fullPortJoy];

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
    
    g_pref_input_touch_type = [op touchtype];
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
    myosd_filter_not_working = op.filterNotWorking;
    
    global_low_latency_sound = [op lowlsound];
    if(myosd_video_threaded==-1)
    {
        myosd_video_threaded = [op threaded];
        main_thread_priority =  MAX(1,[op mainPriority] * 10);
        video_thread_priority = MAX(1,[op videoPriority] * 10);
        myosd_dbl_buffer = [op dblbuff];
        main_thread_priority_type = [op mainThreadType]+1;
        main_thread_priority_type = [op videoThreadType]+1;
        NSLog(@"thread Type %d %d\n",main_thread_priority_type,main_thread_priority_type);
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
    
    turboBtnEnabled[BTN_X] = [op turboXEnabled];
    turboBtnEnabled[BTN_Y] = [op turboYEnabled];
    turboBtnEnabled[BTN_A] = [op turboAEnabled];
    turboBtnEnabled[BTN_B] = [op turboBEnabled];
    turboBtnEnabled[BTN_L1] = [op turboLEnabled];
    turboBtnEnabled[BTN_R1] = [op turboREnabled];
    
#if TARGET_OS_IOS
    g_pref_lightgun_enabled = [op lightgunEnabled];
    g_pref_lightgun_bottom_reload = [op lightgunBottomScreenReload];
    
    g_pref_touch_analog_enabled = [op touchAnalogEnabled];
    g_pref_touch_analog_hide_dpad = [op touchAnalogHideTouchDirectionalPad];
    g_pref_touch_analog_hide_buttons = [op touchAnalogHideTouchButtons];
    g_pref_touch_analog_sensitivity = [op touchAnalogSensitivity];
    g_controller_opacity = [op touchControlsOpacity];
    
    g_pref_touch_directional_enabled = [op touchDirectionalEnabled];
#else
    g_pref_lightgun_enabled = NO;
    g_pref_touch_analog_enabled = NO;
    g_pref_touch_directional_enabled = NO;
#endif
}

// DONE button on Settings dialog
-(void)done:(id)sender {
    
	Options *op = [[Options alloc] init];
    
#if TARGET_OS_IOS
    if(g_pref_overscanTVOUT != [op overscanValue])
    {
        [self showAlertWithTitle:@"Pending unplug/plug TVOUT!" message:@"You need to unplug/plug TVOUT for the changes to take effect" buttons:@[@"Dismiss"] handler:^(NSUInteger button) {
            g_pref_overscanTVOUT = [op overscanValue];
            [self done:self];
        }];
        return;
    }
#endif
    
    // have the parent of the options/setting dialog dismiss
    // we present settings two ways, from in-game menu (we are parent) and from ChooseGameUI (it is the parent)
    UIViewController* parent = optionsController.navigationController.presentingViewController;
    [(parent ?: self) dismissViewControllerAnimated:YES completion:^{
        if(global_low_latency_sound != [op lowlsound])
        {
            if(myosd_sound_value!=-1)
            {
               myosd_closeSound();
               global_low_latency_sound = [op lowlsound];
               myosd_openSound(myosd_sound_value, 1);
            }
        }
        
        // if we are at the root menu, exit and restart.
        if (myosd_inGame == 0)
            myosd_exitGame = 1;

        [self updateOptions];
        
        [self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
        
        // dont call endMenu (and unpause MAME) if we still have a dialog up.
        if (self.presentedViewController == nil)
            [self endMenu];
    }];
}


// handle_MENU - called when a possible menu key is pressed on a controller, keyboard, or screen
- (void)handle_MENU
{
#if TARGET_OS_IOS   // NOT needed on tvOS it handles it with the focus engine
    UIViewController* viewController = [self presentedViewController];
    
    if ([viewController isKindOfClass:[UINavigationController class]])
        viewController = [(UINavigationController*)viewController topViewController];

    // if we are showing an alert map controller input to the alert
    if ([viewController isKindOfClass:[UIAlertController class]])
    {
        UIAlertController* alert = (UIAlertController*)viewController;

        unsigned long pad_status = myosd_pad_status | myosd_joy_status[0] | myosd_joy_status[1];

        if (pad_status & MYOSD_A)
            [alert dismissWithDefault];
        if (pad_status & MYOSD_B)
            [alert dismissWithCancel];
        if ((pad_status & MYOSD_UP))
            [alert moveDefaultAction:-1];
        if ((pad_status & MYOSD_DOWN))
            [alert moveDefaultAction:+1];
        return;
    }
    
    // if we are showing some other UI, give it a chance to handle input.
    if ([viewController respondsToSelector:@selector(handle_MENU)])
        [viewController performSelector:@selector(handle_MENU)];
    
    // if we are showing something else, just ignore.
    if (viewController != nil)
        return;
        
    // handle the onscreen buttons....
    if(old_btnStates[BTN_L2] == BUTTON_PRESS && btnStates[BTN_L2] != BUTTON_PRESS)
    {
        [self runExit];
    }
    
    if(old_btnStates[BTN_R2] == BUTTON_PRESS && btnStates[BTN_R2] != BUTTON_PRESS)
    {
        [self runMenu];
    }
#endif
}

- (void)loadView {

	struct CGRect rect = [[UIScreen mainScreen] bounds];
	rect.origin.x = rect.origin.y = 0.0f;
	UIView *view= [[UIView alloc] initWithFrame:rect];
	self.view = view;
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
#if TARGET_OS_IOS
   analogStickView = nil;
   dview = nil;
#endif
   int i;
   for(i=0; i<NUM_BUTTONS;i++)
      buttonViews[i]=nil;
      
   screenView=nil;
   imageBack=nil;   			
   
   menu = nil;

   [self getConf];

	//[self.view addSubview:self.imageBack];
 	
	//[ self getControllerCoords:0 ];
	
	//self.navigationItem.hidesBackButton = YES;
	
	
    self.view.opaque = YES;
	self.view.clearsContextBeforeDrawing = NO; //Performance?
	
	self.view.userInteractionEnabled = YES;

#if TARGET_OS_IOS
	self.view.multipleTouchEnabled = YES;
	self.view.exclusiveTouch = NO;
#endif
	
    //self.view.multipleTouchEnabled = NO; investigar porque se queda
	//self.view.contentMode = UIViewContentModeTopLeft;
	
	//[[self.view layer] setMagnificationFilter:kCAFilterNearest];
	//[[self.view layer] setMinificationFilter:kCAFilterNearest];

	//kito
	[NSThread setThreadPriority:1.0];
	
	//self.view.frame = [[UIScreen mainScreen] bounds];//rMainViewFrame;
		
    [self updateOptions];

#if TARGET_OS_IOS
    // Button to hide/show onscreen controls for lightgun games
    // Also functions as a show menu button when a game controller is used
    hideShowControlsForLightgun = [[UIButton alloc] initWithFrame:CGRectZero];
    hideShowControlsForLightgun.hidden = YES;
    [hideShowControlsForLightgun.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"dpad"] forState:UIControlStateNormal];
    [hideShowControlsForLightgun addTarget:self action:@selector(toggleControlsForLightgunButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    hideShowControlsForLightgun.alpha = 0.2f;
    hideShowControlsForLightgun.translatesAutoresizingMaskIntoConstraints = NO;
    [hideShowControlsForLightgun addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 30.0f : 20.0f]];
    [hideShowControlsForLightgun addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 30.0f :20.0f]];
    [self.view addSubview:hideShowControlsForLightgun];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:hideShowControlsForLightgun attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTopMargin multiplier:1.0f constant:8.0f]];
    areControlsHidden = NO;
#endif
    
    [self changeUI];
    
    icadeView = [[iCadeView alloc] initWithFrame:CGRectZero withEmuController:self];
    [self.view addSubview:icadeView];

    // always enable iCadeView for hardware keyboard support
    icadeView.active = YES;
    
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
    toastStyle.backgroundColor = [UIColor colorWithWhite:0.333 alpha:0.50];
    toastStyle.messageColor = [UIColor whiteColor];
    
    mouseInitialLocation = CGPointMake(9111, 9111);
    mouseTouchStartLocation = mouseInitialLocation;

#if TARGET_OS_IOS
    optionsController =[[OptionsController alloc] init];
    optionsController.emuController = self;
#elif TARGET_OS_TV
    optionsController = [[TVOptionsController alloc] init];
    optionsController.emuController = self;
#endif
    [self updateUserActivity];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#if TARGET_OS_IOS
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeBottom;
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
-(BOOL)prefersHomeIndicatorAutoHidden
{
    return g_device_is_landscape ? YES : NO;
}

- (BOOL)shouldAutorotate {
    return change_layout ? NO : YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (!CGSizeEqualToSize(layoutSize, self.view.bounds.size)) {
        layoutSize = self.view.bounds.size;
        [self changeUI];
    }
}

#endif

- (void)drawRect:(CGRect)rect
{
}

#if TARGET_OS_IOS
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
#endif

// hide or show the screen view
// called from changeUI, and changeUI is called from iphone_Reset_Views() each time a new game (or menu) is started.
- (void)updateScreenView {
    CGFloat alpha;
    if (myosd_inGame || g_mame_game[0])
        alpha = 1.0;
    else
        alpha = 0.0;
    
    if (screenView.alpha != alpha) {
        screenView.alpha = alpha;
        imageOverlay.alpha = alpha;
        if (alpha == 0.0)
            NSLog(@"**** HIDING ScreenView ****");
        else
            NSLog(@"**** SHOWING ScreenView ****");
    }
}

- (void)changeUI { @autoreleasepool {

  int prev_emulation_paused = g_emulation_paused;
   
  g_emulation_paused = 1;
  change_pause(1);
  
  [self getConf];
    
  //printf("%d %d %d\n",ways_auto,myosd_num_ways,myosd_waysStick);
    
  if((ways_auto && myosd_num_ways!=myosd_waysStick) || (button_auto && old_myosd_num_buttons != myosd_num_buttons))
  {
     [self updateOptions];
  }
    
  /* -- TODO figure out why we are doing this.  is it only needed at start up? if so only do it then.
     -- we call changeUI when ever we need to update anything, and this delay causes a glitch.
   
     -- for example when we hit a key on the HW keyboard or iCade for the first time chageUI gets called to possibly hide the onscreen controls, this delay causes MAME to miss the key press
   
     -- another example, we call this when the device is rotated, a delay on the main thread is (almost) always a bad idea....
  usleep(150000);//ensure some frames displayed
  */
    
  if(screenView != nil)
  {
     [screenView removeFromSuperview];
     screenView = nil;
  }

  if(imageBack!=nil)
  {
     [imageBack removeFromSuperview];
     imageBack = nil;
  }
   
  //si tiene overlay
   if(imageOverlay!=nil)
   {
     [imageOverlay removeFromSuperview];
     imageOverlay = nil;
   }
    
#if TARGET_OS_IOS
    // Support iCade in external screens
    if ( externalView != nil && icadeView != nil && ![externalView.subviews containsObject:icadeView] ) {
        [externalView addSubview:icadeView];
    }
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    [[UIApplication sharedApplication] setStatusBarOrientation:self.interfaceOrientation];
#endif
    
    if (self.view.bounds.size.width > self.view.bounds.size.height)
        [self buildLandscape];
    else
        [self buildPortrait];

   if (@available(iOS 11.0, *))
       [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
#elif TARGET_OS_TV
    // for tvOS, use "landscape" only
    [self buildLandscape];
#endif
    [self updateScreenView];
    
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
    prev_myosd_mouse = myosd_mouse;

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

}}

#define MAME_BUTTON_PLAYER_MASK     0xF0000000
#define MAME_BUTTON_PLAYER_SHIFT    28
#define MAME_BUTTON_SENT            0xFFFFFFFF
#define MAME_BUTTONS                4
static unsigned long g_mame_buttons[MAME_BUTTONS];

static void push_mame_button(int player, int button)
{
    button = button | (player << MAME_BUTTON_PLAYER_SHIFT);
    
    for (int i=0; i<MAME_BUTTONS; i++)
    {
        if (g_mame_buttons[i] == 0) {
            g_mame_buttons[i] = button;
            break;
        }
    }
}

static void push_mame_buttons(int player, int button1, int button2)
{
    push_mame_button(player, button1);
    push_mame_button(player, button2);
}

// called from inside MAME droid_ios_poll_input
void myosd_handle_turbo() {
    if ( !myosd_inGame ) {
        return;
    }
    // this is called on the MAME thread, need to be carefull and clean up!
    @autoreleasepool {
        
        // send keys - we do this inside of myosd_handle_turbo() because it is called from droid_ios_poll_input
        // ...and we are sure MAME is in a state to accept input, and not waking up from being paused or loading a ROM
        if (g_mame_buttons[0] != 0 && g_mame_buttons[0] != MAME_BUTTON_SENT) {
            unsigned long button = g_mame_buttons[0] & ~MAME_BUTTON_PLAYER_MASK;
            unsigned long player = (g_mame_buttons[0] & MAME_BUTTON_PLAYER_MASK) >> MAME_BUTTON_PLAYER_SHIFT;
            g_mame_buttons[0] = MAME_BUTTON_SENT;
            
            myosd_joy_status[player] |= button;
            if (player == 0)
                myosd_pad_status |= button;

            NSTimeInterval hold_delay = 0.250;
            NSTimeInterval next_delay = 0.250;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(hold_delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                myosd_joy_status[player] &= ~button;
                if (player == 0)
                    myosd_pad_status &= ~button;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(next_delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    for (int i=0; i<MAME_BUTTONS-1; i++)
                        g_mame_buttons[i] = g_mame_buttons[i+1];
                    g_mame_buttons[MAME_BUTTONS-1] = 0;
                });
            });
        }
        
        // poll mfi controllers and read state of button presses
        for (int index = 0; index < controllers.count; index++) {
            GCController *mfiController = [controllers objectAtIndex:index];
            GCExtendedGamepad *gamepad = mfiController.extendedGamepad;
            if ( gamepad.buttonX.isPressed ) {
                mfiBtnStates[index][BTN_X] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_X] = BUTTON_NO_PRESS;
            }
            if ( gamepad.buttonY.isPressed ) {
                mfiBtnStates[index][BTN_Y] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_Y] = BUTTON_NO_PRESS;
            }
            if ( gamepad.buttonA.isPressed ) {
                mfiBtnStates[index][BTN_A] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_A] = BUTTON_NO_PRESS;
            }
            if ( gamepad.buttonB.isPressed ) {
                mfiBtnStates[index][BTN_B] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_B] = BUTTON_NO_PRESS;
            }
            if ( gamepad.leftShoulder.isPressed ) {
                mfiBtnStates[index][BTN_L1] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_L1] = BUTTON_NO_PRESS;
            }
            if ( gamepad.rightShoulder.isPressed ) {
                mfiBtnStates[index][BTN_R1] = BUTTON_PRESS;
            } else {
                mfiBtnStates[index][BTN_R1] = BUTTON_NO_PRESS;
            }
        }
     
        static struct {int button, myosdButton;} turboButtons[] = {
            {BTN_X, MYOSD_X}, {BTN_Y, MYOSD_Y},
            {BTN_A, MYOSD_A}, {BTN_B, MYOSD_B},
            {BTN_L1, MYOSD_L1}, {BTN_R1, MYOSD_R1},
        };
        for (int i=0; i<sizeof(turboButtons)/sizeof(turboButtons[0]); i++) {
            
            int button = turboButtons[i].button;
            int myosdButton = turboButtons[i].button;
            
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
}

- (void)removeTouchControllerViews{
#if TARGET_OS_TV
    return;
#else
   int i;
   
   if(dpadView!=nil)
   {
      [dpadView removeFromSuperview];
      dpadView=nil;
   }
   
   if(analogStickView!=nil)
   {
      [analogStickView removeFromSuperview];
      analogStickView=nil;   
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {
      if(buttonViews[i]!=nil)
      {
         [buttonViews[i] removeFromSuperview];
         buttonViews[i] = nil; 
      }
   }
#endif
}

- (void)buildTouchControllerViews {
#if TARGET_OS_TV
    return;
#else
   int i;
   
   
   [self removeTouchControllerViews];
    
   g_joy_used = myosd_num_of_joys!=0; 
   
   if (g_joy_used && g_device_is_fullscreen)
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
            if (g_device_is_fullscreen)
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
        if(!change_layout && (g_device_is_landscape || g_device_is_fullscreen))
        {
            if(i==BTN_X && (g_pref_full_num_buttons < 4 && myosd_inGame))continue;
            if(i==BTN_Y && (g_pref_full_num_buttons < 3 || !myosd_inGame))continue;
            if(i==BTN_B && (g_pref_full_num_buttons < 2 || !myosd_inGame))continue;
            if(i==BTN_A && (g_pref_full_num_buttons < 1 && myosd_inGame))continue;
            
            if(i==BTN_L1 && (g_pref_hide_LR || !myosd_inGame))continue;
            if(i==BTN_R1 && (g_pref_hide_LR || !myosd_inGame))continue;
            
            if (touch_buttons_disabled && (i != BTN_SELECT && i != BTN_START && i != BTN_L2 && i != BTN_R2 )) continue;
        }
        
        name = [NSString stringWithFormat:@"./SKIN_%d/%@",g_pref_skin,nameImgButton_NotPress[i]];
        buttonViews[i] = [ [ UIImageView alloc ] initWithImage:[self loadImage:name]];
        buttonViews[i].frame = rButtonImages[i];
        
        if (g_device_is_fullscreen)
            [buttonViews[i] setAlpha:((float)g_controller_opacity / 100.0f)];
        
        if (g_device_is_landscape && !g_device_is_fullscreen && g_isIphone5 /*&& skin_data==1*/ && (i==BTN_Y || i==BTN_A || i==BTN_L1 || i==BTN_R1))
            [buttonViews[i] setAlpha:((float)g_controller_opacity / 100.0f)];
        
        [self.view addSubview: buttonViews[i]];
        btnStates[i] = old_btnStates[i] = BUTTON_NO_PRESS;
    }
#endif
}

#if TARGET_OS_IOS
- (void)buildPortraitImageBack {

   if(!g_device_is_fullscreen)
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
       CGRect r = g_device_is_fullscreen ? rScreenView : rFrames[PORTRAIT_IMAGE_OVERLAY];
       
       if (CGRectEqualToRect(rFrames[PORTRAIT_IMAGE_OVERLAY], rFrames[PORTRAIT_VIEW_NOT_FULL]))
           r = screenView.frame;
       
       UIGraphicsBeginImageContextWithOptions(r.size, NO, 0.0);  
       
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
     
       if(g_isIpad && !g_device_is_fullscreen)
       {
          UIImage *image1;
          if(g_isIpad)          
            image1 = [self loadImage:[NSString stringWithFormat:@"border-iPad.png"]];
          else
            image1 = [self loadImage:[NSString stringWithFormat:@"border-iPhone.png"]];
         
          CGImageRef img = CGImageRetain(image1.CGImage);
       
          CGContextSetAlpha(uiContext,((float)100 / 100.0f));  
   
          CGContextDrawImage(uiContext,CGRectMake(0, 0, r.size.width, r.size.height),img);
   
          CGImageRelease(img);  

           //inset the screenView so the border does not overlap it.
           //TODO: the border image is 320x240 so it gets scaled up alot, maybe we need a new hires one.
           if (TRUE && self.view.window.screen != nil) {
               CGSize border = CGSizeMake(8.0,8.0);  // in pixels
               CGFloat scale = self.view.window.screen.scale;
               CGFloat dx = ceil((border.width * r.size.width / image1.size.width) / scale); // in points
               CGFloat dy = ceil((border.height * r.size.height / image1.size.height) / scale);
               screenView.frame = AVMakeRectWithAspectRatioInsideRect(r.size, CGRectInset(r, dx, dy));
           }
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
   g_device_is_fullscreen = g_pref_full_screen_port || (g_joy_used && g_pref_full_screen_port_joy) || externalView != nil;
    
   [ self getControllerCoords:0 ];
    
   [ self adjustSizes];
    
   [LayoutData loadLayoutData:self];
   
   [self buildPortraitImageBack];
   
   CGRect r;
   
   if(externalView!=nil)   
   {
        r = rExternalView;
   }
   else if (!g_device_is_fullscreen)
   {
	    r = rFrames[PORTRAIT_VIEW_NOT_FULL];
   }		  
   else
   {
        r = rFrames[PORTRAIT_VIEW_FULL];
   }
    
    // Handle Safe Area (iPhone X) adjust the view down away from the notch, before adjusting for aspect
    if ( @available(iOS 11, *) ) {
        if ( externalView == nil ) {
            r = CGRectIntersection(r, UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets));
        }
    }
    
    if(g_pref_keep_aspect_ratio_port)
    {
        r = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(myosd_vis_video_width, myosd_vis_video_height), r);
    }
    
   rScreenView = r;
       
   screenView = [ [ScreenView alloc] initWithFrame: rScreenView];
                  
   if(externalView==nil)
   {
       // add at the bottom, so we dont cover any Toast
       [self.view insertSubview:screenView atIndex:0];
   }
   else
   {
       [externalView addSubview: screenView];
   }
      
   [self buildPortraitImageOverlay];

    hideShowControlsForLightgun.hidden = YES;
    if ( g_device_is_fullscreen &&
        (
         (myosd_light_gun && g_pref_lightgun_enabled) ||
         (myosd_mouse && g_pref_touch_analog_enabled)
        )) {
        // make a button to hide/display the controls
        hideShowControlsForLightgun.hidden = NO;
        [self.view bringSubviewToFront:hideShowControlsForLightgun];
    }

}

- (void)buildLandscapeImageBack {

   if (!g_device_is_fullscreen)
   {
	   if(g_isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPad.png",g_pref_skin]]];
       else if(g_isIphone5)
         imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone_5.png",g_pref_skin]]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone_6.png",g_pref_skin]]];
	   
	   imageBack.frame = rFrames[LANDSCAPE_IMAGE_BACK]; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   
}
#endif

- (void)buildLandscapeImageOverlay{
 
   if((g_pref_scanline_filter_land || g_pref_tv_filter_land) &&  externalView==nil)
   {                                                                                                                                              
	   CGRect r;

       if(g_device_is_fullscreen)
          r = rScreenView;
       else
          r = rFrames[LANDSCAPE_IMAGE_OVERLAY];
       
       if (CGRectEqualToRect(rFrames[LANDSCAPE_IMAGE_OVERLAY], rFrames[LANDSCAPE_VIEW_NOT_FULL]))
           r = screenView.frame;
	
	   UIGraphicsBeginImageContextWithOptions(r.size, NO, 0.0);
	
	   CGContextRef uiContext = UIGraphicsGetCurrentContext();  
	   
	   CGContextTranslateCTM(uiContext, 0, r.size.height);
		
	   CGContextScaleCTM(uiContext, 1.0, -1.0);
	   
	   if(g_pref_scanline_filter_land)
	   {       	       
	      UIImage *image2;

#if TARGET_OS_IOS
	      if(g_isIpad)
	        image2 =  [self loadImage:[NSString stringWithFormat: @"scanline-2.png"]];
	      else
	        image2 =  [self loadImage:[NSString stringWithFormat: @"scanline-1.png"]];
#elif TARGET_OS_TV
           image2 =  [self loadImage:[NSString stringWithFormat: @"scanline_tvOS201901.png"]];
#endif
	                        
	      CGImageRef tile = CGImageRetain(image2.CGImage);
	      
#if TARGET_OS_IOS
	      if(g_isIpad)             
	         CGContextSetAlpha(uiContext,((float)10 / 100.0f));
	      else
	         CGContextSetAlpha(uiContext,((float)22 / 100.0f));
#elif TARGET_OS_TV
           CGContextSetAlpha(uiContext,((float)66 / 100.0f));

#endif
	              
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
#if TARGET_OS_IOS
        imageOverlay.multipleTouchEnabled = NO;
#endif
        imageOverlay.clearsContextBeforeDrawing = NO;
   
        //[imageBack setOpaque:YES];
                                         
        [self.view addSubview: imageOverlay];
	  	   
    }
   
    //DPAD---   
    [self buildTouchControllerViews];   
    /////
  
   //////////////////
#if TARGET_OS_IOS
   if(g_enable_debug_view)
   {
	  if(dview!=nil)
	  {
        [dview removeFromSuperview];
      }	 	  
	  
	  dview = [[DebugView alloc] initWithFrame:self.view.bounds withEmuController:self];
		 	  
	  [self filldebugRects];
	  
	  [self.view addSubview:dview];   
	  [dview setNeedsDisplay];
  }
#endif
  /////////////////	
}

- (void)buildLandscape{
	
   g_device_is_landscape = 1;
   g_device_is_fullscreen = g_pref_full_screen_land  || (g_joy_used && g_pref_full_screen_land_joy) || externalView != nil;

#if TARGET_OS_IOS
   [self getControllerCoords:1 ];
    
   [self adjustSizes];
    
   [LayoutData loadLayoutData:self];
   
   [self buildLandscapeImageBack];
#endif
        
   CGRect r;

#if TARGET_OS_IOS
   if(externalView!=nil)
   {
        r = rExternalView;
   }
   else if (!g_device_is_fullscreen)
   {
        r = rFrames[LANDSCAPE_VIEW_NOT_FULL];
   }     
   else
   {
        r = rFrames[LANDSCAPE_VIEW_FULL];
   }
#elif TARGET_OS_TV
    r = [[UIScreen mainScreen] bounds];
#endif
   
   if(g_pref_keep_aspect_ratio_land)
   {
       r = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(myosd_vis_video_width, myosd_vis_video_height), r);
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
    
    if (g_device_is_fullscreen &&
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
#if TARGET_OS_IOS
    if(!g_pref_animated_DPad /*|| !show_controls*/) {
        for(int i=0; i< NUM_BUTTONS;i++)
            old_btnStates[i] = btnStates[i];
        return;
    }

    if(dpad_state!=old_dpad_state && dpadView != nil && ![dpadView isHidden])
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
               [self.impactFeedback impactOccurred];
               imgName = nameImgButton_Press[i];
           }
           else
           {
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
    
    if (analogStickView != nil && ![analogStickView isHidden])
        [analogStickView update];
#endif
}

#if TARGET_OS_IOS
#pragma mark Touch Handling
-(NSSet*)touchHandler:(NSSet *)touches withEvent:(UIEvent *)event {
    if(change_layout)
    {
        [layoutView handleTouches:touches withEvent: event];
    }
    else if (g_joy_used && g_device_is_fullscreen)
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
        myosd_pad_status &= ~MYOSD_A;
        myosd_joy_status[0] &= ~MYOSD_A;
        myosd_pad_status &= ~MYOSD_B;
        myosd_joy_status[0] &= ~MYOSD_B;
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
        return nil;
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
            }
            else if (MyCGRectContainsPoint(rInput[BTN_START_RECT], point)) {
                //NSLog(@"MYOSD_START");
                myosd_pad_status |= MYOSD_START;
                btnStates[BTN_START] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
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
                btnStates[BTN_L2] = BUTTON_PRESS;
                buttonTouched = YES;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_R2] != nil && !buttonViews[BTN_R2].hidden && MyCGRectContainsPoint(rInput[BTN_R2_RECT], point) ) {
                //NSLog(@"MYOSD_R2");
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
        myosd_joy_status[0] |= MYOSD_A;
        myosd_pad_status |= MYOSD_A;
        if ( touchcount > 3 ) {
            // 4 touches = insert coin
            push_mame_button(0, MYOSD_SELECT);
        } else if ( touchcount > 2 ) {
            // 3 touches = press start
            push_mame_button(0, MYOSD_START);
        } else if ( touchcount > 1 ) {
            // more than one touch means secondary button press
            myosd_pad_status |= MYOSD_B;
            myosd_joy_status[0] |= MYOSD_B;
            myosd_pad_status &= ~MYOSD_A;
            myosd_joy_status[0] &= ~MYOSD_A;
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
        } else if ( screenType == IPAD_PRO_11 ) {
            deviceName = @"iPad_pro_11";
        } else if ( screenType == IPAD ) {
            deviceName = @"iPad";
        } else if ( screenType == IPAD_GEN_7 ) {
            deviceName = @"iPad_gen_7";
        } else {
            deviceName = @"iPad_pro_12_9";
        }
    } else {
        // default to the largest iPhone if unknown
        deviceName = @"iPhone_xr_xs_max";
    }
    
    NSLog(@"DEVICE: %@", deviceName);
    
	if(!orientation)
	{
        if (g_device_is_fullscreen)
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_portrait_full_%@.txt", g_skin_data, deviceName] UTF8String]];
        else
            fp = [self loadFile:[[NSString stringWithFormat:@"/SKIN_%d/controller_portrait_%@.txt", g_skin_data, deviceName] UTF8String]];
    }
	else
	{
        if (g_device_is_fullscreen)
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

#endif

- (void)getConf{
#if TARGET_OS_IOS
    char string[256];
    
    DeviceScreenType screenType = [DeviceScreenResolver resolve];
    char* config = "";
    
    if ( screenType == IPHONE_XR_XS_MAX ) {
        config = "config_iPhone_xr_xs_max.txt";
    } else if ( screenType == IPHONE_X_XS ) {
        config = "config_iPhone_x.txt";
    } else if ( screenType == IPHONE_6_7_8_PLUS ) {
        config = "config_iPhone_6_plus.txt";
    } else if ( screenType == IPHONE_6_7_8 ) {
        config = "config_iPhone_6.txt";
    } else if ( screenType == IPHONE_5 ) {
        config = "config_iPhone_5.txt";
    } else if ( screenType == IPHONE_4_OR_LESS ) {
        config = "config_iPhone.txt";
    } else if ( g_isIpad ) {
        if ( screenType == IPAD_PRO_12_9 ) {
            config = "config_iPad_pro_12_9.txt";
        } else if ( screenType == IPAD_PRO_10_5 ) {
            config = "config_iPad_pro_10_5.txt";
        } else if ( screenType == IPAD_PRO_11 ) {
            config = "config_iPad_pro_11.txt";
        } else if ( screenType == IPAD ) {
            config = "config_iPad.txt";
        } else if ( screenType == IPAD_GEN_7 ) {
            config = "config_iPad_gen_7.txt";
        } else {
            config = "config_iPad_pro_12_9.txt";
        }
    } else {
        // default to the largest iPhone if unknown
        config = "config_iPhone_xr_xs_max.txt";
    }
    
    NSLog(@"USING CONFIG: %s", config);
    
    FILE *fp = [self loadFile:config];

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
                case 0:    rFrames[PORTRAIT_VIEW_FULL]         = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 1:    rFrames[PORTRAIT_VIEW_NOT_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 2:    rFrames[PORTRAIT_IMAGE_BACK]         = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 3:    rFrames[PORTRAIT_IMAGE_OVERLAY]         = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                    
                case 4:    rFrames[LANDSCAPE_VIEW_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 5:    rFrames[LANDSCAPE_VIEW_NOT_FULL] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 6:    rFrames[LANDSCAPE_IMAGE_BACK]      = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 7:    rFrames[LANDSCAPE_IMAGE_OVERLAY]         = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                    
                case 8:    g_enable_debug_view = coords[0]; break;
                    //case 9:    main_thread_priority_type = coords[0]; break;
                    //case 10:   video_thread_priority_type = coords[0]; break;
            }
            i++;
        }
        fclose(fp);
    }
#endif
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCControllerDidConnectNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCControllerDidDisconnectNotification
                                                  object:nil];
    
    [self removeTouchControllerViews];
    
    screenView = nil;
    
    imageBack = nil;
    
    imageOverlay = nil;

#if TARGET_OS_IOS
    dview= nil;
#endif

    optionsController = nil;
    icadeView = nil;
    
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
    
    static NSCache* g_image_cache = nil;
    
    if (g_image_cache == nil)
        g_image_cache = [[NSCache alloc] init];
    
    img = [g_image_cache objectForKey:name];
    
    if ([img isKindOfClass:[UIImage class]])
        return img;
    if (img != nil)
        return nil;
    
    path=[NSString stringWithUTF8String:get_documents_path((char *)[name UTF8String])];
    
    img = [UIImage imageWithContentsOfFile:path];
    
    if(img==nil)
    {
       path=[NSString stringWithUTF8String:get_resource_path((char *)[name UTF8String])];
       img = [UIImage imageWithContentsOfFile:path];
    }
    [g_image_cache setObject:(img ?: [NSNull null]) forKey:name];
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

// move a single ZIP file from the document root into where it belongs.
//
// we handle three kinds of ZIP files...
//
//  * zipset, if the ZIP contains other ZIP files, then it is a zip of romsets, aka zipset?.
//  * artwork, if the ZIP contains a .LAY file, then it is artwork
//  * romset, if the ZIP has "normal" files in it assume it is a romset.
//
//  we will move a artwork zip file to the artwork directory
//  we will move a romset zip file to the roms directory
//  we will unzip (in place) a zipset
//
-(BOOL)moveROM:(NSString*)romName progressBlock:(void (^)(double progress))block {

    if (![[romName.pathExtension uppercaseString] isEqualToString:@"ZIP"])
        return FALSE;
    
    NSError *error = nil;

    NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
    NSString *romsPath = [NSString stringWithUTF8String:get_documents_path("roms")];
    NSString *artwPath = [NSString stringWithUTF8String:get_documents_path("artwork")];
    NSString *sampPath = [NSString stringWithUTF8String:get_documents_path("samples")];

    NSString *romPath = [rootPath stringByAppendingPathComponent:romName];
    
    // if the ROM had a name like "foobar 1.zip", "foobar (1).zip" use only the first word as the ROM name.
    // this most likley came when a user downloaded the zip and a foobar.zip already existed, MAME ROMs are <8 char and no spaces.
    if ([romName containsString:@" "])
        romName = [[romName componentsSeparatedByString:@" "].firstObject stringByAppendingPathExtension:@"zip"];

    NSLog(@"ROM NAME: '%@' PATH:%@", romName, romPath);

    //
    // scan the ZIP file to see what kind it is.
    //
    //  * zipset, if the ZIP contains other ZIP files, then it is a zip of romsets, aka zipset?.
    //  * artwork, if the ZIP contains a .LAY file, then it is artwork
    //  * samples, if the ZIP contains a .WAV file, then it is samples
    //  * romset, if the ZIP has "normal" files in it assume it is a romset.
    //
    int __block numLAY = 0;
    int __block numZIP = 0;
    int __block numCHD = 0;
    int __block numWAV = 0;
    int __block numFiles = 0;
    BOOL result = [ZipFile enumerate:romPath withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        NSString* ext = [info.name.pathExtension uppercaseString];
        numFiles++;
        if ([ext isEqualToString:@"LAY"])
            numLAY++;
        if ([ext isEqualToString:@"ZIP"])
            numZIP++;
        if ([ext isEqualToString:@"CHD"])
            numCHD++;
        if ([ext isEqualToString:@"WAV"])
            numWAV++;
    }];

    NSString* toPath = nil;

    if (!result)
    {
        NSLog(@"%@ is a CORRUPT ZIP (deleting)", romPath);
        [[NSFileManager defaultManager] removeItemAtPath:romPath error:nil];
    }
    else if (numZIP != 0 || numCHD != 0)
    {
        NSLog(@"%@ is a ZIPSET", [romPath lastPathComponent]);
        int maxFiles = numFiles;
        numFiles = 0;
        [ZipFile destructiveEnumerate:romPath withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
            NSString* toPath = nil;
            NSString* ext = [info.name.pathExtension uppercaseString];
            
            NSLog(@"...UNZIP: %@", info.name);

            // only UNZIP files to specific directories, send a ZIP file with a unspecifed directory to roms/
            if ([info.name hasPrefix:@"roms/"] || [info.name hasPrefix:@"artwork/"] || [info.name hasPrefix:@"titles/"]  || [info.name hasPrefix:@"samples/"] || [info.name hasPrefix:@"cfg/"])
                toPath = [rootPath stringByAppendingPathComponent:info.name];
            else if ([ext isEqualToString:@"ZIP"])
                toPath = [romsPath stringByAppendingPathComponent:[info.name lastPathComponent]];

            if (toPath != nil)
            {
                if (![NSFileManager.defaultManager createDirectoryAtPath:[toPath stringByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:nil])
                    NSLog(@"ERROR CREATING DIRECTORY: ", [info.name stringByDeletingLastPathComponent]);

                if (![info.data writeToFile:toPath atomically:YES])
                    NSLog(@"ERROR UNZIPing %@", info.name);
            }
            
            numFiles++;
            block((double)numFiles / maxFiles);
        }];
        toPath = nil;   // nothing to move, we unziped the file "in place"
    }
    else if (numLAY != 0)
    {
        NSLog(@"%@ is a ARTWORK file", romName);
        toPath = [artwPath stringByAppendingPathComponent:romName];
    }
    else if (numWAV != 0)
    {
        NSLog(@"%@ is a SAMPLES file", romName);
        toPath = [sampPath stringByAppendingPathComponent:romName];
    }
    else
    {
        NSLog(@"%@ is a ROMSET", romName);
        toPath = [romsPath stringByAppendingPathComponent:romName];
    }

    // move file to either ROMS, ARTWORK or SAMPLES
    if (toPath)
    {
        //first attemp to delete de old one
        [[NSFileManager defaultManager] removeItemAtPath:toPath error:&error];
        
        //now move it
        error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:romPath toPath:toPath error:&error];
        if(error!=nil)
        {
            NSLog(@"Unable to move rom: %@", [error localizedDescription]);
            result = FALSE;
        }
        block(1.0);
    }
    return result;
}

-(void)moveROMS {
    
    NSArray *filelist;
    NSUInteger count;
    NSUInteger i;
    static int g_move_roms = 0;
    
    NSString *fromPath = [NSString stringWithUTF8String:get_documents_path("")];
    filelist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fromPath error:nil];
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
    
    if(count != 0)
        NSLog(@"found (%d) ROMs to move....", (int)count);
    if(count != 0 && g_move_roms != 0)
        NSLog(@"....cant moveROMs now");
    
    if(count != 0 && g_move_roms++ == 0)
    {
        UIViewController* topViewController = self;
        while (topViewController.presentedViewController != nil)
            topViewController = topViewController.presentedViewController;

        UIAlertController *progressAlert = [UIAlertController alertControllerWithTitle:@"Moving ROMs" message:@"Please wait..." preferredStyle:UIAlertControllerStyleAlert];
        [progressAlert setProgress:0.0];
        [topViewController presentViewController:progressAlert animated:YES completion:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL result = TRUE;
            for (int i = 0; i < count; i++)
            {
                result = result && [self moveROM:[romlist objectAtIndex: i] progressBlock:^(double progress) {
                    [progressAlert setProgress:((double)i / count) + progress * (1.0 / count)];
                }];
                [progressAlert setProgress:(double)(i+1) / count];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [topViewController dismissViewControllerAnimated:YES completion:^{
                    
                    // reset MAME filter and last game...
                    if (result)
                    {
                       if(!(myosd_in_menu==0 && myosd_inGame)){
                          myosd_reset_filter = 1;
                       }
                       myosd_last_game_selected = 0;
                    }

                    // reload the MAME menu....
                    if (result)
                        [self performSelectorOnMainThread:@selector(playGame:) withObject:nil waitUntilDone:NO];
                    
                    g_move_roms = 0;
                }];
            });
        });
    }
}

#pragma mark - IMPORT and EXPORT

#if TARGET_OS_IOS
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"IMPORT CANCELED");
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls {
    UIApplication* application = UIApplication.sharedApplication;
    for (NSURL* url in urls) {
        NSLog(@"IMPORT: %@", url);

        // call our own openURL handler (in Bootstrapper)
        [application.delegate application:application openURL:url options:@{UIApplicationOpenURLOptionsOpenInPlaceKey:@(YES)}];
    }
}

- (void)runImport {
    // TODO: support multi select??
    UIDocumentPickerViewController* documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.zip-archive"] inMode:UIDocumentPickerModeOpen];
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    documentPicker.delegate = self;
    [(self.presentedViewController ?: self) presentViewController:documentPicker animated:YES completion:nil];
}

- (void)runExport {
    [self showAlertWithTitle:@"MAME4iOS" message:@"T.B.D."];
}
#endif

- (void)runServer {
    [[WebServer sharedInstance] startUploader];
    [WebServer sharedInstance].webUploader.delegate = self;
}

#pragma mark - CUSTOM LAYOUT

#if TARGET_OS_IOS
-(void)beginCustomizeCurrentLayout{
    
    if (g_joy_used && g_device_is_fullscreen)
    {
        [self showAlertWithTitle:nil message:@"You cannot customize current layout when using a external controller!"];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];

        [self changeUI]; //ensure GUI
        
        [screenView removeFromSuperview];
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
    
    change_layout = 0;

    [self done:self];
}

-(void)resetCurrentLayout{
    
    if (g_joy_used && g_device_is_fullscreen)
    {
        [self showAlertWithTitle:nil message:@"You cannot reset current layout when using a external controller!"];
        return;
    }
    
    [self showAlertWithTitle:nil message:@"Do you want to reset current layout to default?" buttons:@[@"Yes", @"No"] handler:^(NSUInteger buttonIndex) {
        if (buttonIndex == 0)
        {
            [LayoutData removeLayoutData];
            [self done:self];
        }
    }];
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
    
    if (g_device_is_fullscreen)
    {
       rStickWindow.size.height *= g_stick_size;
       rStickWindow.size.width *= g_stick_size;
    }
}
#endif

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

-(void)setupMFIControllers {
    
    // build list of controlers, put any non-game controllers (like the siri remote) at the end
    [controllers removeAllObjects];
    
    for (GCController* controler in GCController.controllers) {
#if TARGET_IPHONE_SIMULATOR // ignore the bogus controller in the simulator
        if ([controler.vendorName isEqualToString:@"Generic Controller"])
            continue;
#endif
        if (controler.extendedGamepad != nil)
            [controllers addObject:controler];
    }
    for (GCController* controler in GCController.controllers) {
        if (controler.extendedGamepad == nil)
            [controllers addObject:controler];
    }
    
    if (controllers.count == 0 && myosd_num_of_joys != 0) {
        g_joy_used = 0;
        myosd_num_of_joys = 0;
        [self changeUI];
    }
    
    if (controllers.count > 4) {
        [controllers removeObjectsInRange:NSMakeRange(4,controllers.count - 4)];
    }
    
    if (controllers.count != 0 && myosd_num_of_joys == 0) {
        g_joy_used = 1;
        myosd_num_of_joys = 8;
        [self changeUI];
    }
    
    for (int index = 0; index < controllers.count; index++) {

        GCController *MFIController = [controllers objectAtIndex:index];
        
        [MFIController setPlayerIndex:GCControllerPlayerIndexUnset];
        [MFIController setPlayerIndex:index];
        
        NSLog(@" PlayerIndex: %li", (long)MFIController.playerIndex);
        
        BOOL isSiriRemote = (MFIController.extendedGamepad == nil && MFIController.microGamepad != nil);
        
        MFIController.extendedGamepad.dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            NSLog(@"%d: %@", index, directionpad);
            
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
            [self handle_MENU];
        };
        
        //
        // handle a MENU BUTTON modifier
        //
        // NOTE because UIAlertController now works with a game controller, we dont need
        // to rely on these crazy button combinations, but I had to change them around
        // a little bit so just hitting menu by itself will bring up the MAME4iOS menu.
        //
        //                NEW                   OLD
        //                -------------         -------------
        //      MENU    = MAME4iOS MENU         START
        //      MENU+L1 = COIN/SELECT           COIN/SELECT
        //      MENU+R1 = START                 MAME MENU
        //      MENU+X  = EXIT GAME             EXIT GAME
        //      MENU+B  = MAME MENU             MAME4iOS MENU
        //      MENU+A  = LOAD STATE            LOAD STATE
        //      MENU+Y  = SAVE STATE            SAVE STATE
        //
        //      OPTION   = COIN + START
        //
        void (^menuButtonHandler)(BOOL) = ^(BOOL pressed){
            static int g_menu_modifier_button_pressed[4];
            
            NSLog(@"%d: MENU %s", index, pressed ? "DOWN" : "UP");
            
            // on MENU button up, if no modifier was pressed then show menu
            if (!pressed) {
                if (g_menu_modifier_button_pressed[index] == FALSE) {
                    // Show or Cancel Action Sheet (aka MAME4iOS) Menu
                    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
                       [(UIAlertController*)self.presentedViewController dismissWithCancel];
                    }
                    else if (myosd_inGame && myosd_in_menu == 0) {
                        [self runMenu:index];
                    }
                }
                g_menu_modifier_button_pressed[index] = FALSE;  // reset for next time.
                return;
            }

             // Add Coin
             if (MFIController.extendedGamepad.leftShoulder.pressed) {
                 NSLog(@"%d: MENU+L1 => COIN", index);
                 myosd_joy_status[index] &= ~MYOSD_L1;
                 push_mame_button(index, MYOSD_SELECT);
             }
             // Start
             else if (MFIController.extendedGamepad.rightShoulder.pressed) {
                 NSLog(@"%d: MENU+R1 => START", index);
                 myosd_joy_status[index] &= ~MYOSD_R1;
                 push_mame_button(index, MYOSD_START);
             }
             //Show Mame menu (Start + Coin)
             else if (MFIController.extendedGamepad.buttonB.pressed) {
                 NSLog(@"%d: MENU+B => MAME MENU", index);
                 myosd_joy_status[index] &= ~MYOSD_B;
                 push_mame_button(index, MYOSD_SELECT|MYOSD_START);
             }
             //Exit Game
             else if (MFIController.microGamepad.buttonX.pressed) {
                 NSLog(@"%d: MENU+X => EXIT GAME", index);
                 if (myosd_inGame && myosd_in_menu == 0) {
                     myosd_joy_status[index] &= ~MYOSD_X;
                     [self runExit];
                 }
             }
             // Load State
             else if (MFIController.microGamepad.buttonA.pressed ) {
                 NSLog(@"%d: MENU+A => LOAD STATE", index);
                 [self runLoadState];
             }
             // Save State
             else if (MFIController.extendedGamepad.buttonY.pressed ) {
                 NSLog(@"%d: MENU+Y => SAVE STATE", index);
                 [self runSaveState];
             }
             else {
                 return;
             }
             g_menu_modifier_button_pressed[index] = TRUE;
        };
        
        MFIController.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
            NSLog(@"%d: %@", index, element);
            
#if TARGET_OS_TV
            // disable button presses while alert is shown
            if ([self controllerUserInteractionEnabled]) {
                return;
            }
#endif
             if (@available(iOS 13.0, tvOS 13.0, *)) {
                if (gamepad.buttonMenu.pressed && element != gamepad.buttonMenu) {
                    menuButtonHandler(TRUE);
                    return;
                }
            }
            
            if (element == gamepad.buttonA) {
                if (gamepad.buttonA.pressed) {
                    myosd_joy_status[index] |= MYOSD_A;
                }
                else {
                    [self handle_MENU];     // handle menu on button UP
                    myosd_joy_status[index] &= ~MYOSD_A;
                }
            }
            if (element == gamepad.buttonB) {
                if (gamepad.buttonB.pressed) {
                    myosd_joy_status[index] |= MYOSD_B;
                }
                else {
                    [self handle_MENU];     // handle menu on button UP
                    myosd_joy_status[index] &= ~MYOSD_B;
                }
            }
            if (element == gamepad.buttonX) {
                if (gamepad.buttonX.pressed) {
                    myosd_joy_status[index] |= MYOSD_X;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_X;
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
                if (gamepad.leftTrigger.pressed) {
                    myosd_joy_status[index] |= MYOSD_L2;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_L2;
                }
            }
            if (element == gamepad.rightTrigger) {
                joy_analog_x[index][3] = gamepad.rightTrigger.value;
                if (gamepad.rightTrigger.pressed) {
                    myosd_joy_status[index] |= MYOSD_R2;
                }
                else {
                    myosd_joy_status[index] &= ~MYOSD_R2;
                }
            }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120100 || __TV_OS_VERSION_MAX_ALLOWED >= 120100
            if (@available(iOS 12.1, *)) {
                if ( element == gamepad.leftThumbstickButton ) {
                    if ( gamepad.leftThumbstickButton.pressed ) {
                        myosd_joy_status[index] |= MYOSD_L3;
                    } else {
                        myosd_joy_status[index] &= ~MYOSD_L3;
                    }
                }
                if ( element == gamepad.rightThumbstickButton ) {
                    if ( gamepad.rightThumbstickButton.pressed ) {
                        myosd_joy_status[index] |= MYOSD_R3;
                    } else {
                        myosd_joy_status[index] &= ~MYOSD_R3;
                    }
                }
            }
#endif
        };
        
        //
        // handle a siri remote, it only has a A,X,MENU button plus a dpad
        //
        if (isSiriRemote) {

            MFIController.microGamepad.allowsRotation = YES;
            MFIController.microGamepad.reportsAbsoluteDpadValues = NO;

            MFIController.microGamepad.valueChangedHandler = ^(GCMicroGamepad* gamepad, GCControllerElement* element) {
                NSLog(@"%d: %@", index, element);
                if (element == gamepad.buttonA) {
                    if (gamepad.buttonA.pressed) {
                        myosd_joy_status[index] |= MYOSD_A;
                    }
                    else {
                        myosd_joy_status[index] &= ~MYOSD_A;
                    }
                }
                if (element == gamepad.buttonX) {
                    if (gamepad.buttonX.pressed) {
                        myosd_joy_status[index] |= MYOSD_X;
                    }
                    else {
                        myosd_joy_status[index] &= ~MYOSD_X;
                    }
                }
            };
            MFIController.microGamepad.dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
                NSLog(@"%d: %@", index, directionpad);
                
                // emulate a analog joystick and a dpad
                joy_analog_x[index][0] = directionpad.xAxis.value;
                if (STICK2WAY)
                    joy_analog_y[index][0] = 0.0;
                else
                    joy_analog_y[index][0] = directionpad.yAxis.value;

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
                
                if (STICK2WAY) {
                     myosd_joy_status[index] &= ~(MYOSD_UP | MYOSD_DOWN);
                }
                else if (STICK4WAY) {
                    if (fabs(joy_analog_y[index][0]) > fabs(joy_analog_x[index][0]))
                        myosd_joy_status[index] &= ~(MYOSD_LEFT|MYOSD_RIGHT);
                    else
                        myosd_joy_status[index] &= ~(MYOSD_DOWN|MYOSD_UP);
                }
            };
        }
        
        MFIController.extendedGamepad.leftThumbstick.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            float deadZone = [self getDeadZone];
            
            NSLog(@"%d: %@", index, directionpad);

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
            
            NSLog(@"%d: %@", index, directionpad);

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
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000 || __TV_OS_VERSION_MAX_ALLOWED >= 130000
        // handle MENU and OPTION buttons on Xbox and PS4 controllers
        if (@available(iOS 13.0, tvOS 13.0, *)) {
            MFIController.microGamepad.buttonMenu.pressedChangedHandler = ^(GCControllerButtonInput* button, float value, BOOL pressed) {
                menuButtonHandler(pressed);
            };
            MFIController.extendedGamepad.buttonMenu.pressedChangedHandler = MFIController.microGamepad.buttonMenu.pressedChangedHandler;
            
            MFIController.extendedGamepad.buttonOptions.pressedChangedHandler = ^(GCControllerButtonInput* button, float value, BOOL pressed) {
                if (!pressed) {
                    NSLog(@"%d: OPTIONS", index);

                    // Insert a COIN, then do a START (Player 1 or Player 2)
                    push_mame_buttons(index, MYOSD_SELECT, MYOSD_START);
                }
            };
        }
        else {
            MFIController.controllerPausedHandler = ^(GCController *controller) {
                menuButtonHandler(TRUE);
                menuButtonHandler(FALSE);
            };
        }
#else
        MFIController.controllerPausedHandler = ^(GCController *controller) {
            menuButtonHandler(TRUE);
            menuButtonHandler(FALSE);
        };
#endif
    }
    
}

-(void)scanForDevices{
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
}

-(void)MFIControllerConnected:(NSNotification*)notif{
    GCController *controller = (GCController *)[notif object];
    NSLog(@"Hello %@", controller.vendorName);

    // if we already have this controller, ignore
    if ([controllers containsObject:controller])
        return;

    [self setupMFIControllers];
#if TARGET_OS_IOS
    if ([controllers containsObject:controller]) {
        [self.view makeToast:[NSString stringWithFormat:@"%@ connected", controller.vendorName] duration:4.0 position:CSToastPositionCenter style:toastStyle];
    }
#endif
}

-(void)MFIControllerDisconnected:(NSNotification*)notif{
    GCController *controller = (GCController *)[notif object];
    
    if (![controllers containsObject:controller])
        return;
    
    NSLog(@"Goodbye %@", controller.vendorName);
    [self setupMFIControllers];
#if TARGET_OS_IOS
    [self.view makeToast:[NSString stringWithFormat:@"%@ disconnected", controller.vendorName] duration:4.0 position:CSToastPositionCenter style:toastStyle];
#endif
}

#pragma mark GCDWebServerDelegate
- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server {
    
    NSMutableString *servers = [[NSMutableString alloc] init];

    if ( server.serverURL != nil ) {
        [servers appendString:[NSString stringWithFormat:@"%@",server.serverURL]];
    }
    if ( servers.length > 0 ) {
        [servers appendString:@"\n\n"];
    }
    if ( server.bonjourServerURL != nil ) {
        [servers appendString:[NSString stringWithFormat:@"%@",server.bonjourServerURL]];
    }
#if TARGET_OS_TV
    NSString* welcome = @"Welcome to MAME for AppleTV";
    NSString* message = [NSString stringWithFormat:@"\nTo transfer ROMs from your computer go to one of these addresses in your web browser:\n\n%@",servers];
#else
    NSString* welcome = @"Welcome to MAME4iOS";
    NSString* message = [NSString stringWithFormat:@"\nTo transfer ROMs from your computer, use AirDrop, or go to one of these addresses in your web browser:\n\n%@",servers];
#endif
    NSString* title = g_no_roms_found ? welcome : @"Web Server Started";
    NSString* done  = g_no_roms_found ? @"Reload ROMs" : @"Stop Server";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:done style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[WebServer sharedInstance] webUploader].delegate = nil;
        [[WebServer sharedInstance] stopUploader];
        if (!myosd_inGame)
            myosd_exitGame = 1;     /* exit mame menu and re-scan ROMs*/
    }]];
    UIViewController* vc = self;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

#pragma mark play GAME

// this is called three ways
//    -- after the user has selected a game in the ChooseGame UI
//    -- if a NSUserActivity is restored
//    -- if a mame4ios: URL is opened.
//
-(void)playGame:(NSDictionary*)game {
    NSLog(@"PLAY: %@", game);
    
    // if we are not presenting anything, we can just "run" the game
    // else we need to dismiss what is active and try again...
    //
    // we can be in the following states
    // 1. alert is up...
    //      pause
    //      exit
    //      menu
    //      server
    //      other/error
    //
    //      if the alert has a cancel button, cancel and then run game....
    //
    // 2. settings view controller is active
    //      just fail in this case.
    //
    // 3. choose game controller is active.
    //      dissmiss and run game.
    //
    UIViewController* viewController = self.presentedViewController;
    if ([viewController isKindOfClass:[UINavigationController class]])
        viewController = [(UINavigationController*)viewController topViewController];
    
    if ([viewController isKindOfClass:[UIAlertController class]]) {
        UIAlertController* alert = (UIAlertController*)viewController;
        UIAlertAction* action;

        NSLog(@"ALERT: %@:%@", alert.title, alert.message);
        
        if (alert.actions.count == 1)
            action = alert.preferredAction ?: alert.cancelAction;
        else
            action = alert.cancelAction;
        
        if (action != nil) {
            [alert dismissWithAction:action completion:^{
                [self performSelectorOnMainThread:@selector(playGame:) withObject:game waitUntilDone:NO];
            }];
            return;
        }
        else {
            NSLog(@"CANT RUN GAME! (alert does not have a default or cancel button)");
            return;
        }
    }
    else if ([viewController isKindOfClass:[ChooseGameController class]]) {
        // if we are in the ChooseGame UI dismiss and run game
        ChooseGameController* choose = (ChooseGameController*)viewController;
        if (choose.selectGameCallback != nil)
            choose.selectGameCallback(game);
        return;
    }
    else if (viewController != nil) {
        NSLog(@"CANT RUN GAME! (%@ is active)", viewController);
        return;
    }
    
    NSString* name = game[kGameInfoName];
    
    if ([name isEqualToString:kGameInfoNameMameMenu])
        name = @" ";

    if (name != nil) {
        strncpy(g_mame_game, [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(g_mame_game));
        [[NSUserDefaults standardUserDefaults] setObject:game forKey:kSelectedGameKey];
        [self updateUserActivity];
    }
    else {
        g_mame_game[0] = 0;     // run the MENU
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedGameKey];
    }

    g_emulation_paused = 0;
    change_pause(g_emulation_paused);
    myosd_exitGame = 1; // exit menu mode and start game or menu.
}

#pragma mark choose game UI

-(void)chooseGame:(NSArray*)games {
    // a Alert or Setting is up, bail
    if (self.presentedViewController != nil) {
        NSLog(@"CANT SHOW CHOOSE GAME UI....");
        if (self.presentedViewController.beingDismissed) {
            NSLog(@"....TRY AGAIN");
            [self performSelector:_cmd withObject:games afterDelay:1.0];
        }
        return;
    }
    g_no_roms_found = [games count] == 0;
    if (g_no_roms_found) {
        NSLog(@"NO GAMES, START SERVER....");
        [self runServer];
        return;
    }
    if (g_mame_game_error[0] != 0) {
        NSLog(@"ERROR RUNNING GAME %s", g_mame_game_error);
        
        NSString* msg = [NSString stringWithFormat:@"ERROR RUNNING GAME %s", g_mame_game_error];
        g_mame_game_error[0] = 0;
        g_mame_game[0] = 0;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedGameKey];
        
        [self showAlertWithTitle:@"MAME4iOS" message:msg buttons:@[@"Ok"] handler:^(NSUInteger button) {
            [self performSelectorOnMainThread:@selector(chooseGame:) withObject:games waitUntilDone:FALSE];
        }];
        return;
    }
    if (g_mame_game[0] == ' ') {
        NSLog(@"RUNNING MAME MENU, DONT BRING UP UI.");
        return;
    }

    NSLog(@"GAMES: %@", games);

    ChooseGameController* choose = [[ChooseGameController alloc] init];
    [choose setGameList:games];
    g_emulation_paused = 1;
    change_pause(g_emulation_paused);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedGameKey];
    choose.selectGameCallback = ^(NSDictionary* game) {
        if ([game[kGameInfoName] isEqualToString:kGameInfoNameSettings]) {
            [self runSettings];
            return;
        }
        [self dismissViewControllerAnimated:YES completion:^{
            self->icadeView.active = TRUE;
            [self performSelectorOnMainThread:@selector(playGame:) withObject:game waitUntilDone:FALSE];
        }];
    };
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:choose];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        nav.modalInPresentation = YES;    // disable iOS 13 swipe to dismiss...
    }
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark UIEvent handling for button presses

#if TARGET_OS_TV
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event; {
    // in the simulator we may not have any controllers
    if (controllers.count == 0) {
        for (UIPress *press in presses) {
            if (press.type == UIPressTypeMenu) {
                return [self runMenu];
            }
        }
    }
    // not a menu press, delegate to UIKit responder handling
    [super pressesBegan:presses withEvent:event];
}
#endif

#pragma mark NSUserActivty

-(void)updateUserActivity
{
    NSDictionary* game = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSelectedGameKey];
    
    if (game == nil || game[kGameInfoName] == nil || [game[kGameInfoName] length] <= 1)
        return;

#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 120100
    if (@available(iOS 12.0, *)) {
        NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
        NSString* name = game[kGameInfoDescription] ?: game[kGameInfoName];
        NSString* title = [NSString stringWithFormat:@"Play %@", [[name componentsSeparatedByString:@" ("] firstObject]];
        
        NSUserActivity* activity = [[NSUserActivity alloc] initWithActivityType:type];
        
        activity.title = title;
        activity.userInfo = game;
        activity.eligibleForSearch = TRUE;
        activity.eligibleForPrediction = TRUE;
        activity.persistentIdentifier = game[kGameInfoName];
        activity.suggestedInvocationPhrase = title;

        if ([title containsString:@"Donkey Kong"])
            activity.suggestedInvocationPhrase = @"It's on like Donkey Kong!";
        
        self.userActivity = activity;
        [activity becomeCurrent];
    }
#endif
}

@end
