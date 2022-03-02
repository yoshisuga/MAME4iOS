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
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder API_AVAILABLE(ios(13.0));
@end

// declare selectors
// TODO: add this to a header file as a protocol??
// TODO: add these to ChooseGameController.h and EmulatorController.h?
@interface NSObject (AppMenu)

- (void)filePlay;
- (void)fileInfo;
- (void)fileFavorite;

- (void)mameSelect;
- (void)mameStart;
- (void)mameStartP1;
- (void)mameStartP2;
- (void)mamePause;
- (void)mameSettings;
- (void)mameConfigure;
- (void)mameReset;
- (void)mameFullscreen;
- (void)mameExit;

@end

@implementation Bootstrapper (AppMenu)

#pragma MARK - MENU BUILDER

// called once at startup, to build or modify our main app menu.
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    
    if (!IsRunningOnMac() || builder.system != UIMenuSystem.mainSystem)
        return;
    
    [builder removeMenuForIdentifier:UIMenuEdit];
    [builder removeMenuForIdentifier:UIMenuView];
    [builder removeMenuForIdentifier:UIMenuFormat];
    [builder removeMenuForIdentifier:UIMenuServices];
    [builder removeMenuForIdentifier:UIMenuToolbar];
    [builder removeMenuForIdentifier:UIMenuHelp];

    // remove all items in the File menu
    [builder replaceChildrenOfMenuForIdentifier:UIMenuFile fromChildrenBlock:^NSArray* (NSArray* children) {return @[];}];

    // then add the ones we want.
    [builder insertChildMenu:[UIMenu menuWithTitle:@"FILE" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UIKeyCommand commandWithTitle:@"Play"     image:[UIImage systemImageNamed:@"play.circle"] action:@selector(filePlay) input:@" " modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Favorite" image:[UIImage systemImageNamed:@"star.circle"] action:@selector(fileFavorite) input:@"y" modifierFlags:UIKeyModifierCommand propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Get Info" image:[UIImage systemImageNamed:@"info.circle"] action:@selector(fileInfo) input:@"i" modifierFlags:UIKeyModifierCommand propertyList:nil],
    ]] atStartOfMenuForIdentifier:UIMenuFile];

    [builder insertChildMenu:[UIMenu menuWithTitle:@"FILE" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UICommand commandWithTitle:@"Import..."     image:[UIImage systemImageNamed:@"square.and.arrow.down.on.square"]      action:@selector(fileImport) propertyList:nil],
        [UICommand commandWithTitle:@"Export..."     image:[UIImage systemImageNamed:@"square.and.arrow.up.on.square"]        action:@selector(fileExport) propertyList:nil],
        [UICommand commandWithTitle:@"Start Server"  image:[UIImage systemImageNamed:@"arrow.up.arrow.down.circle"] action:@selector(fileStartServer) propertyList:nil],
        [UICommand commandWithTitle:@"Show Files"    image:[UIImage systemImageNamed:@"folder"] action:@selector(fileShowFiles) propertyList:nil],
    ]] atStartOfMenuForIdentifier:UIMenuFile];
    
    // UIKeyInputF3 is only valid on 13.4 or later, avoid a build warning
    NSString* keyF3 = @"";
#ifdef __IPHONE_13_4
    if (@available(iOS 13.4, *)) {
        keyF3 = UIKeyInputF3;
    }
#endif

    // **NOTE** the keyboard shortcuts here are mostly for discoverability, the real key handling takes place in KeyboardView.m
    // TODO: find out why some keys are handled by KeyboardView.m and some are handled by UIKeyCommand, weird responder chain magic??
    UIMenu* mame = [UIMenu menuWithTitle:@"MAME" image:nil identifier:nil options:0 children:@[
        [UIKeyCommand commandWithTitle:@"Coin"      image:[UIImage systemImageNamed:@"centsign.circle"]     action:@selector(mameSelect)    input:@"5" modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Start"     image:[UIImage systemImageNamed:@"play.circle"]         action:@selector(mameStart)     input:@"1" modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Coin+Start"image:[UIImage systemImageNamed:@"person.circle"]       action:@selector(mameStartP1)   input:@"1" modifierFlags:UIKeyModifierCommand propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Fullscreen"image:[UIImage systemImageNamed:@"rectangle.and.arrow.up.right.and.arrow.down.left"]
                                action:@selector(mameFullscreen) input:@"\r" modifierFlags:UIKeyModifierCommand propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Settings"  image:[UIImage systemImageNamed:@"gear"]                action:@selector(mameSettings)  input:@"/" modifierFlags:UIKeyModifierCommand propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Configure" image:[UIImage systemImageNamed:@"slider.horizontal.3"] action:@selector(mameConfigure) input:@"\t" modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Pause"     image:[UIImage systemImageNamed:@"pause.circle"]        action:@selector(mamePause)     input:@"P" modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Reset"     image:[UIImage systemImageNamed:@"power"]               action:@selector(mameReset)     input:keyF3 modifierFlags:0 propertyList:nil],
        [UIKeyCommand commandWithTitle:@"Exit"      image:[UIImage systemImageNamed:@"x.circle"]            action:@selector(mameExit)      input:UIKeyInputEscape modifierFlags:0  propertyList:nil],
    ]];
    [builder insertSiblingMenu:mame afterMenuForIdentifier:UIMenuFile];
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
-(void)fileExportSkin {
    [hrViewController runExportSkin];
}
-(void)fileShowFiles {
    [hrViewController runShowFiles];
}

@end


