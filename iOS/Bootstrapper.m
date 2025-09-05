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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "Bootstrapper.h"
#import "Globals.h"
#import "libmame.h"     // to get the MAME version
#import "GameInfo.h"

#import "EmulatorController.h"
#import <GameController/GameController.h>
#import "Alert.h"
#import "ZipFile.h"

#include <sys/stat.h>

const char* get_resource_path(const char* file)
{
    static char resource_path[1024];
    sprintf(resource_path, "%s/%s", NSBundle.mainBundle.resourcePath.UTF8String, file);
    return resource_path;
}

const char* get_documents_path(const char* file)
{
    static char documents_path[1024];
    
#if TARGET_OS_IOS
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
#elif TARGET_OS_TV
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    sprintf(documents_path, "%s/%s",path.UTF8String, file);

    return documents_path;
}

// versions of get_resource_path and get_documents_path that take (gasp!) an NSString*
NSString* getResourcePath(NSString* str)
{
    return @(get_resource_path(str.UTF8String));
}
NSString* getDocumentPath(NSString* str)
{
    return @(get_documents_path(str.UTF8String));
}


@implementation Bootstrapper

- (BOOL)extract:(NSString*)path to:(NSString*)dir {
    NSParameterAssert([NSFileManager.defaultManager fileExistsAtPath:path]);
    return [ZipFile enumerate:path withOptions:(ZipFileEnumFiles + ZipFileEnumLoadData) usingBlock:^(ZipFileInfo* info) {
        // zip file should not have directory names, check for that in DEBUG
        NSParameterAssert(![info.name.pathComponents.firstObject isEqualToString:dir.lastPathComponent]);
        NSString* toPath = [dir stringByAppendingPathComponent:info.name];
        [NSFileManager.defaultManager createDirectoryAtPath:[toPath stringByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:nil];
        [info.data writeToFile:toPath atomically:YES];
    }];
}

static NSComparisonResult compare_file_dates(NSString* file1, NSString* file2) {
    NSDate* date1 = [[NSFileManager.defaultManager attributesOfItemAtPath:file1 error:nil] fileModificationDate] ?: NSDate.distantPast;
    NSDate* date2 = [[NSFileManager.defaultManager attributesOfItemAtPath:file2 error:nil] fileModificationDate] ?: NSDate.distantPast;
    return [date1 compare:date2];
}

NSArray* g_import_file_types;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    
    chdir (get_documents_path(""));
    
    // read our own Info.plist to get the file types we can import.
    NSArray* arr = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
    g_import_file_types = [arr valueForKeyPath:@"CFBundleTypeExtensions.@unionOfArrays.self"];
    NSParameterAssert([g_import_file_types containsObject:@"zip"]);
    
    // create directories
    for (NSString* dir in MAME_ROOT_DIRS)
    {
        NSString* dirPath = [NSString stringWithUTF8String:get_documents_path(dir.UTF8String)];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath])
            continue;
        
        mkdir(dirPath.UTF8String, 0755);
    }
    
    // copy first-run files.
    if (compare_file_dates(getResourcePath(@"history.dat.zip"), getDocumentPath(@"dats/history.dat")) == NSOrderedDescending)
        [self extract:getResourcePath(@"history.dat.zip") to:getDocumentPath(@"dats")];

    if (myosd_get(MYOSD_VERSION) != 139 && compare_file_dates(getResourcePath(@"plugins.zip"), getDocumentPath(@"plugins/hiscore/hiscore.dat")) == NSOrderedDescending)
        [self extract:getResourcePath(@"plugins.zip") to:getDocumentPath(@"plugins")];

    // cheat.zip is the 139 version, and cheat.7z is the 2xx version
    // hiscore.dat (in root) is the 139 version, and plugins/hiscore/hiscore.dat is the 2xx version
    NSArray* files;
    if (myosd_get(MYOSD_VERSION) == 139)
        files = @[@"cheat.zip", @"hiscore.dat"];
    else
        files = @[@"cheat.7z"];
    
    // add in fixed pre-canned files
    files = [files arrayByAddingObjectsFromArray:@[@"ui.bdf", @"Category.ini", @"hash.zip", @"skins/README.txt", @"shaders/README.txt", @"shaders/Example.metal", @"software/README.txt"]];

    // copy (or update) pre-canned files.
    for (NSString* file in files)
    {
        NSString* fromPath = getResourcePath(file);
        NSString* toPath = getDocumentPath(file);

        if (file.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:fromPath])
            continue;

        if (compare_file_dates(fromPath, toPath) == NSOrderedDescending) {
            [NSFileManager.defaultManager removeItemAtPath:toPath error:nil];
            [NSFileManager.defaultManager copyItemAtPath:fromPath toPath:toPath error:nil];
        }
    }
    
    // delete the 139 cheat.zip if this is the latest MAME
    if (myosd_get(MYOSD_VERSION) != 139)
        [NSFileManager.defaultManager removeItemAtPath:getDocumentPath(@"cheat.zip") error:nil];

    // delete the 139 hiscore.dat (in root) if this is the latest MAME
    if (myosd_get(MYOSD_VERSION) != 139)
        [NSFileManager.defaultManager removeItemAtPath:getDocumentPath(@"hiscore.dat") error:nil];
    
    // set non-backup items.
    for (NSString* path in @[@"roms", @"artwork", @"titles", @"samples", @"nvram", @"cheat.zip", @"cheat.7z", @"hash.zip"])
    {
        NSURL* url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:get_documents_path(path.UTF8String)]];
        [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
    }

#if TARGET_OS_IOS
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation : UIStatusBarAnimationNone];
#endif
#endif
    
    BOOL result = TRUE;
    
    // check UIApplicationLaunchOptionsURLKey to see if we were launched with a game URL, and set that as the game to restore.
    NSURL* url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if ([url isKindOfClass:[NSURL class]]) {
        
        // handle our own url scheme mame4ios://
        GameInfo* game = [[GameInfo alloc] initWithURL:url];
        if (game != nil) {
            [EmulatorController setCurrentGame:game];
            result = FALSE;
        }
    }

	hrViewController = [[EmulatorController alloc] init];
	
	deviceWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#if TARGET_OS_TV
    deviceWindow.backgroundColor = [UIColor colorWithWhite:0.111 alpha:1.0];
    deviceWindow.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
#endif
    [deviceWindow setRootViewController:hrViewController];
    
    [hrViewController startEmulation];
	[deviceWindow makeKeyAndVisible];
        
    [UIApplication sharedApplication].idleTimerDisabled = YES;
	 
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    externalWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
    externalWindow.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareScreen) name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareScreen) name:UIScreenDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreen)  name:UIScreenModeDidChangeNotification object:nil];
    
    [self prepareScreen];
#endif
    
    NSError *audioSessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&audioSessionError];
    if (audioSessionError != nil) {
        NSLog(@"Could not set audio session category: %@",audioSessionError.localizedDescription);
    }
  
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    [session setPreferredSampleRate:48000.0 error:&error];
    [session setPreferredIOBufferDuration:0.01 error:&error]; // Target ~10 ms latency
    [session setActive:YES error:&error];

    if (error) {
        NSLog(@"Error when setting sample rate or buffer duration: %@", error);
    }


    return result;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSLog(@"OPEN URL: %@ %@", url, options);
    
    GameInfo* game = [[GameInfo alloc] initWithURL:url];
    
    // handle our own scheme mame4ios://game OR mame4ios://system/game OR mame4ios://system/type:file
    if (game != nil) {
        [hrViewController performSelectorOnMainThread:@selector(playGame:) withObject:game waitUntilDone:NO];
        return TRUE;
    }
    
    // copy a file to document root, and then let moveROMS take care of it....
    // ...only handle certain files
    if (!url.fileURL || ![IMPORT_FILE_TYPES containsObject:url.pathExtension.lowercaseString])
        return FALSE;
    
    // dont share with myself
    if ([[url URLByDeletingLastPathComponent].path isEqualToString:[NSString stringWithUTF8String:get_documents_path("roms")]])
        return FALSE;
    
    NSURL* destURL = [[NSURL fileURLWithPath:[NSString stringWithUTF8String:get_documents_path("")]]
                      URLByAppendingPathComponent:url.lastPathComponent];

    BOOL open_in_place = [options[UIApplicationOpenURLOptionsOpenInPlaceKey] boolValue];
    
    if (open_in_place)
    {
        if (![url startAccessingSecurityScopedResource])
            return FALSE;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError* error = nil;
            NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL * newURL) {
                NSError* error = nil;
                [NSFileManager.defaultManager copyItemAtURL:newURL toURL:destURL error:&error];
                
                if (error != nil)
                    NSLog(@"copyItemAtURL ERROR: (%@)", error);
                
                [url stopAccessingSecurityScopedResource];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject cancelPreviousPerformRequestsWithTarget:self->hrViewController selector:@selector(moveROMS) object:nil];
                    [self->hrViewController performSelector:@selector(moveROMS) withObject:nil afterDelay:1.0];
                });
            }];
            if (error != nil)
                NSLog(@"coordinateReadingItemAtURL ERROR: (%@)", error);
        });
    }
    else {
        NSError* error = nil;
        [NSFileManager.defaultManager copyItemAtURL:url toURL:destURL error:&error];
        
        if (error != nil)
            NSLog(@"copyItemAtURL ERROR: (%@)", error);
        
        if ([[[url URLByDeletingLastPathComponent] lastPathComponent] hasSuffix:@"Inbox"])
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];

        [NSObject cancelPreviousPerformRequestsWithTarget:self->hrViewController selector:@selector(moveROMS) object:nil];
        [self->hrViewController performSelector:@selector(moveROMS) withObject:nil afterDelay:1.0];
    }
    
    return TRUE;
}

- (BOOL)performActivity:(NSString*)activityType userInfo:(NSDictionary*)info {
    
    if (![activityType hasPrefix:[[NSBundle mainBundle] bundleIdentifier]])
        return FALSE;
    
    NSString* cmd = [[activityType componentsSeparatedByString:@"."] lastObject];
    
    if ([cmd isEqualToString:@"play"])
    {
        GameInfo* game = [[GameInfo alloc] initWithDictionary:info];
        [hrViewController performSelectorOnMainThread:@selector(playGame:) withObject:game waitUntilDone:NO];
        return TRUE;
    }
        
    return FALSE;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSLog(@"continueUserActivity: %@ %@", userActivity.activityType, userActivity.userInfo);
    return [self performActivity:userActivity.activityType userInfo:userActivity.userInfo];
}

#if TARGET_OS_IOS
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"performActionForShortcutItem: %@ %@", shortcutItem.type, shortcutItem.userInfo);
    completionHandler([self performActivity:shortcutItem.type userInfo:shortcutItem.userInfo]);
}
#endif

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [hrViewController enterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [hrViewController enterForeground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // need to cleanly exit MAME thread
    // MAME static destructors are getting called onexit in Catalyst, sigh C++
    [hrViewController stopEmulation];
}

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
// called when a screen is attached *or* detached
- (void)prepareScreen
{
    // dont show alert asking for screen mode more than once!
    static UIAlertController *g_alert;
    if (g_alert != nil) {
        [g_alert dismissWithCancel];
        return;
    }

    if ([[UIScreen screens] count] > 1) {
        
        // Internal display is 0, external is 1.
        UIScreen* externalScreen = [[UIScreen screens] objectAtIndex:1];
        NSArray* screenModes = [externalScreen availableModes];
        
        if (screenModes.count <= 1) {
            // only one mode, just use it no quesrtions asked
            [self setupScreen:externalScreen];
        }
        else {
			// Allow user to choose from available screen-modes (pixel-sizes).
            g_alert = [UIAlertController alertControllerWithTitle:@"External Display Detected!" message:@"Choose a size for the external display." preferredStyle:UIAlertControllerStyleAlert];
			for (UIScreenMode *mode in screenModes) {
                [g_alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%.0f x %.0f pixels", mode.size.width, mode.size.height] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                    g_alert = nil;
                    [externalScreen setCurrentMode:mode];
                    [self setupScreen:externalScreen];
                }]];
                if (mode == externalScreen.preferredMode)
                    [g_alert setPreferredAction:g_alert.actions.lastObject];
			}
            [g_alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                g_alert = nil;
                [self setupScreen:nil];
            }]];
             
            [hrViewController.topViewController presentViewController:g_alert animated:YES completion:nil];
		}
    }
    else {
        [self setupScreen:nil];
    }
}

// called to use an external screen (or nil for none)
- (void)setupScreen:(UIScreen*)screen
{
    if (screen != nil)
    {
        [screen setOverscanCompensation:UIScreenOverscanCompensationInsetBounds];

        // yea we know setScreen is deprecated and we should use the UIWindowScene version, not today
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated"
        [externalWindow setScreen:screen];
        #pragma clang diagnostic pop

        for (UIView *view in externalWindow.subviews)
            [view removeFromSuperview];
                            
        UIView *view = [[UIView alloc] initWithFrame:screen.bounds];
        view.backgroundColor = [UIColor blackColor];
        [externalWindow addSubview:view];
#ifdef DEBUG
        view.backgroundColor = [UIColor systemOrangeColor];
#endif
        [hrViewController setExternalView:view];
        externalWindow.hidden = NO;
    }
    else
    {
        [hrViewController setExternalView:nil];
        externalWindow.hidden = YES;
    }
    [hrViewController performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];
}

// called when a mode change happens on a external display
- (void)updateScreen
{
    if (externalWindow.hidden == NO && externalWindow.screen != nil) {
        // update window and view frame to new screen mode/size
        externalWindow.frame = externalWindow.screen.bounds;
        externalWindow.subviews.firstObject.frame = externalWindow.bounds;
        [hrViewController performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];
    }
}
#endif

@end

int main(int argc, char **argv){
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"Bootstrapper");
    }
}
