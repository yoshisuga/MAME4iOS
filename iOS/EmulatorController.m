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
#import "FileItemProvider.h"
#endif

#import "ChooseGameController.h"

#if TARGET_OS_TV
#import "TVOptionsController.h"
#endif

#import "iCadeView.h"
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
#import "SteamController.h"

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

// mfi Controllers
NSMutableArray *controllers;

// Turbo functionality
int cyclesAfterButtonPressed[NUM_JOY][NUM_BUTTONS];
int turboBtnEnabled[NUM_BUTTONS];

// On-screen touch gamepad button state
unsigned long buttonState;      // on-screen button state, MYOSD_*
int buttonMask[NUM_BUTTONS];    // map a button index to a button MYOSD_* mask

// Touch Directional Input tracking
int touchDirectionalCyclesAfterMoved = 0;

int g_isIpad = 0;

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
int g_pref_nintendoBAYX = 0;

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
static BOOL g_mame_reset = FALSE;           // do a full reset (delete cfg files) before running MAME
static char g_mame_game[MAX_GAME_NAME];     // game MAME should run (or empty is menu)
static char g_mame_game_error[MAX_GAME_NAME];
static BOOL g_no_roms_found = FALSE;

static NSInteger g_settings_roms_count;
static NSInteger g_settings_file_count;

static EmulatorController *sharedInstance = nil;

static const int buttonPressReleaseCycles = 2;
static const int buttonNextPressCycles = 32;

void iphone_Reset_Views(void)
{
    if (sharedInstance == nil)
       return;
    
    if(!myosd_inGame)
       [sharedInstance performSelectorOnMainThread:@selector(moveROMS) withObject:nil waitUntilDone:NO];
    [sharedInstance performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];
}
void iphone_UpdateScreen()
{
    if (sharedInstance == nil || sharedInstance->screenView == nil)
        return;
    
    [sharedInstance->screenView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
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
        
        // reset MAME by deleteing CFG files, cfg/default.cfg and cfg/ROMNAME.cfg
        if (g_mame_reset) {
            NSString *cfg_path = [NSString stringWithUTF8String:get_documents_path("cfg")];
            
            // NOTE we need to delete the default.cfg file here because MAME saves cfg files on exit.
            [[NSFileManager defaultManager] removeItemAtPath: [cfg_path stringByAppendingPathComponent:@"default.cfg"] error:nil];

#if 0 // should we use this big of hammer? the user can always delete settings on a game by game basis via context menu in ChooseGameController.
            // delete *all* the cfg files, not just default.cfg so we reset settings for all games.
            [[NSFileManager defaultManager] removeItemAtPath:cfg_path error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:cfg_path withIntermediateDirectories:NO attributes:nil error:nil];
#endif
            g_mame_reset = FALSE;
        }
        
        if (run_mame(g_mame_game) != 0 && g_mame_game[0]) {
            strncpy(g_mame_game_error, g_mame_game, sizeof(g_mame_game_error));
            g_mame_game[0] = 0;
        }
    }
}

#ifdef DEBUG
NSDictionary* g_category_dict = nil;
#endif

// find the category for a game/rom using Category.ini (a copy of a similar function from uimenu.c)
NSString* find_category(NSString* name)
{
#ifndef DEBUG
    static NSDictionary* g_category_dict = nil;
#endif
    
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
                kGameInfoDriver:      [[NSString stringWithUTF8String:game_info[i]->source_file ?: ""].lastPathComponent stringByDeletingPathExtension],
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
}
@end

@implementation EmulatorController

@synthesize externalView;
@synthesize stick_radio;
@synthesize rStickWindow;

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
    return analogStickView;
}

- (UIView *)getStickView{
    return analogStickView;
}

#endif

- (void)startEmulation {
    NSParameterAssert(g_emulation_initiated == 0);
    
    sharedInstance = self;
    
    NSString* name = [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedGameKey] ?: @"";
    if ([name isEqualToString:kGameInfoNameMameMenu])
        name = @" ";
    strncpy(g_mame_game, [name cStringUsingEncoding:NSUTF8StringEncoding], sizeof(g_mame_game));
    g_mame_game_error[0] = 0;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedGameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
	     		    				
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


enum {LOAD_STATE, SAVE_STATE, ASK_STATE};

void mame_state(int load_save, int slot)
{
    myosd_loadstate = (load_save == LOAD_STATE);
    myosd_savestate = (load_save == SAVE_STATE);
    push_mame_buttons(0, 0, (slot == 1) ? MYOSD_B : MYOSD_X);       // delay, slot #
}

- (void)runState:(int)load_save
{
    if (self.presentedViewController)
        return NSLog(@"runLoadSaveState: BUSY!");
    
    if (load_save == ASK_STATE) {
        [self startMenu];
        [self showAlertWithTitle:nil message:nil buttons:@[@"Save State 1", @"Load State 1", @"Save State 2", @"Load State 2", @"Cancel"] handler:^(NSUInteger button) {
            if (button < 4)
                mame_state((button & 1) ? LOAD_STATE : SAVE_STATE, (button < 2) ? 1 : 2);
            [self endMenu];
        }];
    }
    else {
        NSString* message = [NSString stringWithFormat:@"Select State to %@", (load_save == LOAD_STATE) ? @"Load" : @"Save"];
        NSString* state1 = (controllers.count > 0 && TARGET_OS_IOS) ? @"Ⓧ State 1" : @"State 1";
        NSString* state2 = (controllers.count > 0 && TARGET_OS_IOS) ? @"Ⓨ State 2" : @"State 2";
        
        [self startMenu];
        [self showAlertWithTitle:nil message:message buttons:@[state1, state2, @"Cancel"] handler:^(NSUInteger button) {
            if (button <= 1)
                mame_state(load_save, (button == 0) ? 1 : 2);
            [self endMenu];
        }];
    }
}
- (void)runLoadState
{
    [self runState:LOAD_STATE];
}
- (void)runSaveState
{
    [self runState:SAVE_STATE];
}

- (void)runMenu:(int)player
{
    if (self.presentedViewController != nil)
        return;
    
    [self startMenu];

    int enable_menu_exit_option = TRUE; // (myosd_inGame && myosd_in_menu==0) || !myosd_inGame;
    
    NSString* title = nil;
    NSInteger controller_count = controllers.count;
#if TARGET_OS_TV
    if (controller_count > 1 && ((GCController*)controllers.lastObject).extendedGamepad == nil)
        controller_count--;
#endif
    if (controller_count > 1)
        title = [NSString stringWithFormat:@"Player %d", player+1];
    
    UIAlertController* menu = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    CGFloat size = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 1.5;

    if(myosd_inGame && myosd_in_menu==0)
    {
        // MENU item to insert a coin and do a start. usefull for fullscreen and AppleTV siri remote, and discoverability on a GameController
        if (player >= 2 && myosd_num_players > 2) {
            // in-game menu for player 3+ just give them a COIN+START option....
            [menu addAction:[UIAlertAction actionWithTitle:@"Coin+Start" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"centsign.circle" withPointSize:size] handler:^(UIAlertAction* action) {
                 push_mame_button(0, MYOSD_SELECT);      // Player 1 COIN
                 push_mame_button((player < myosd_num_coins ? player : 0), MYOSD_SELECT);  // Player X (or P1) COIN
                 push_mame_button(player, MYOSD_START);  // Player X START
                 [self endMenu];
            }]];
        }
        else {
            // in-game menu for player 1 or 2, give them options to start 1P or 2P
            int num_players = MIN(myosd_num_players, 2);

            for (int player=0; player<num_players; player++) {
                title = [NSString stringWithFormat:@"Coin+Start %d Player", player+1];
                NSString* image = @[@"person", @"person.2", @"person.3", @"centsign.circle"][player];
                [menu addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:image withPointSize:size] handler:^(UIAlertAction* action) {

                    // add an extra COIN for good luck, some games need two coins to play by default
                    push_mame_button(0, MYOSD_SELECT);  // Player 1 coin

                    // insert a COIN for each player, make sure to not exceed the max coin slot for game
                    for (int i=0; i<=player; i++)
                        push_mame_button((player < myosd_num_coins ? player : 0), MYOSD_SELECT);  // Player X coin
 
                    // then hit START
                    push_mame_button(player, MYOSD_START);      // Player X start
                    [self endMenu];
                }]];
            }
        }
        [menu addAction:[UIAlertAction actionWithTitle:@"Load/Save State" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"bookmark" withPointSize:size] handler:^(UIAlertAction* action) {
            [self runState:ASK_STATE];
        }]];
        [menu addAction:[UIAlertAction actionWithTitle:@"MAME Menu" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"slider.horizontal.3" withPointSize:size] handler:^(UIAlertAction* action) {
            myosd_configure = 1;
            [self endMenu];
        }]];
    }
    [menu addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"gear" withPointSize:size] handler:^(UIAlertAction* action) {
        [self runSettings];
    }]];

#ifdef DEBUG
    [menu addAction:[UIAlertAction actionWithTitle:(g_enable_debug_view ? @"DEBUG OFF" : @"DEBUG ON") style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"bolt" withPointSize:size] handler:^(UIAlertAction* action) {
        [self endMenu];
        g_enable_debug_view = !g_enable_debug_view;
        [self changeUI];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:(g_device_is_fullscreen ? @"FULLSCREEN OFF" : @"FULLSCREEN ON") style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right" withPointSize:size] handler:^(UIAlertAction* action) {
        [self endMenu];
        if (g_device_is_landscape)
            g_pref_full_screen_land = g_pref_full_screen_land_joy = !g_device_is_fullscreen;
        else
            g_pref_full_screen_port = g_pref_full_screen_port_joy = !g_device_is_fullscreen;
        [self changeUI];
    }]];
#endif
    
    if(enable_menu_exit_option) {
        [menu addAction:[UIAlertAction actionWithTitle:((myosd_inGame && myosd_in_menu==0) ? @"Exit Game" : @"Exit") style:UIAlertActionStyleDestructive image:[UIImage systemImageNamed:@"arrow.uturn.left.circle" withPointSize:size] handler:^(UIAlertAction* action) {
            [self endMenu];
            [self runExit:NO]; // the user just selected "Exit Game" from a menu, dont ask again
        }]];
    }
    
    [menu addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
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

// show or dismiss our in-game menu (called on joystick MENU button)
- (void)toggleMenu:(int)player
{
    // if menu is up take it down
    if (self.presentedViewController != nil) {
        if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
            UIAlertController* alert = (UIAlertController*)self.presentedViewController;
            if (!alert.isBeingDismissed && alert.preferredStyle == UIAlertControllerStyleActionSheet) {
                [alert dismissWithCancel];
            }
        }
        return;
    }
    else {
        [self runMenu:player];
    }
}

- (void)runExit:(BOOL)ask_user
{
    if (self.presentedViewController != nil)
        return;

    if (myosd_in_menu == 0 && ask_user)
    {
        NSString* yes = (controllers.count > 0 && TARGET_OS_IOS) ? @"Ⓐ Yes" : @"Yes";
        NSString* no  = (controllers.count > 0 && TARGET_OS_IOS) ? @"Ⓑ No" : @"No";

        UIAlertController *exitAlertController = [UIAlertController alertControllerWithTitle:@"" message:@"Are you sure you want to exit?" preferredStyle:UIAlertControllerStyleAlert];

        [self startMenu];
        [exitAlertController addAction:[UIAlertAction actionWithTitle:yes style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            [self endMenu];
            [self runExit:NO];
        }]];
        [exitAlertController addAction:[UIAlertAction actionWithTitle:no style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
            [self endMenu];
        }]];
        exitAlertController.preferredAction = exitAlertController.actions.firstObject;
        [self presentViewController:exitAlertController animated:YES completion:nil];
    }
    else if (myosd_inGame && myosd_in_menu == 0)
    {
        if (g_mame_game[0] != ' ')
            g_mame_game[0] = 0;
        myosd_exitGame = 1;
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

- (void)runExit
{
    [self runExit:YES];
}

- (void)runPause
{
    // this is called from bootstrapper when app is going into the background, save the current game we are playing so we can restore next time.
    NSString* name = [NSString stringWithUTF8String:g_mame_game];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:kSelectedGameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.presentedViewController != nil || g_emulation_paused)
        return;
    
    // dont pause the MAME select game menu.
    if (!myosd_inGame)
        return;

    [self startMenu];
    [self showAlertWithTitle:@"MAME4iOS" message:@"Game is PAUSED" buttons:@[@"Continue"] handler:^(NSUInteger button) {
        [self endMenu];
    }];
}

- (void)runSettings {
    
    g_settings_file_count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:get_documents_path("")] error:nil] count];
    g_settings_roms_count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:get_documents_path("roms")] error:nil] count];

    [self startMenu];
    
#if TARGET_OS_IOS
    OptionsController* optionsController = [[OptionsController alloc] initWithEmuController:self];
#elif TARGET_OS_TV
    TVOptionsController *optionsController = [[TVOptionsController alloc] initWithEmuController:self];
#endif

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:optionsController];
#if TARGET_OS_IOS
    [navController setModalPresentationStyle:UIModalPresentationPageSheet];
#endif
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        navController.modalInPresentation = YES;    // disable iOS 13 swipe to dismiss...
        navController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    [self.topViewController presentViewController:navController animated:YES completion:nil];
}

- (void)endMenu{
    int old_joy_used = g_joy_used;
    g_joy_used = myosd_num_of_joys!=0;
    
    if (old_joy_used != g_joy_used)
        [self changeUI];
    
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

    g_pref_nintendoBAYX = [op nintendoBAYX];

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
    
    // have the parent of the options/setting dialog dismiss
    // we present settings two ways, from in-game menu (we are parent) and from ChooseGameUI (it is the parent)
    UIViewController* parent = self.topViewController.presentingViewController;
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
        if (myosd_inGame == 0 || g_mame_reset)
            myosd_exitGame = 1;

        [self updateOptions];
        
        [self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
        
        NSInteger file_count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:get_documents_path("")] error:nil] count];
        NSInteger roms_count = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:get_documents_path("roms")] error:nil] count];

        if (file_count != g_settings_file_count)
            NSLog(@"SETTINGS DONE: files added to root %ld => %ld", g_settings_file_count, file_count);
        if (roms_count != g_settings_roms_count)
            NSLog(@"SETTINGS DONE: files added to roms %ld => %ld", g_settings_roms_count, roms_count);

        if (g_settings_file_count != file_count)
            [self performSelector:@selector(moveROMS) withObject:nil afterDelay:0.0];
        else if (g_settings_roms_count != roms_count || (g_mame_reset && myosd_inGame == 0))
            [self performSelector:@selector(playGame:) withObject:nil afterDelay:0.0];
        
        // dont call endMenu (and unpause MAME) if we still have a dialog up.
        if (self.presentedViewController == nil)
            [self endMenu];
    }];
}


#if TARGET_OS_IOS   // NOT needed on tvOS it handles it with the focus engine
- (void)handle_MENU
{
    unsigned long pad_status = myosd_pad_status | myosd_joy_status[0] | myosd_joy_status[1] | myosd_joy_status[2] | myosd_joy_status[3];
    
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
        if (pad_status & MYOSD_Y)
            [alert dismissWithTitle:@"Ⓨ"];
        if (pad_status & MYOSD_X)
            [alert dismissWithTitle:@"Ⓧ"];
        if (pad_status & MYOSD_UP)
            [alert moveDefaultAction:-1];
        if (pad_status & MYOSD_DOWN)
            [alert moveDefaultAction:+1];
        return;
    }
    
    // if we are showing some other UI, give it a chance to handle input.
    if ([viewController respondsToSelector:@selector(handle_MENU)])
        [viewController performSelector:@selector(handle_MENU)];
    
    // if we are showing something else, just ignore.
    if (viewController != nil)
        return;

    // touch screen EXIT button
    if ((buttonState & MYOSD_EXIT) && !(pad_status & MYOSD_EXIT))
    {
        [self runExit];
    }
    
    // touch screen OPTION button
    if ((buttonState & MYOSD_OPTION) && !(pad_status & MYOSD_OPTION))
    {
        [self runMenu];
    }
    
    // exit MAME MENU with B (but only if we are not mapping a input)
    if (myosd_in_menu == 1 && (pad_status & MYOSD_B))
    {
        [self runExit];
    }
    
    // SELECT and START at the same time (iCade, keyboard, 8bitDo, touch)
    if ((pad_status & MYOSD_SELECT) && (pad_status & MYOSD_START))
    {
        // hide these keys from MAME
        myosd_pad_status &= ~(MYOSD_SELECT|MYOSD_START);
        [self runMenu];
    }
}
#endif

-(void)viewDidLoad{
    printf("viewDidLoad\n");
    
    self.view.backgroundColor = [UIColor blackColor];

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
    
    // map a button index to a MYOSD button mask
    buttonMask[BTN_A] = MYOSD_A;
    buttonMask[BTN_B] = MYOSD_B;
    buttonMask[BTN_X] = MYOSD_X;
    buttonMask[BTN_Y] = MYOSD_Y;
    buttonMask[BTN_L1] = MYOSD_L1;
    buttonMask[BTN_R1] = MYOSD_R1;
    buttonMask[BTN_EXIT] = MYOSD_EXIT;
    buttonMask[BTN_OPTION] = MYOSD_OPTION;
    buttonMask[BTN_SELECT] = MYOSD_SELECT;
    buttonMask[BTN_START] = MYOSD_START;
         
    [self getConf];

	self.view.userInteractionEnabled = YES;

#if TARGET_OS_IOS
	self.view.multipleTouchEnabled = YES;
	self.view.exclusiveTouch = NO;
#endif
	
	//kito
	//[NSThread setThreadPriority:1.0];
	
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

    [self updateUserActivity:nil];      // TODO: look at if we need to do this here??
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self scanForDevices];
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
    return g_device_is_fullscreen;
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

#if TARGET_OS_IOS
-(void) toggleControlsForLightgunButtonPressed:(id)sender {
    // hack for when using a game controller - it will display the menu
    if ( g_joy_used ) {
        [self runMenu];
        return;
    }
    areControlsHidden = !areControlsHidden;
    
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
        if (alpha == 0.0)
            NSLog(@"**** HIDING ScreenView ****");
        else
            NSLog(@"**** SHOWING ScreenView ****");
    }

    screenView.alpha = alpha;
    imageOverlay.alpha = alpha;
    imageLogo.alpha = (1.0 - alpha);
}

-(void)buildLogoView {
    // no need to show logo in fullscreen.
    if (g_device_is_fullscreen || TARGET_OS_TV)
        return;

    // create a logo view to show when no-game is displayed. (place on external display, or in app.)
    imageLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mame_logo"]];
    imageLogo.contentMode = UIViewContentModeScaleAspectFit;
    if (externalView != nil)
        imageLogo.frame = externalView.bounds;
    else if (g_device_is_fullscreen)
        imageLogo.frame = self.view.bounds;
    else
        imageLogo.frame = g_device_is_landscape ? rFrames[LANDSCAPE_VIEW_NOT_FULL] : rFrames[PORTRAIT_VIEW_NOT_FULL];
    [screenView.superview addSubview:imageLogo];
}

- (void)changeUI { @autoreleasepool {

  int prev_emulation_paused = g_emulation_paused;
   
  if (g_emulation_paused == 0) {
    g_emulation_paused = 1;
    change_pause(1);
  }
    
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
    
  if(imageLogo != nil)
  {
      [imageLogo removeFromSuperview];
      imageLogo = nil;
  }

  if(imageExternalDisplay != nil)
  {
      [imageExternalDisplay removeFromSuperview];
      imageExternalDisplay = nil;
  }

#if TARGET_OS_IOS
    
// this does not make any sence, iCadeView needs to become the first responder and get keyboard input, it cant do this on the external display?????
//    // Support iCade in external screens
//    if ( externalView != nil && icadeView != nil && ![externalView.subviews containsObject:icadeView] ) {
//        [externalView addSubview:icadeView];
//    }
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    [[UIApplication sharedApplication] setStatusBarOrientation:self.interfaceOrientation];
#endif
    
    if (self.view.bounds.size.width > self.view.bounds.size.height)
        [self buildLandscape];
    else
        [self buildPortrait];
    
    if (externalView != nil)
    {
        imageExternalDisplay = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"airplayvideo"] ?: [UIImage imageNamed:@"mame_logo"]];
        imageExternalDisplay.contentMode = UIViewContentModeScaleAspectFit;
        imageExternalDisplay.frame = g_device_is_landscape ? rFrames[LANDSCAPE_VIEW_NOT_FULL] : rFrames[PORTRAIT_VIEW_NOT_FULL];
        [self.view addSubview:imageExternalDisplay];
    }

   if (@available(iOS 11.0, *))
       [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
#elif TARGET_OS_TV
    // for tvOS, use "landscape" only
    [self buildLandscape];
#endif
    [self buildLogoView];
    [self updateScreenView];

    if ( g_joy_used ) {
        [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
    } else {
        [hideShowControlsForLightgun setImage:[UIImage imageNamed:@"dpad"] forState:UIControlStateNormal];
    }
    
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
    }
    prev_myosd_mouse = myosd_mouse;

    areControlsHidden = NO;
    
    memset(cyclesAfterButtonPressed, 0, sizeof(cyclesAfterButtonPressed));
}}

#define MAME_BUTTON_PLAYER_MASK     0xF0000000
#define MAME_BUTTON_PLAYER_SHIFT    28
NSMutableArray<NSNumber*>* g_mame_buttons;  // FIFO queue of buttons to press
NSLock* g_mame_buttons_lock;
NSInteger g_mame_buttons_tick;              // ticks until we send next one
        
static void push_mame_button(int player, int button)
{
    assert([NSThread isMainThread]);     // only add buttons from main thread
    if (g_mame_buttons == nil) {
        g_mame_buttons = [[NSMutableArray alloc] init];
        g_mame_buttons_lock = [[NSLock alloc] init];
    }
    button = button | (player << MAME_BUTTON_PLAYER_SHIFT);
    [g_mame_buttons_lock lock];
    [g_mame_buttons addObject:@(button)];
    [g_mame_buttons_lock unlock];
}
static void push_mame_buttons(int player, int button1, int button2)
{
    push_mame_button(player, button1);
    push_mame_button(player, button2);
}

// called from inside MAME droid_ios_poll_input
void myosd_handle_turbo() {

    // this is called on the MAME thread, need to be carefull and clean up!
    @autoreleasepool {
        
        // send keys - we do this inside of myosd_handle_turbo() because it is called from droid_ios_poll_input
        // ...and we are sure MAME is in a state to accept input, and not waking up from being paused or loading a ROM
        // ...we hold a key DOWN for 2 frames (buttonPressReleaseCycles) and wait (buttonNextPressCycles) frames  between keys.
        // ...these are *magic* numbers that seam to work good. if we hold a key down too long, games may ignore it. if we send too fast bad too.

        if (g_mame_buttons.count > 0) {
            
            if (g_mame_buttons_tick > 0) {
                g_mame_buttons_tick--;
                return;
            }
            
            [g_mame_buttons_lock lock];
            unsigned long button = g_mame_buttons.firstObject.intValue;
            unsigned long player = (button & MAME_BUTTON_PLAYER_MASK) >> MAME_BUTTON_PLAYER_SHIFT;
            button = button & ~MAME_BUTTON_PLAYER_MASK;
            
            if ((myosd_joy_status[player] & button) == button) {
                [g_mame_buttons removeObjectAtIndex:0];
                if (g_mame_buttons.count > 0)
                    g_mame_buttons_tick = buttonNextPressCycles;  // wait this long before next button
                myosd_joy_status[player] &= ~button;
                if (player == 0)
                    myosd_pad_status &= ~button;
            }
            else {
                g_mame_buttons_tick = buttonPressReleaseCycles;  // keep button DOWN for this long.
                myosd_joy_status[player] |= button;
                if (player == 0)
                    myosd_pad_status |= button;
            }
            [g_mame_buttons_lock unlock];
            return;
        }


        // dont do turbo mode in MAME menus.
        if (!(myosd_inGame && myosd_in_menu == 0))
            return;
        
        // also dont do turbo mode if all checks are off
        if ((turboBtnEnabled[BTN_X] | turboBtnEnabled[BTN_Y] |
             turboBtnEnabled[BTN_A] | turboBtnEnabled[BTN_B] |
             turboBtnEnabled[BTN_L1] | turboBtnEnabled[BTN_R1]) == 0) {
            return;
        }
        
        if (controllers.count > 0) {
            unsigned long mfi_button_state[NUM_JOY];
            
            // poll mfi controllers and read current state of buttons
            for (int i = 0; i < controllers.count; i++) {
                GCController *mfiController = [controllers objectAtIndex:i];
                GCExtendedGamepad *gamepad = mfiController.extendedGamepad;
                mfi_button_state[i]=(gamepad.buttonX.isPressed ? MYOSD_X : 0) |
                                    (gamepad.buttonY.isPressed ? MYOSD_Y : 0) |
                                    (gamepad.buttonA.isPressed ? MYOSD_A : 0) |
                                    (gamepad.buttonB.isPressed ? MYOSD_B : 0) |
                                    (gamepad.leftShoulder.isPressed ? MYOSD_L1 : 0) |
                                    (gamepad.rightShoulder.isPressed ? MYOSD_R1 : 0) ;
            }
            
            for (int button=0; button<NUM_BUTTONS; button++) {
                for (int i = 0; i < controllers.count; i++) {
                    if ( turboBtnEnabled[button] && (mfi_button_state[i] & buttonMask[button])) {
                        if ( cyclesAfterButtonPressed[i][button] > buttonPressReleaseCycles ) {
                            //NSLog(@"Turbo enabled! (mfi)");
                            if ( myosd_joy_status[i] & buttonMask[button]) {
                                myosd_joy_status[i] &= ~buttonMask[button];
                            } else {
                                myosd_joy_status[i] |= buttonMask[button];
                            }
                            cyclesAfterButtonPressed[i][button] = 0;
                        }
                        cyclesAfterButtonPressed[i][button]++;
                    }
                }
            }
        }
        else {
            // For the on-screen touch controlls
            for (int button=0; button<NUM_BUTTONS; button++) {
                if ( turboBtnEnabled[button] && (buttonState & buttonMask[button]) ) {
                    if ( cyclesAfterButtonPressed[0][button] > buttonPressReleaseCycles ) {
                        //NSLog(@"Turbo enabled!");
                        if ( myosd_pad_status & buttonMask[button]) {
                            myosd_pad_status &= ~buttonMask[button];
                        } else {
                            myosd_pad_status |= buttonMask[button];
                        }
                        cyclesAfterButtonPressed[0][button] = 0;
                    }
                    cyclesAfterButtonPressed[0][button]++;
                }
            }
        }
    }
}

#pragma mark - view layout

#if TARGET_OS_IOS

// show debug rects
- (void) showDebugRects {
#ifdef DEBUG
    if (g_enable_debug_view)
    {
        for (UIView* view in inputView.subviews)
        {
            view.layer.borderWidth = 1.0;
            view.layer.borderColor = [UIColor.systemYellowColor colorWithAlphaComponent:0.50].CGColor;
        }

        for (UIView* view in @[screenView, analogStickView])
        {
            view.layer.borderWidth = 1.0;
            view.layer.borderColor = [UIColor.systemYellowColor colorWithAlphaComponent:0.50].CGColor;
        }
        for (int i=0; i<INPUT_LAST_VALUE; i++)
        {
            CGRect rect = rInput[i];
            if (CGRectIsEmpty(rect))
                continue;
            if (i>=DPAD_UP_RECT && i<=DPAD_DOWN_RIGHT_RECT)
                continue;
            UILabel* label = [[UILabel alloc] initWithFrame:rect];
            label.text = [NSString stringWithFormat:@"%d", i];
            label.userInteractionEnabled = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.75];
            label.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.25];
            label.layer.borderColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.50].CGColor;
            label.layer.borderWidth = 1.0;
            [inputView addSubview:label];
        }
    }
#endif
}


- (void)removeTouchControllerViews{

    [inputView removeFromSuperview];

    inputView=nil;
    analogStickView=nil;

    for (int i=0; i<NUM_BUTTONS;i++)
      buttonViews[i] = nil;
}

- (void)buildTouchControllerViews {

    [self removeTouchControllerViews];
    
    inputView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:inputView];
    
    g_joy_used = myosd_num_of_joys!=0;
   
    // no touch controlls for fullscreen with a joystick
    if (g_joy_used && g_device_is_fullscreen)
        return;
   
    BOOL touch_dpad_disabled = (myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_dpad) ||
                               (g_pref_touch_directional_enabled && g_pref_touch_analog_hide_dpad);
    if ( !touch_dpad_disabled || !myosd_inGame ) {
        //analogStickView
        analogStickView = [[AnalogStickView alloc] initWithFrame:rStickWindow withEmuController:self];
        [inputView addSubview:analogStickView];
    }
   
    BOOL touch_buttons_disabled = myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_buttons;
    buttonState = 0;
    for (int i=0; i<NUM_BUTTONS; i++)
    {
        // hide buttons that are not used in fullscreen mode (and not laying out)
        if (g_device_is_fullscreen && !change_layout && !g_enable_debug_view)
        {
            if(i==BTN_X && (g_pref_full_num_buttons < 4 && myosd_inGame))continue;
            if(i==BTN_Y && (g_pref_full_num_buttons < 3 || !myosd_inGame))continue;
            if(i==BTN_B && (g_pref_full_num_buttons < 2 || !myosd_inGame))continue;
            if(i==BTN_A && (g_pref_full_num_buttons < 1 && myosd_inGame))continue;
            
            if(i==BTN_L1 && (g_pref_hide_LR || !myosd_inGame))continue;
            if(i==BTN_R1 && (g_pref_hide_LR || !myosd_inGame))continue;
            
            if (touch_buttons_disabled && (i != BTN_SELECT && i != BTN_START && i != BTN_L2 && i != BTN_R2 )) continue;
        }
        
        NSString *name_up = nameImgButton_NotPress[i];
        NSString *name_down = nameImgButton_Press[i];
        buttonViews[i] = [ [ UIImageView alloc ] initWithImage:[self loadImage:name_up] highlightedImage:[self loadImage:name_down]];
        buttonViews[i].frame = rButtonImages[i];
        
        if (g_device_is_fullscreen)
            [buttonViews[i] setAlpha:((float)g_controller_opacity / 100.0f)];
        
        [inputView addSubview: buttonViews[i]];
    }

    [self showDebugRects];
}
#endif

#if TARGET_OS_IOS
- (void)buildPortraitImageBack {

   if(!g_device_is_fullscreen)
   {
	   if(g_isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:@"back_portrait_iPad.png"]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:@"back_portrait_iPhone.png"]];
	   
	   imageBack.frame = rFrames[PORTRAIT_IMAGE_BACK]; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   
}


- (void)buildPortraitImageOverlay {
   
   if((g_pref_scanline_filter_port || g_pref_tv_filter_port) /*&& externalView==nil*/)
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
     
       if(g_isIpad && !g_device_is_fullscreen && externalView == nil)
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
           if (TRUE && self.view.window.screen != nil) {
               CGSize border = CGSizeMake(4.0,4.0);  // in pixels
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
            		    			
       [screenView.superview addSubview: imageOverlay];
  }
}

- (void)buildPortrait {

   g_device_is_landscape = 0;
   g_device_is_fullscreen = (g_pref_full_screen_port || (g_joy_used && g_pref_full_screen_port_joy)) && externalView == nil;
    
   [ self getControllerCoords:0 ];
    
   [ self adjustSizes];
    
   [LayoutData loadLayoutData:self];
   
   [self buildPortraitImageBack];
   
   CGRect r;
   
   if(externalView!=nil)   
   {
       r = externalView.window.screen.bounds;
       
       CGFloat overscan = (g_pref_overscanTVOUT *  0.025f);
       CGFloat overscan_x = ceil(r.size.width * overscan / 2.0);
       CGFloat overscan_y = ceil(r.size.height * overscan / 2.0);

       r = CGRectInset(r, overscan_x, overscan_y);
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
            // in fullscreen mode, we dont want to correct for the bottom inset, because we hide the home indicator.
            UIEdgeInsets safeArea = self.view.safeAreaInsets;
            if (g_device_is_fullscreen)
                safeArea.bottom = 0.0;
            r = CGRectIntersection(r, UIEdgeInsetsInsetRect(self.view.bounds, safeArea));
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
   [self buildTouchControllerViews];


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
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:@"back_landscape_iPad.png"]];
       else if (UIScreen.mainScreen.nativeBounds.size.width <= 640.0)
         imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:@"back_landscape_iPhone_5.png"]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[self loadImage:@"back_landscape_iPhone_6.png"]];
	   
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
 
   if((g_pref_scanline_filter_land || g_pref_tv_filter_land) /*&& externalView==nil*/)
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
                                         
        [screenView.superview addSubview: imageOverlay];
	  	   
    }
}

- (void)buildLandscape{
	
   g_device_is_landscape = 1;
   g_device_is_fullscreen = (g_pref_full_screen_land || (g_joy_used && g_pref_full_screen_land_joy)) && externalView == nil;

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
       r = externalView.window.screen.bounds;
       
       CGFloat overscan = (g_pref_overscanTVOUT *  0.025f);
       CGFloat overscan_x = ceil(r.size.width * overscan / 2.0);
       CGFloat overscan_y = ceil(r.size.height * overscan / 2.0);

       r = CGRectInset(r, overscan_x, overscan_y);
   }
   else if (!g_device_is_fullscreen)
   {
        r = rFrames[LANDSCAPE_VIEW_NOT_FULL];
   }     
   else
   {
        r = rFrames[LANDSCAPE_VIEW_FULL];
   }

    // Handle Safe Area (iPhone X) adjust the view down away from the notch, before adjusting for aspect
    if ( @available(iOS 11, *) ) {
        if ( externalView == nil ) {
            // in fullscreen mode, we dont want to correct for the bottom inset, because we hide the home indicator.
            UIEdgeInsets safeArea = self.view.safeAreaInsets;
            if (g_device_is_fullscreen)
                safeArea.bottom = 0.0;
            r = CGRectIntersection(r, UIEdgeInsetsInsetRect(self.view.bounds, safeArea));
        }
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
#if TARGET_OS_IOS
   [self buildTouchControllerViews];
#endif
    
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

// handle_INPUT - called when input happens on a controller, keyboard, or screen
- (void)handle_INPUT {
#if defined(DEBUG) && DebugLog
    for (int i=0; i<MAX(1, myosd_num_of_joys); i++) {
        unsigned long pad_status = myosd_joy_status[i] | (i == 0 ? myosd_pad_status : 0);
        
        NSLog(@"%s[%d]: %s%s%s%s (%+1.3f,%+1.3f) %s%s%s%s %s%s%s%s%s%s %s%s%s%s (%+1.3f,%+1.3f) (%1.3f,%1.3f) inGame=%d, inMenu=%d",
              i==0 ? "handle_INPUT" : "            ", i,
              (pad_status & MYOSD_UP) ?   "U" : "-", (pad_status & MYOSD_DOWN) ?  "D" : "-",
              (pad_status & MYOSD_LEFT) ? "L" : "-", (pad_status & MYOSD_RIGHT) ? "R" : "-",

              joy_analog_x[i][0], joy_analog_y[i][0],

              (pad_status & MYOSD_A) ? "A" : "-", (pad_status & MYOSD_B) ? "B" : "-",
              (pad_status & MYOSD_X) ? "X" : "-", (pad_status & MYOSD_Y) ? "Y" : "-",
  
              (pad_status & MYOSD_L1) ? "L1" : "--", (pad_status & MYOSD_L2) ? "L2" : "--",
              (pad_status & MYOSD_L3) ? "L3" : "--", (pad_status & MYOSD_R3) ? "R3" : "--",
              (pad_status & MYOSD_R2) ? "R2" : "--", (pad_status & MYOSD_R1) ? "R1" : "--",

              (pad_status & MYOSD_SELECT) ? "C" : "-", (pad_status & MYOSD_EXIT) ? "X" : "-",
              (pad_status & MYOSD_OPTION) ? "M" : "-", (pad_status & MYOSD_START) ? "S" : "-",

              joy_analog_x[i][1], joy_analog_y[i][1], joy_analog_x[i][2],joy_analog_x[i][3],
              
              myosd_inGame, myosd_in_menu
              );
    }
#endif

#if TARGET_OS_IOS
    // call handle_MENU first so it can use buttonState to see key up.
    [self handle_MENU];
    [self handle_DPAD];
#endif
}

#if TARGET_OS_IOS
// update the state of the on-screen buttons and dpad/stick
- (void)handle_DPAD{
    unsigned long pad_status = myosd_pad_status | myosd_joy_status[0];
    
    if (!g_pref_animated_DPad || (g_device_is_fullscreen && g_joy_used)) {
        buttonState = pad_status;
        return;
    }

    for(int i=0; i< NUM_BUTTONS; i++)
    {
        if((buttonState & buttonMask[i]) != (pad_status & buttonMask[i]))
        {
            buttonViews[i].highlighted = (pad_status & buttonMask[i]) != 0;
            
#ifdef XDEBUG
            if(pad_status & buttonMask[i])
                NSLog(@"****** BUZZ! *******: %08X %@", (int)pad_status, [nameImgButton_Press[i] stringByDeletingPathExtension]);
            else
                NSLog(@"****** BONK! *******: %08X", (int)pad_status);
#endif
            
            if(pad_status & buttonMask[i])
                [self.impactFeedback impactOccurred];
            else
                [self.selectionFeedback selectionChanged];
        }
    }
    
    buttonState = pad_status;
    
    if (analogStickView != nil && ![analogStickView isHidden])
        [analogStickView update];
}
#endif
    

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
    NSMutableSet *handledTouches = [NSMutableSet set];
    
    //Get all the touches.
    NSSet *allTouches = [event allTouches];
    NSUInteger touchcount = [allTouches count];
    
    if ( areControlsHidden && g_pref_lightgun_enabled && g_device_is_landscape) {
        [self handleLightgunTouchesBegan:touches];
        return nil;
    }

    unsigned long pad_status = 0;

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
            if(!touch_dpad_disabled )
            {
                if(MyCGRectContainsPoint(analogStickView.frame, point) || stickTouch == touch)
                {
                    stickTouch = touch;
                    stickWasTouched = YES;
                    [analogStickView analogTouches:touch withEvent:event];
                }
            }
            
            if(touch == stickTouch) continue;
            
            BOOL touch_buttons_disabled = myosd_mouse == 1 && g_pref_touch_analog_enabled && g_pref_touch_analog_hide_buttons;
            
            if (buttonViews[BTN_Y] != nil &&
                !buttonViews[BTN_Y].hidden && MyCGRectContainsPoint(rInput[BTN_Y_RECT], point) &&
                !touch_buttons_disabled) {
                pad_status |= MYOSD_Y;
                //NSLog(@"MYOSD_Y");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_X] != nil &&
                     !buttonViews[BTN_X].hidden && MyCGRectContainsPoint(rInput[BTN_X_RECT], point) &&
                     !touch_buttons_disabled) {
                pad_status |= MYOSD_X;
                //NSLog(@"MYOSD_X");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_A] != nil &&
                     !buttonViews[BTN_A].hidden && MyCGRectContainsPoint(rInput[BTN_A_RECT], point) &&
                     !touch_buttons_disabled) {
                if(g_pref_BplusX)
                    pad_status |= MYOSD_X | MYOSD_B;
                else
                    pad_status |= MYOSD_A;
                //NSLog(@"MYOSD_A");
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_B] != nil && !buttonViews[BTN_B].hidden && MyCGRectContainsPoint(rInput[BTN_B_RECT], point) &&
                     !touch_buttons_disabled) {
                pad_status |= MYOSD_B;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_B");
            }
            else if (buttonViews[BTN_A] != nil &&
                     buttonViews[BTN_Y] != nil &&
                     !buttonViews[BTN_A].hidden &&
                     !buttonViews[BTN_Y].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_A_Y_RECT], point) &&
                     !touch_buttons_disabled) {
                pad_status |= MYOSD_Y | MYOSD_A;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_Y | MYOSD_A");
            }
            else if (buttonViews[BTN_X] != nil &&
                     buttonViews[BTN_A] != nil &&
                     !buttonViews[BTN_X].hidden &&
                     !buttonViews[BTN_A].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_X_A_RECT], point) &&
                     !touch_buttons_disabled) {
                
                pad_status |= MYOSD_X | MYOSD_A;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_X | MYOSD_A");
            }
            else if (buttonViews[BTN_Y] != nil &&
                     buttonViews[BTN_B] != nil &&
                     !buttonViews[BTN_Y].hidden &&
                     !buttonViews[BTN_B].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_B_Y_RECT], point) &&
                     !touch_buttons_disabled) {
                pad_status |= MYOSD_Y | MYOSD_B;
                [handledTouches addObject:touch];
                //NSLog(@"MYOSD_Y | MYOSD_B");
            }
            else if (!buttonViews[BTN_B].hidden &&
                     !buttonViews[BTN_X].hidden &&
                     MyCGRectContainsPoint(rInput[BTN_B_X_RECT], point) &&
                     !touch_buttons_disabled) {
                if(!g_pref_BplusX /*&& g_pref_land_num_buttons>=3*/)
                {
                    pad_status |= MYOSD_X | MYOSD_B;
                    [handledTouches addObject:touch];
                }
                //NSLog(@"MYOSD_X | MYOSD_B");
            }
            else if (MyCGRectContainsPoint(rInput[BTN_SELECT_RECT], point)) {
                //NSLog(@"MYOSD_SELECT");
                pad_status |= MYOSD_SELECT;
                [handledTouches addObject:touch];
            }
            else if (MyCGRectContainsPoint(rInput[BTN_START_RECT], point)) {
                //NSLog(@"MYOSD_START");
                pad_status |= MYOSD_START;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_L1] != nil && !buttonViews[BTN_L1].hidden && MyCGRectContainsPoint(rInput[BTN_L1_RECT], point) && !touch_buttons_disabled) {
                //NSLog(@"MYOSD_L");
                pad_status |= MYOSD_L1;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_R1] != nil && !buttonViews[BTN_R1].hidden && MyCGRectContainsPoint(rInput[BTN_R1_RECT], point) && !touch_buttons_disabled ) {
                //NSLog(@"MYOSD_R");
                pad_status |= MYOSD_R1;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_EXIT] != nil && !buttonViews[BTN_EXIT].hidden && MyCGRectContainsPoint(rInput[BTN_EXIT_RECT], point)) {
                //NSLog(@"MYOSD_EXIT");
                pad_status |= MYOSD_EXIT;
                [handledTouches addObject:touch];
            }
            else if (buttonViews[BTN_OPTION] != nil && !buttonViews[BTN_OPTION].hidden && MyCGRectContainsPoint(rInput[BTN_OPTION_RECT], point) ) {
                 //NSLog(@"MYOSD_OPTION");
                 pad_status |= MYOSD_OPTION;
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
                [analogStickView analogTouches:touch withEvent:event];
                stickWasTouched = YES;
                stickTouch = nil;
            }
        }
    }
    
    // merge in the button state this way, instead of setting to zero and |=, so MAME wont see a random button flip.
    const unsigned long BUTTON_MASK = (MYOSD_A|MYOSD_B|MYOSD_X|MYOSD_Y|MYOSD_L1|MYOSD_R1|MYOSD_SELECT|MYOSD_START|MYOSD_EXIT|MYOSD_OPTION);
    myosd_pad_status = pad_status | (myosd_pad_status & ~BUTTON_MASK);

    if (buttonState != myosd_pad_status || (stickWasTouched && g_pref_input_touch_type == TOUCH_INPUT_ANALOG)) {
        [self handle_INPUT];
    }
    
//    BOOL touchWasHandled = stickTouch != nil || handledTouches.count != 0;
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
            NSLog(@"LIGHTGUN: COIN");
            push_mame_button(0, MYOSD_SELECT);
        } else if ( touchcount > 2 ) {
            // 3 touches = press start
            NSLog(@"LIGHTGUN: START");
            push_mame_button(0, MYOSD_START);
        } else if ( touchcount > 1 ) {
            // more than one touch means secondary button press
            NSLog(@"LIGHTGUN: B");
            myosd_pad_status |= MYOSD_B;
            myosd_joy_status[0] |= MYOSD_B;
            myosd_pad_status &= ~MYOSD_A;
            myosd_joy_status[0] &= ~MYOSD_A;
        } else if ( touchcount == 1 ) {
            if ( g_pref_lightgun_bottom_reload && newY < -0.80 ) {
                NSLog(@"LIGHTGUN: RELOAD");
                newY = -12.1f;
            }
            NSLog(@"LIGHTGUN: %f,%f",newX,newY);
            lightgun_x[0] = newX;
            lightgun_y[0] = newY;
            
            if (joy_analog_x[0][0] != 0 || joy_analog_y[0][0] != 0 ||
                joy_analog_x[0][1] != 0 || joy_analog_y[0][1] != 0) {
                NSLog(@"LIGHTGUN: NON ZERO JOYSTICK! (%f,%f) (%f,%f)", joy_analog_x[0][0], joy_analog_y[0][0], joy_analog_x[0][1], joy_analog_y[0][1]);
            }
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
            fp = [self loadFile:[NSString stringWithFormat:@"controller_portrait_full_%@.txt", deviceName]];
        else
            fp = [self loadFile:[NSString stringWithFormat:@"controller_portrait_%@.txt", deviceName]];
    }
	else
	{
        if (g_device_is_fullscreen)
            fp = [self loadFile:[NSString stringWithFormat:@"controller_landscape_full_%@.txt",deviceName]];
        else
            fp = [self loadFile:[NSString stringWithFormat:@"controller_landscape_%@.txt", deviceName]];
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
            case 28:   /*rDPadImage  = CGRectMake( coords[0], coords[1], coords[2], coords[3] );*/ break;
            case 29:   rButtonImages[BTN_SELECT]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 30:   rButtonImages[BTN_START]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 31:   rButtonImages[BTN_L1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 32:   rButtonImages[BTN_R1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 33:   rButtonImages[BTN_L2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 34:   rButtonImages[BTN_R2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            
            case 35:   rStickWindow = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 36:   rStickWindow = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 37:   stick_radio =coords[0]; break;            
//            case 38:   g_controller_opacity= coords[0]; break;
			}
      i++;
    }
    fclose(fp);
        
#define SWAPRECT(a,b) {CGRect t = a; a = b; b = t;}
        
    // swap A and B, swap X and Y
    if(g_pref_nintendoBAYX)
    {
        SWAPRECT(rButtonImages[BTN_A], rButtonImages[BTN_B]);
        SWAPRECT(rButtonImages[BTN_X], rButtonImages[BTN_Y]);

        SWAPRECT(rInput[BTN_A_RECT], rInput[BTN_B_RECT]);
        SWAPRECT(rInput[BTN_X_RECT], rInput[BTN_Y_RECT]);

        SWAPRECT(rInput[BTN_X_A_RECT], rInput[BTN_B_Y_RECT]);
        SWAPRECT(rInput[BTN_A_Y_RECT], rInput[BTN_B_X_RECT]);
    }
    
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
    
    FILE *fp = [self loadFile:[NSString stringWithUTF8String:config]];

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
                    
                    //case 8:    g_enable_debug_view = coords[0]; break;
                    //case 9:    main_thread_priority_type = coords[0]; break;
                    //case 10:   video_thread_priority_type = coords[0]; break;
            }
            i++;
        }
        fclose(fp);
    }
#endif
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
    
    path = [NSString stringWithUTF8String:get_resource_path("")];
    img = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:name]];
    
    if (img == nil)
    {
        name = [NSString stringWithFormat:@"SKIN_%d/%@", g_pref_skin, name];
        img = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:name]];
    }

    [g_image_cache setObject:(img ?: [NSNull null]) forKey:name];
    return img;
}


-(FILE *)loadFile:(NSString*)name {
    NSString *path = nil;
    FILE *fp;
    
    path = [NSString stringWithUTF8String:get_resource_path("")];
    fp = fopen([path stringByAppendingPathComponent:name].UTF8String, "r");

    if(!fp)
    {
        name = [NSString stringWithFormat:@"SKIN_%d/%@", g_pref_skin, name];
        fp = fopen([path stringByAppendingPathComponent:name].UTF8String, "r");
    }
    
    return fp;
}

// move a single ZIP file from the document root into where it belongs.
//
// we handle three kinds of ZIP files...
//
//  * zipset, if the ZIP contains other ZIP files, then it is a zip of romsets, aka zipset?.
//  * chdset, if the ZIP has CHDs in it, unzip and place in roms folder.
//  * artwork, if the ZIP contains a .LAY file, then it is artwork
//  * romset, if the ZIP has "normal" files in it assume it is a romset.
//
//  because we are registered to open *any* zip file, we also verify that a romset looks
//  valid, we dont want to copy "Funny Cat Pictures.zip" to our roms directory, no one wants that.
//  a valid romset must be a short <= 20 name with no spaces.
//
//  we will move a artwork zip file to the artwork directory
//  we will move a romset zip file to the roms directory
//  we will unzip (in place) a zipset or chdset
//
-(BOOL)moveROM:(NSString*)romName progressBlock:(void (^)(double progress))block {

    if (![[romName.pathExtension uppercaseString] isEqualToString:@"ZIP"])
        return FALSE;
    
    NSError *error = nil;

    NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
    NSString *romsPath = [NSString stringWithUTF8String:get_documents_path("roms")];
    NSString *artwPath = [NSString stringWithUTF8String:get_documents_path("artwork")];
    NSString *sampPath = [NSString stringWithUTF8String:get_documents_path("samples")];
    NSString *datsPath = [NSString stringWithUTF8String:get_documents_path("dats")];

    NSString *romPath = [rootPath stringByAppendingPathComponent:romName];
    
    // if the ROM had a name like "foobar 1.zip", "foobar (1).zip" use only the first word as the ROM name.
    // this most likley came when a user downloaded the zip and a foobar.zip already existed, MAME ROMs are <=20 char and no spaces.
    NSArray* words = [[romName stringByDeletingPathExtension] componentsSeparatedByString:@" "];
    if (words.count == 2 && [words.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]].intValue != 0)
        romName = [words.firstObject stringByAppendingPathExtension:@"zip"];

    NSLog(@"ROM NAME: '%@' PATH:%@", romName, romPath);

    //
    // scan the ZIP file to see what kind it is.
    //
    //  * zipset, if the ZIP contains other ZIP files, then it is a zip of romsets, aka zipset?.
    //  * chdset, if the ZIP has CHDs in it.
    //  * datset, if the ZIP has DATs in it. *NOTE* many ROMSETs have .DAT files, so we only check a whitelist of files.
    //  * artwork, if the ZIP contains a .LAY file, then it is artwork
    //  * samples, if the ZIP contains a .WAV file, then it is samples
    //  * romset, if the ZIP has "normal" files in it assume it is a romset.
    //

    // whitelist of valid .DAT files we will copy to the dats folder
    NSArray* dat_files = @[@"HISTORY.DAT", @"MAMEINFO.DAT"];
    
    int __block numLAY = 0;
    int __block numZIP = 0;
    int __block numCHD = 0;
    int __block numWAV = 0;
    int __block numDAT = 0;
    int __block numFiles = 0;
    BOOL result = [ZipFile enumerate:romPath withOptions:ZipFileEnumFiles usingBlock:^(ZipFileInfo* info) {
        NSString* ext = [info.name.pathExtension uppercaseString];
        numFiles++;
        if ([ext isEqualToString:@"LAY"])
            numLAY++;
        if ([ext isEqualToString:@"ZIP"])
            numZIP++;
        if ([ext isEqualToString:@"WAV"])
            numWAV++;
        if ([ext isEqualToString:@"CHD"])
            numCHD++;
        if ([dat_files containsObject:info.name.lastPathComponent.uppercaseString])
            numDAT++;
    }];

    NSString* toPath = nil;

    if (!result)
    {
        NSLog(@"%@ is a CORRUPT ZIP (deleting)", romPath);
    }
    else if (numZIP != 0 || numCHD != 0 || numDAT != 0)
    {
        NSLog(@"%@ is a ZIPSET", [romPath lastPathComponent]);
        int maxFiles = numFiles;
        numFiles = 0;
        [ZipFile enumerate:romPath withOptions:(ZipFileEnumFiles + ZipFileEnumLoadData) usingBlock:^(ZipFileInfo* info) {
            
            if (info.data == nil)
                return;
            
            NSString* toPath = nil;
            NSString* ext  = info.name.pathExtension.uppercaseString;
            NSString* name = info.name.lastPathComponent;
            
            // only UNZIP files to specific directories, send a ZIP file with a unspecifed directory to roms/
            if ([info.name hasPrefix:@"roms/"] || [info.name hasPrefix:@"artwork/"] || [info.name hasPrefix:@"titles/"] || [info.name hasPrefix:@"samples/"] ||
                [info.name hasPrefix:@"cfg/"] || [info.name hasPrefix:@"ini/"] || [info.name hasPrefix:@"sta/"] || [info.name hasPrefix:@"hi/"])
                toPath = [rootPath stringByAppendingPathComponent:info.name];
            else if ([name.uppercaseString isEqualToString:@"CHEAT.ZIP"])
                toPath = [rootPath stringByAppendingPathComponent:name];
            else if ([ext isEqualToString:@"DAT"])
                toPath = [datsPath stringByAppendingPathComponent:name];
            else if ([ext isEqualToString:@"ZIP"])
                toPath = [romsPath stringByAppendingPathComponent:name];
            else if ([ext isEqualToString:@"CHD"] && [info.name containsString:@"/"]) {
                // CHD will be of the form XXXXXXX/ROMNAME/file.chd, so move to roms/ROMNAME/file.chd
                NSString* romname = info.name.stringByDeletingLastPathComponent.lastPathComponent;
                toPath = [[romsPath stringByAppendingPathComponent:romname] stringByAppendingPathComponent:info.name.lastPathComponent];
            }

            if (toPath != nil)
                NSLog(@"...UNZIP: %@ => %@", info.name, toPath);
            else
                NSLog(@"...UNZIP: %@ (ignoring)", info.name);

            if (toPath != nil)
            {
                if (![info.data writeToFile:toPath atomically:YES])
                {
                    NSLog(@"ERROR UNZIPing %@ (trying to create directory)", info.name);
                    
                    if (![NSFileManager.defaultManager createDirectoryAtPath:[toPath stringByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:nil])
                        NSLog(@"ERROR CREATING DIRECTORY: %@", [info.name stringByDeletingLastPathComponent]);

                    if (![info.data writeToFile:toPath atomically:YES])
                        NSLog(@"ERROR UNZIPing %@", info.name);
                }
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
    else if ([romName length] <= 20 && ![romName containsString:@" "])
    {
        NSLog(@"%@ is a ROMSET", romName);
        toPath = [romsPath stringByAppendingPathComponent:romName];
    }
    else
    {
        NSLog(@"%@ is a NOT a ROMSET (deleting)", romName);
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
    }
    else
    {
        NSLog(@"DELETE: %@", romPath);
        [[NSFileManager defaultManager] removeItemAtPath:romPath error:nil];
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
        UIViewController* topViewController = self.topViewController;

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
                    
                    // reset MAME last game selected...
                    if (result)
                       myosd_last_game_selected = 0;

                    // reload the MAME menu....
                    if (result)
                        [self performSelectorOnMainThread:@selector(playGame:) withObject:nil waitUntilDone:NO];
                    
                    g_move_roms = 0;
                }];
            });
        });
    }
}

// ZIP up all the important files in our documents directory
// TODO: maybe we should also export the settings.bin or the UserDefaults plist
// NOTE we specificaly *dont* export CHDs because they are too big, we support importing CHDs just not exporting
-(BOOL)saveROMS:(NSURL*)url progressBlock:(BOOL (^)(double progress))block {

    NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
    NSString *romsPath = [NSString stringWithUTF8String:get_documents_path("roms")];

    NSMutableArray* files = [[NSMutableArray alloc] init];

    NSArray* roms = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:romsPath error:nil];
    for (NSString* rom in roms) {
        NSString* ext = [rom.pathExtension uppercaseString];
        
        if (![ext isEqualToString:@"ZIP"])
            continue;
        
        NSArray* paths = @[@"roms/%@.zip", @"artwork/%@.zip", @"titles/%@.png", @"samples/%@.zip", @"cfg/%@.cfg", @"ini/%@.ini", @"sta/%@/1.sta", @"sta/%@/2.sta", @"hi/%@.hi"];
        for (NSString* path in paths) {
            [files addObject:[NSString stringWithFormat:path, [rom stringByDeletingPathExtension]]];
        }
    }
    
    NSLog(@"saveROMS: ROMS: %@", roms);
    NSLog(@"saveROMS: FILES: %@", files);
    
    return [ZipFile exportTo:url.path fromDirectory:rootPath withFiles:files withOptions:(ZipFileWriteFiles | ZipFileWriteAtomic | ZipFileWriteNoCompress) progressBlock:block];
}

#pragma mark - IMPORT and EXPORT

#if TARGET_OS_IOS
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"IMPORT CANCELED");
    [self performSelectorOnMainThread:@selector(playGame:) withObject:nil waitUntilDone:NO];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls {
    UIApplication* application = UIApplication.sharedApplication;
    for (NSURL* url in urls) {
        NSLog(@"IMPORT: %@", url);
        // call our own openURL handler (in Bootstrapper)
        [application.delegate application:application openURL:url options:@{UIApplicationOpenURLOptionsOpenInPlaceKey:@(NO)}];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(moveROMS) object:nil];
    }
    [self performSelectorOnMainThread:@selector(moveROMS) withObject:nil waitUntilDone:NO];
}

- (void)runImport {
    UIDocumentPickerViewController* documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.zip-archive"] inMode:UIDocumentPickerModeImport];
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    documentPicker.delegate = self;
    documentPicker.allowsMultipleSelection = YES;
    [self.topViewController presentViewController:documentPicker animated:YES completion:nil];
}

- (void)runExport {
    
    FileItemProvider* item = [[FileItemProvider alloc] initWithTitle:@"MAME4iOS (export)" typeIdentifier:@"public.zip-archive" saveHandler:^BOOL(NSURL* url, FileItemProviderProgressHandler progressHandler) {
        return [self saveROMS:url progressBlock:progressHandler];
    }];
    
    // NOTE UIActivityViewController is kind of broken in the Simulator, if you find a crash or problem verify it on a real device.
    UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:nil];
    
    UIViewController* top = self.topViewController;

    if (activity.popoverPresentationController != nil) {
        activity.popoverPresentationController.sourceView = top.view;
        activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);
        activity.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    [top presentViewController:activity animated:YES completion:nil];
}
#endif

- (void)runServer {
    [[WebServer sharedInstance] startUploader];
    [WebServer sharedInstance].webUploader.delegate = self;
}

#pragma mark - RESET

- (void)runReset {
    NSLog(@"RESET: %s", g_mame_game);
    
    NSString* msg = [NSString stringWithFormat:@"Reset %@ back to factory defaults?",
            TARGET_OS_IOS ? @"MAME4iOS" : @"MAME4tvOS"];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
        [Options resetOptions];
        [ChooseGameController reset];
        g_mame_reset = TRUE;
        [self done:self];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self.topViewController presentViewController:alert animated:YES completion:nil];
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
        
        if (g_pref_input_touch_type == TOUCH_INPUT_DPAD)
            g_pref_input_touch_type = TOUCH_INPUT_DSTICK;

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

// scale a CGRect but dont move the center
CGRect scale_rect(CGRect rect, CGFloat scale) {
    return CGRectInset(rect, -0.5 * rect.size.width * (scale - 1.0), -0.5 * rect.size.height * (scale - 1.0));
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
           rInput[i] = scale_rect(rInput[i], g_buttons_size);
        }
    }
    
    for(i=0;i<NUM_BUTTONS;i++)
    {
        if(i==BTN_A || i==BTN_B || i==BTN_X || i==BTN_Y || i==BTN_R1 || i==BTN_L1)
        {
            rButtonImages[i] = scale_rect(rButtonImages[i], g_buttons_size);
        }
    }
    
    if (g_device_is_fullscreen)
    {
       rStickWindow = scale_rect(rStickWindow, g_buttons_size);
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
    
    // add all the controllers with a extendedGamepad profile first
    for (GCController* controler in GCController.controllers) {
#if TARGET_IPHONE_SIMULATOR // ignore the bogus controller in the simulator
        if ([controler.vendorName isEqualToString:@"Generic Controller"])
            continue;
#endif
        if (controler.extendedGamepad != nil)
            [controllers addObject:controler];
    }
    
    // now add any Steam Controllers, these should always have a extendedGamepad profile
    for (GCController* controler in SteamControllerManager.sharedManager.controllers) {
        if (controler.extendedGamepad != nil)
            [controllers addObject:controler];
    }

    // add all the controllers without a extendedGamepad profile last, ie the Siri Remote.
    for (GCController* controler in GCController.controllers) {
        if (controler.extendedGamepad == nil)
            [controllers addObject:controler];
    }

    if (controllers.count > NUM_JOY) {
        [controllers removeObjectsInRange:NSMakeRange(NUM_JOY,controllers.count - NUM_JOY)];
    }
    
    if (controllers.count != myosd_num_of_joys) {
        myosd_num_of_joys = (int)controllers.count;
        g_joy_used = (myosd_num_of_joys != 0);
        [self changeUI];
    }

    for (int index = 0; index < controllers.count; index++) {

        GCController *MFIController = [controllers objectAtIndex:index];
        
        [MFIController setPlayerIndex:GCControllerPlayerIndexUnset];
        [MFIController setPlayerIndex:index];
        
        NSLog(@" PlayerIndex: %li", (long)MFIController.playerIndex);
        
        BOOL isSiriRemote = (MFIController.extendedGamepad == nil && MFIController.microGamepad != nil);
        
        MFIController.extendedGamepad.dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            //NSLog(@"%d: %@", index, directionpad);
            
            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.

            unsigned long dpad_status = myosd_joy_status[player];
            
            if (directionpad.up.pressed)
                myosd_joy_status[player] |= MYOSD_UP;
            else
                myosd_joy_status[player] &= ~MYOSD_UP;
            
            if (directionpad.down.pressed)
                myosd_joy_status[player] |= MYOSD_DOWN;
            else
                myosd_joy_status[player] &= ~MYOSD_DOWN;

            if (directionpad.left.pressed)
                myosd_joy_status[player] |= MYOSD_LEFT;
            else
                myosd_joy_status[player] &= ~MYOSD_LEFT;

            if (directionpad.right.pressed)
                myosd_joy_status[player] |= MYOSD_RIGHT;
            else
                myosd_joy_status[player] &= ~MYOSD_RIGHT;
            
            if (dpad_status != myosd_joy_status[player])
                [self handle_INPUT];
        };
        
        //
        // handle a MENU BUTTON modifier
        //
        //      MENU    = MAME4iOS MENU
        //      MENU+L1 = Pn COIN/SELECT
        //      MENU+R1 = Pn START
        //      MENU+L2 = P2 COIN/SELECT
        //      MENU+R2 = P2 START
        //      MENU+X  = EXIT
        //      MENU+B  = MAME MENU
        //      MENU+A  = LOAD STATE
        //      MENU+Y  = SAVE STATE
        //
        //      OPTION   = COIN + START
        //
        BOOL (^menuButtonHandler)(BOOL) = ^BOOL(BOOL pressed){
            static int g_menu_modifier_button_pressed[NUM_JOY];
            int player = (isSiriRemote || index >= myosd_num_inputs) ? 0 : index; // siri remote is always player 1

            NSLog(@"menuButtonHandler[%d]: %s", player, pressed ? "DOWN" : "UP");
#if TARGET_OS_TV
            // disable button presses while alert is shown
            if ([self controllerUserInteractionEnabled]) {
                return FALSE;
            }
#endif
            // on MENU button up, if no modifier was pressed then show menu
            if (!pressed) {
                BOOL result = g_menu_modifier_button_pressed[player] == FALSE;
                g_menu_modifier_button_pressed[player] = FALSE;  // reset for next time.
                return result;
            }

             // Add Coin
             if (MFIController.extendedGamepad.leftShoulder.pressed) {
                 NSLog(@"%d: MENU+L1 => COIN", player);
                 myosd_joy_status[player] &= ~MYOSD_L1;
                 push_mame_button((player < myosd_num_coins ? player : 0), MYOSD_SELECT);  // Player X coin
             }
             // Start
             else if (MFIController.extendedGamepad.rightShoulder.pressed) {
                 NSLog(@"%d: MENU+R1 => START", player);
                 myosd_joy_status[player] &= ~MYOSD_R1;
                 push_mame_button(player, MYOSD_START);
             }
            // Add P2 Coin
            else if (MFIController.extendedGamepad.leftTrigger.value == 1.0) {
                NSLog(@"%d: MENU+L2 => P2 COIN", player);
                myosd_joy_status[player] &= ~MYOSD_L2;
                push_mame_button((player < myosd_num_coins ? player : 0), MYOSD_SELECT);  // Player X coin
                push_mame_button((1 < myosd_num_coins ? 1 : 0), MYOSD_SELECT);  // Player 2 coin
            }
            // P2 Start
            else if (MFIController.extendedGamepad.rightTrigger.value == 1.0) {
                NSLog(@"%d: MENU+R1 => P2 START", player);
                myosd_joy_status[player] &= ~MYOSD_R2;
                push_mame_button(1, MYOSD_START);
            }
             //Show Mame menu
             else if (MFIController.extendedGamepad.buttonB.pressed) {
                 NSLog(@"%d: MENU+B => MAME MENU", player);
                 myosd_joy_status[player] &= ~MYOSD_B;
                 myosd_configure = 1;
             }
             //Exit Game
             else if (MFIController.extendedGamepad.buttonX.pressed) {
                 NSLog(@"%d: MENU+X => EXIT", player);
                 myosd_joy_status[player] &= ~MYOSD_X;
                 [self runExit];
             }
             // Load State
             else if (MFIController.extendedGamepad.buttonA.pressed ) {
                 NSLog(@"%d: MENU+A => LOAD STATE", player);
                 [self runLoadState];
             }
             // Save State
             else if (MFIController.extendedGamepad.buttonY.pressed ) {
                 NSLog(@"%d: MENU+Y => SAVE STATE", player);
                 [self runSaveState];
             }
             else {
                 return FALSE;
             }
             g_menu_modifier_button_pressed[player] = TRUE;
             return FALSE;
        };
        
        MFIController.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
            //NSLog(@"valueChangedHandler[%d]: %@ %s", index, element, ([element isKindOfClass:[GCControllerButtonInput class]] && [(GCControllerButtonInput*)element isPressed]) ? "PRESSED" : "");

            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.
            
#if TARGET_OS_TV
            // disable button presses while alert is shown
            if ([self controllerUserInteractionEnabled]) {
                return;
            }
#endif
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wpartial-availability"
            GCControllerButtonInput *buttonMenu = [gamepad respondsToSelector:@selector(buttonMenu)] ? [gamepad buttonMenu] : nil;
            GCControllerButtonInput *buttonOptions = [gamepad respondsToSelector:@selector(buttonOptions)] ? [gamepad buttonOptions] : nil;
            if ((element != buttonMenu && buttonMenu.pressed) || (element != buttonOptions && buttonOptions.pressed)) {
                menuButtonHandler(TRUE);
                return;
            }
            #pragma clang diagnostic pop

            unsigned long dpad_status = myosd_joy_status[player];
            
            if (gamepad.buttonA.pressed)
                myosd_joy_status[player] |= MYOSD_A;
            else
                myosd_joy_status[player] &= ~MYOSD_A;
            
            if (gamepad.buttonB.pressed)
                myosd_joy_status[player] |= MYOSD_B;
            else
                myosd_joy_status[player] &= ~MYOSD_B;

            if (gamepad.buttonX.pressed)
                myosd_joy_status[player] |= MYOSD_X;
            else
                myosd_joy_status[player] &= ~MYOSD_X;
        
            if (gamepad.buttonY.pressed)
                myosd_joy_status[player] |= MYOSD_Y;
            else
                myosd_joy_status[player] &= ~MYOSD_Y;

            if (gamepad.leftShoulder.pressed)
                myosd_joy_status[player] |= MYOSD_L1;
            else
                myosd_joy_status[player] &= ~MYOSD_L1;
    
            if (gamepad.rightShoulder.pressed)
                myosd_joy_status[player] |= MYOSD_R1;
            else
                myosd_joy_status[player] &= ~MYOSD_R1;
            
            joy_analog_x[player][2] = gamepad.leftTrigger.value;
            if (gamepad.leftTrigger.pressed)
                myosd_joy_status[player] |= MYOSD_L2;
            else
                myosd_joy_status[player] &= ~MYOSD_L2;

            joy_analog_x[player][3] = gamepad.rightTrigger.value;
            if (gamepad.rightTrigger.pressed)
                myosd_joy_status[player] |= MYOSD_R2;
            else
                myosd_joy_status[player] &= ~MYOSD_R2;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120100 || __TV_OS_VERSION_MAX_ALLOWED >= 120100
            if (@available(iOS 12.1, *)) {
                if (gamepad.leftThumbstickButton.pressed)
                    myosd_joy_status[player] |= MYOSD_L3;
                else
                    myosd_joy_status[player] &= ~MYOSD_L3;
                
                if (gamepad.rightThumbstickButton.pressed)
                    myosd_joy_status[player] |= MYOSD_R3;
                else
                    myosd_joy_status[player] &= ~MYOSD_R3;
            }
#endif
            if (dpad_status != myosd_joy_status[player] || (element == gamepad.leftThumbstick && !g_device_is_fullscreen))
                [self handle_INPUT];
#ifdef DEBUG
            else if (element == gamepad.leftThumbstick || element == gamepad.rightThumbstick || element == gamepad.rightTrigger || element == gamepad.leftTrigger)
                [self handle_INPUT];
#endif
        };
        
        //
        // handle a siri remote, it only has a A,X,MENU button plus a dpad
        //
        if (isSiriRemote) {

            MFIController.microGamepad.allowsRotation = YES;
            MFIController.microGamepad.reportsAbsoluteDpadValues = YES;

            MFIController.microGamepad.valueChangedHandler = ^(GCMicroGamepad* gamepad, GCControllerElement* element) {
#if TARGET_OS_TV
                // disable button presses while alert is shown
                if ([self controllerUserInteractionEnabled]) {
                    return;
                }
#endif
                int player = 0; // siri remote is always player 1
                NSLog(@"%d(%d): %@", index, player, element);
                // in iOS 13.4 sometimes we get passed the wrong gamepad???
                if (gamepad != ((GCController*)controllers[index]).microGamepad) {
                    NSLog(@"WTF! %8@ != %8@", gamepad, ((GCController*)controllers[index]).microGamepad);
                    gamepad = ((GCController*)controllers[index]).microGamepad;
                }
                if (gamepad.buttonA.pressed)
                    myosd_joy_status[player] |= MYOSD_A;
                else
                    myosd_joy_status[player] &= ~MYOSD_A;
                
                if (gamepad.buttonX.pressed)
                    myosd_joy_status[player] |= MYOSD_X;
                else
                    myosd_joy_status[player] &= ~MYOSD_X;
            };
            MFIController.microGamepad.dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
                NSInteger player = 0; // siri remote is always player 1

                //NSLog(@"%d(%d): %@", index, (int)player, directionpad);
                
                // emulate a analog joystick and a dpad, except when in a menu only a dpad
                if (myosd_inGame && !myosd_in_menu) {
                    joy_analog_x[player][0] = directionpad.xAxis.value;
                    if (STICK2WAY)
                        joy_analog_y[player][0] = 0.0;
                    else
                        joy_analog_y[player][0] = directionpad.yAxis.value;
                }
                else {
                    joy_analog_x[player][0] = 0.0;
                    joy_analog_y[player][0] = 0.0;
                }

                if (directionpad.up.pressed) {
                    myosd_joy_status[player] |= MYOSD_UP;
                }
                else {
                    myosd_joy_status[player] &= ~MYOSD_UP;
                }
                if (directionpad.down.pressed) {
                    myosd_joy_status[player] |= MYOSD_DOWN;
                }
                else {
                    myosd_joy_status[player] &= ~MYOSD_DOWN;
                }
                if (directionpad.left.pressed) {
                    myosd_joy_status[player] |= MYOSD_LEFT;
                }
                else {
                    myosd_joy_status[player] &= ~MYOSD_LEFT;
                }
                if (directionpad.right.pressed) {
                    myosd_joy_status[player] |= MYOSD_RIGHT;
                }
                else {
                    myosd_joy_status[player] &= ~MYOSD_RIGHT;
                }
                
                if (STICK2WAY) {
                     myosd_joy_status[player] &= ~(MYOSD_UP | MYOSD_DOWN);
                }
                else if (STICK4WAY) {
                    if (fabs(directionpad.yAxis.value) > fabs(directionpad.xAxis.value))
                        myosd_joy_status[player] &= ~(MYOSD_LEFT|MYOSD_RIGHT);
                    else
                        myosd_joy_status[player] &= ~(MYOSD_DOWN|MYOSD_UP);
                }
            };
        }
        
        MFIController.extendedGamepad.leftThumbstick.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            float deadZone = [self getDeadZone];
            
            //NSLog(@"%d: %@", index, directionpad);
            
            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.

            if (xValue < -deadZone)
                joy_analog_x[player][0] = xValue;
            if (xValue > deadZone)
                joy_analog_x[player][0] = xValue;
            if ( xValue <= deadZone && xValue >= -deadZone )
                joy_analog_x[player][0] = 0.0f;
            if (yValue > deadZone)
                joy_analog_y[player][0] = yValue;
            if (yValue < -deadZone)
                joy_analog_y[player][0] = yValue;
            if ( yValue <= deadZone && yValue >= -deadZone )
                joy_analog_y[player][0] = 0.0f;
        };
        
        MFIController.extendedGamepad.rightThumbstick.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad, float xValue, float yValue) {
            
            float deadZone = [self getDeadZone];
            
            //NSLog(@"%d: %@", index, directionpad);
            
            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.

            if (xValue < -deadZone)
                joy_analog_x[player][1] = xValue;
            if (xValue > deadZone)
                joy_analog_x[player][1] = xValue;
            if ( xValue <= deadZone && xValue >= -deadZone )
                joy_analog_x[player][1] = 0.0f;
            if (yValue > deadZone)
                joy_analog_y[player][1] = yValue;
            if (yValue < -deadZone)
                joy_analog_y[player][1] = yValue;
            if ( yValue <= deadZone && yValue >= -deadZone )
                joy_analog_y[player][1] = 0.0f;
        };
        
        // install handlers for MENU and OPTION buttons, if the controller has neither, insall a old skoool pause handler.
        id gamepad = MFIController.extendedGamepad ?: MFIController.microGamepad;
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wpartial-availability"
        GCControllerButtonInput *buttonMenu = [gamepad respondsToSelector:@selector(buttonMenu)] ? [gamepad buttonMenu] : nil;
        GCControllerButtonInput *buttonOptions = [gamepad respondsToSelector:@selector(buttonOptions)] ? [gamepad buttonOptions] : nil;
        #pragma clang diagnostic pop

        // MENU BUTTON
        buttonMenu.pressedChangedHandler = ^(GCControllerButtonInput* button, float value, BOOL pressed) {
            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.
            if (menuButtonHandler(pressed))
                [self toggleMenu:player];
        };
        
        // OPTION BUTTON
        buttonOptions.pressedChangedHandler = ^(GCControllerButtonInput* button, float value, BOOL pressed) {
            int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.
            if (menuButtonHandler(pressed)) {
                NSLog(@"%d: OPTIONS", index);
                // Insert a few COINs, then do a START
                push_mame_button(0, MYOSD_SELECT);  // Player 1 coin
                push_mame_button((player < myosd_num_coins ? player : 0), MYOSD_SELECT);  // Player X COIN
                push_mame_button(player, MYOSD_START); // Player X START
            }
        };
        
        // old skoool PAUSE button
        if (buttonMenu == nil && buttonOptions == nil) {
            MFIController.controllerPausedHandler = ^(GCController *controller) {
                int player = (index < myosd_num_inputs) ? index : 0; // act as Player 1 if MAME is not using us.
                menuButtonHandler(TRUE);
                if (menuButtonHandler(FALSE))
                    [self toggleMenu:player];
            };
        }
    }
}

-(void)scanForDevices{
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
    [[SteamControllerManager sharedManager] scanForControllers];
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
        [self.view makeToast:[NSString stringWithFormat:@"%@ connected", controller.vendorName] duration:4.0 position:CSToastPositionTop style:toastStyle];
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
    [self.view makeToast:[NSString stringWithFormat:@"%@ disconnected", controller.vendorName] duration:4.0 position:CSToastPositionTop style:toastStyle];
#endif
}

#pragma mark GCDWebServerDelegate
- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server {
    // dont bring up this WebServer alert multiple times, for example the server will stop and restart when app goes into background.
    static BOOL g_web_server_alert = FALSE;
    
    if (g_web_server_alert)
        return;
    
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
#else
    NSString* welcome = @"Welcome to MAME4iOS";
#endif
    NSString* message = [NSString stringWithFormat:@"\nTo transfer ROMs from your computer go to one of these addresses in your web browser:\n\n%@",servers];
    NSString* title = g_no_roms_found ? welcome : @"Web Server Started";
    NSString* done  = g_no_roms_found ? @"Reload ROMs" : @"Stop Server";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:done style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        g_web_server_alert = FALSE;
        [[WebServer sharedInstance] webUploader].delegate = nil;
        [[WebServer sharedInstance] stopUploader];
        if (!myosd_inGame)
            myosd_exitGame = 1;     /* exit mame menu and re-scan ROMs*/
    }]];
    alert.preferredAction = alert.actions.lastObject;
    g_web_server_alert = TRUE;
    [self.topViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark play GAME

// this is called a few ways
//    -- after the user has selected a game in the ChooseGame UI
//    -- if a NSUserActivity is restored
//    -- if a mame4ios: URL is opened.
//    -- called from moveROMs (with nil) to reload the gameList.
//
// NOTE we cant run a game in all situations, for example if the user is deep
// into the Settings dialog, we just give up, to complex to try to back out.
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
    //      if the alert has a cancel button (or single default) dismiss and then run game....
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
    else if ([viewController isKindOfClass:[ChooseGameController class]] && viewController.presentedViewController == nil) {
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
        [self updateUserActivity:game];
    }
    else {
        g_mame_game[0] = 0;     // run the MENU
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
#if TARGET_OS_IOS
        NSLog(@"NO GAMES, ASK USER WHAT TO DO....");

        NSString* title = @"Welcome to MAME4iOS";
        NSString* message = @"\nTo transfer ROMs from your computer, Start Server, Import ROMs, or use AirDrop.";
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Start Server" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle"] handler:^(UIAlertAction * _Nonnull action) {
            [self runServer];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Import ROMs" style:UIAlertActionStyleDefault image:[UIImage systemImageNamed:@"square.and.arrow.down"] handler:^(UIAlertAction * _Nonnull action) {
            [self runImport];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Reload ROMs" style:UIAlertActionStyleCancel image:[UIImage systemImageNamed:@"arrow.2.circlepath.circle"] handler:^(UIAlertAction * _Nonnull action) {
            myosd_exitGame = 1;     /* exit mame menu and re-scan ROMs*/
        }]];
        [self.topViewController presentViewController:alert animated:YES completion:nil];
#else
        NSLog(@"NO GAMES, START SERVER....");
        [self runServer];
#endif
        return;
    }
    if (g_mame_game_error[0] != 0) {
        NSLog(@"ERROR RUNNING GAME %s", g_mame_game_error);
        
        NSString* msg = [NSString stringWithFormat:@"ERROR RUNNING GAME %s", g_mame_game_error];
        g_mame_game_error[0] = 0;
        g_mame_game[0] = 0;
        
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

-(void)updateUserActivity:(NSDictionary*)game
{
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
