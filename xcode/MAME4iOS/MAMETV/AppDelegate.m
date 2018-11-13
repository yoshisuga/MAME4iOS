//
//  AppDelegate.m
//  MAMETV
//
//  Created by Yoshi Sugawara on 10/14/18.
//  Copyright © 2018 Seleuco. All rights reserved.
//

#import "AppDelegate.h"

#include <sys/stat.h>

const char* get_resource_path(const char* file)
{
    static char resource_path[1024];
    const char *userPath = [[[NSBundle mainBundle] bundlePath] cStringUsingEncoding:NSASCIIStringEncoding];
    sprintf(resource_path, "%s/%s", userPath, file);
    return resource_path;
}

const char* get_documents_path(const char* file)
{
    static char documents_path[1024];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    const char *userPath = [[paths objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding];
    sprintf(documents_path, "%s/%s",userPath, file);
    return documents_path;
}

unsigned long read_mfi_controller(unsigned long res){
    return res;
}


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    struct CGRect rect = [[UIScreen mainScreen] bounds];
    rect.origin.x = rect.origin.y = 0.0f;
    NSError *error;
    NSString *fromPath,*toPath;
    NSFileManager* manager = nil;
    int r = chdir (get_documents_path(""));
    printf("running... %d\n",r);
    
    mkdir(get_documents_path("iOS"), 0755);
    mkdir(get_documents_path("artwork"), 0755);
    mkdir(get_documents_path("cfg"), 0755);
    mkdir(get_documents_path("nvram"), 0755);
    mkdir(get_documents_path("ini"), 0755);
    mkdir(get_documents_path("snap"), 0755);
    mkdir(get_documents_path("sta"), 0755);
    mkdir(get_documents_path("hi"), 0755);
    mkdir(get_documents_path("inp"), 0755);
    mkdir(get_documents_path("memcard"), 0755);
    mkdir(get_documents_path("samples"), 0755);
    mkdir(get_documents_path("roms"), 0755);

    manager = [[NSFileManager alloc] init];
    
    fromPath = [NSString stringWithUTF8String:get_resource_path("gridlee.zip")];
    toPath = [NSString stringWithUTF8String:get_documents_path("roms/gridlee.zip")];
    
    if([manager fileExistsAtPath:fromPath] && ![manager fileExistsAtPath:toPath])
    {
        [manager copyItemAtPath:fromPath toPath:toPath error:nil];
    }
    
    toPath = [NSString stringWithUTF8String:get_documents_path("cheat.zip")];
    if (![manager fileExistsAtPath:toPath])
    {
        error = nil;
        fromPath = [NSString stringWithUTF8String:get_resource_path("cheat.zip")];
        [manager copyItemAtPath: fromPath toPath:toPath error:&error];
        NSLog(@"Unable to move file cheat? %@", [error localizedDescription]);
    }
    toPath = [NSString stringWithUTF8String:get_documents_path("Category.ini")];
    if (![manager fileExistsAtPath:toPath])
    {
        error = nil;
        fromPath = [NSString stringWithUTF8String:get_resource_path("Category.ini")];
        [manager copyItemAtPath: fromPath toPath:toPath error:&error];
        NSLog(@"Unable to move file category? %@", [error localizedDescription]);
    }
    toPath = [NSString stringWithUTF8String:get_documents_path("hiscore.dat")];
    if (![manager fileExistsAtPath:toPath])
    {
        error = nil;
        fromPath = [NSString stringWithUTF8String:get_resource_path("hiscore.dat")];
        [manager copyItemAtPath: fromPath toPath:toPath error:&error];
        NSLog(@"Unable to move file hiscore? %@", [error localizedDescription]);
    }
    
    
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
