//
//  MacMenu.m
//  MAME4mac
//
//  Created by Todd Laney on 7/10/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Bootstrapper.h"

@interface Bootstrapper (AppMenu)
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder;
@end

// declare selectors
// TODO: add this to a header file as a protocol??
// TODO: add these to ChooseGameController.h and EmulatorController.h?
@interface NSObject (AppMenu)

- (void)filePlay;
- (void)fileInfo;

- (void)mameSelect;
- (void)mameStart;
- (void)mamePause;
- (void)mameConfigure;
- (void)mameReset;
- (void)mameFullscreen;

@end


@implementation Bootstrapper (AppMenu)

#pragma MARK - MENU BUILDER

// called once at startup, to build or modify our main app menu.
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    
    if (builder.system != UIMenuSystem.mainSystem)
        return;
    
    [builder removeMenuForIdentifier:UIMenuEdit];
    [builder removeMenuForIdentifier:UIMenuFormat];
    [builder removeMenuForIdentifier:UIMenuServices];
    [builder removeMenuForIdentifier:UIMenuToolbar];
    [builder removeMenuForIdentifier:UIMenuHelp];
    
    //[self addMenuItem:UIMenuView title:@"FULLSCREEN" action:@selector(toggleFullScreen:) key:@"\r" modifierFlags:UIKeyModifierCommand using:builder];

    // TODO: DO **NOT** add any UIKeyCommands as menu items, we loose all keyboard input if you do!

    [builder insertChildMenu:[UIMenu menuWithTitle:@"FILE" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UICommand commandWithTitle:@"Import..."     image:[UIImage systemImageNamed:@"square.and.arrow.down"]      action:@selector(fileImport) propertyList:nil],
        [UICommand commandWithTitle:@"Export..."     image:[UIImage systemImageNamed:@"square.and.arrow.up"]        action:@selector(fileExport) propertyList:nil],
        [UICommand commandWithTitle:@"Start Server"  image:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle"] action:@selector(fileStartServer) propertyList:nil],
    ]] atStartOfMenuForIdentifier:UIMenuFile];

    [builder insertSiblingMenu:[UIMenu menuWithTitle:@"FILE" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UICommand commandWithTitle:@"Play"     image:[UIImage systemImageNamed:@"play.circle"] action:@selector(filePlay) propertyList:nil],
        [UICommand commandWithTitle:@"Get Info" image:[UIImage systemImageNamed:@"info.circle"] action:@selector(fileInfo) propertyList:nil],
    ]] beforeMenuForIdentifier:UIMenuClose];

    UIMenu* mame = [UIMenu menuWithTitle:@"MAME" image:nil identifier:nil options:0 children:@[
        [UICommand commandWithTitle:@"Coin"      image:[UIImage systemImageNamed:@"centsign.circle"]     action:@selector(mameSelect)    propertyList:nil],
        [UICommand commandWithTitle:@"Start"     image:[UIImage systemImageNamed:@"person"]              action:@selector(mameStart)     propertyList:nil],
        [UICommand commandWithTitle:@"Fullscreen"image:[UIImage systemImageNamed:@"rectangle.and.arrow.up.right.and.arrow.down.left"] action:@selector(mameFullscreen)propertyList:nil],
        [UICommand commandWithTitle:@"Configure" image:[UIImage systemImageNamed:@"slider.horizontal.3"] action:@selector(mameConfigure) propertyList:nil],
        [UICommand commandWithTitle:@"Pause"     image:[UIImage systemImageNamed:@"pause.circle"]        action:@selector(mamePause)     propertyList:nil],
        [UICommand commandWithTitle:@"Reset"     image:[UIImage systemImageNamed:@"power"]               action:@selector(mameReset)     propertyList:nil],
    ]];
    [builder insertSiblingMenu:mame afterMenuForIdentifier:UIMenuView];
    
    UIWindowScene* scene = deviceWindow.windowScene;
    if (scene) {
        scene.titlebar.autoHidesToolbarInFullScreen = YES;
        scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    }
}

#pragma MARK - FILE MENU

-(void)fileStartServer {
    [hrViewController runServer];
}
-(void)fileImport {
    [hrViewController runImport];
}
-(void)fileExport {
    [hrViewController runExport];
}

@end


