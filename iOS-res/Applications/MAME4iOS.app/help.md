# MAME4iOS Reloaded (0.139u1 ) 1.6 (May 15, 2013) by David Valdeita (Seleuco)

![Icon](MAME4iOS144.png)

## INTRODUCTION

MAME4iOS Reloaded is developed by David Valdeita (Seleuco), port of MAME 0.139u1 emulator by Nicola Salmoria and TEAM.

MAME4iOS Reloaded emulates arcade games supported by original MAME 0.139u1.

This MAME4iOS version is targeted to A5 devices, because it is based on a high specs 2010 PC MAME build. Anyway don't expect arcade games of the 90 to work at full speed. With some games that are really bad optimized (like outrun or mk series) you will need at least an A6 device. This is related to MAME build used, since it is targeted to high specs PC's as i said before. This version doesn't have an UML backend ARM dynamic recompiler, which means drivers based on high specs arcade CPUs won't be playable (it has not sense since this games will be slow in any case).

TIP: You can try to use speed hacks (this menu appears pressing START + COIN at the same time when you are gaming) to make playables some games like CPS3 ones.

Said that, with a low end device, use at your own risk. I suggest you use iMAME4all (0.37b5) instead. Remember that games that can be emulated on both versions will run much faster on iMAME4all (0.37b5) than on MAME4iOS Reloaded (0.139u1), and will drain less battery.

This version emulates over 8000 different romsets.

Please, try to understand that that with that amount of games, some will run better than others and some might not even run with MAME4iOS Reloaded. Please, don't email me asking for a specific game to run.

After installing, place your MAME-titled zipped roms in /var/mobile/Media/ROMs/MAME4iOS/ folder for MAME4iOS for jailbroken devices, on NO jailbroken devices, use iTunes file sharing (if your build has it available) or use a 3rd party app like iFunBox or iExplorer to copy ROMs on sandboxed MAME4iOS 'Documents' folder.

MAME4iOS Reloaded uses only '0.139u1' romset.

Official web page for news, source code & additional information:

[http://code.google.com/p/imame4all/](http://code.google.com/p/imame4all/)

[To see MAME license, go to the end of this document.](#license)

## Features

*   Autorotate.
*   Smoothed image.
*   Scanline & TV Effect.
*   Full screen, windowed.
*   Selectable animated touch DPad, Digital Stick or Analog Stick.
*   1/6 touch buttons selectable.
*   Sixaxis/WiiMote/WiiClassic control thanks to BTstack. (Jailbroken only).
*   Support for up to 4 Sixaxis/WiiMotes/Classic (multiplayer) (Jailbroken only).
*   External controller support: iCade (or compatible), iControlPad, iMpulse (1 or 2 Players).
*   Peer to Peer Netplay Multiplayer
*   TV-OUT

... and more.

## CONTROLS

The emulator controls are the following ones:

**-Virtual pad:** Movement in pad, mouse and analog control of the four players.

**-Buttons B,X,A,Y,L,R:** Buttons A,B,C,D,E,F.

**-Buttons START+COIN:** (pressed simultaneously) Access to the MAME menu.

**-Button COIN:** Insert credits (UP+COIN = 2P credits, RIGHT+COIN = 3P credits, DOWN+COIN = 4P credits).

**-Button START:** Start (UP+START = 2P start, RIGHT+START = 3P start, DOWN+START = 4P start).

**-Buttons A+COIN:** Load State.

**-Buttons A+START:** Save State.

**-Button EXIT:** Exit to selection menu to select another game.

**-Button MENU:** Open MAME4iOS menu, global settings.

NOTE: To type OK when MAME requires it, press LEFT and then RIGHT.

## GLOBAL OPTIONS

**-Game Filter.** Use to filter games by keyword, year, manufacturer, driver source, category. Also let you hide non Favorites, clones or not working games.

**-Smoothed image.** Enable to apply a smoothing image filter over the emulator screen.

**-CRT Effect.** Enable to apply a CRT like filter over the image.

**-Sacanline Effect.** Enable to apply a scanline filter over the image.

**-Full Screen.** Uses all available screen or shows the emulator windowed.

**-Keep Aspect Ratio.** 'Enabled' keeps the aspect ratio; 'Disabled' will use all available screen.

**-Change Current Layout.** Changes the current touch controller current layout.

**-Reset Current Layout to Default.** Restores the current layout.

**-Animated.** Animates ON/OFF DPad/Stick. Disable to gain performance.

**-Touch Type:** Set the touch stick to works as analog stick, digital stick or dpad.

**-Stick Type:** Limits the joystick's range of motion: 8-way,4-way,2-way The most common reason to use a gate in an actual arcade setting is the retrofitting of an older machine that is not compatible with a new 8-way stick. A classic example of this is Pac-Man. The game was originally designed for a 4-way stick, and is programmed to respond only when a new input occurs. If the user is holding the stick in the down position, then suddenly makes a motion to move to the right, what often happens is that the stick first moves into the down-right diagonal, which the game does not recognize as new input since down is still being held. However, right is also now considered held, and when the user completes the motion to move right, it is also not a new input, and Pac-Man will still be moving down.

**-Full Screen Buttons.** Show 1-4/6 Buttons: Hide/show B/Y/A/X/L/R buttons if needed.

**-Button A = B + X.** Select it to use A button as B and X simultaneous press.

**-Buttons Size.** Lets you change the touch buttons size.

**-Fullscreen Stick Size.** Lets you change the stick size (not DPAD) on lanscape or portrait fullscreen mode.

**-External Controller:** Enable external controller: iCade, iControlPad as iCade mode or iMpulse.

**-P4,P3,P2 as P1.** Send Player 1 input data to Player2,3,4 so you can use the 2-4 players at the same time. Funny :). It makes some weird problems with some roms like D&D.

**-Button B as Autofire:** If enabled, press B to switch autofire on/off.

**-DPAD Touch DZ:** Enable/Disable a deadzone on DPAD touch center. It could be better for some games. Disable if you don't like it.

**-Stick Touch DZ:** Touch stick deadzone selector. Lower to gets more sensitivity.

**-BT Analog DZ:** Sixaxis or Wii classic stick deadzone selector. Upper if you have problems with stick (controller going crazy). Lower to gets more sensitivity. (only jailbroken)

**-Sound:** Enable or set the default sound rate for games.

**-Cheats:** Enables the reading of the cheat database, if present, and the Cheat menu in the user interface.

**-Force 60hz sync:** If enabled, forces 60Hz video emulatiob for smoother gameplay in some games (use with caution since it could broke other games like cave ones).

**-Save Hiscores:** If enabled, saves hiscores on some games not saving on NVRAM. It could cause problems with some games or save states.

**-Native TV-OUT:** If you want native iOS TVOUT mirror or you use and external 3rd party TVOUT app, you can turn off MAME4iOS native TVOUT.

**-Threaded video:** Enable video threading for better performance on multicore devices.

**-Video Thread Priority:** Sets the video thread priority if video thread is also enabled.

**-Double buffer:** Avoids flickering.

**-Main Thread Priority:** Sets the main thread priority.

**-Show FPS:** Shows ON/OFF fps.

**-Emulated Resolution:** Force MAME internal drawing resolution, use hires resolution to improve artwork rendering at the expense of performance.

**-Throttle:** Configures the default thottling setting. When throttling is on, MAME attempts to keep the game running at the game's intended speed. When throttling is off, MAME runs the game as fast as it can.

**-Frame Skip:** Specifies the frameskip value. This is the number of frames out of every 12 to drop when running. For example, if you say -frameskip 2,then MAME will display 10 out of every 12 frames. By skipping those frames, you may be able to get full speed in a game that requires more horsepower than your device has. The default value is autoframekip that Automatically determines the frameskip level while you're playing the game, adjusting it constantly in a frantic attempt to keep the game running at full speed.

**-Force Pixel Aspect:** Enable it to force pixel aspect ratio bypassing MAME video selection.

**-Sleep on idle:** Allows MAME to give time back to the system (sleep) when running with -throttle. This allows other programs to have some CPU time, assuming that the game isn't taxing 100% of your CPU resources. This option can potentially cause hiccups in performance if other demanding programs are running.

**-Show Info/Warnings:** Shows Game Info and any warnings when a game is selected.

**-Low Latency Audio:** Uses no queues (AudioUnit) to play audio with low latency.

**-Skin:** Let's you select skin or skin layout

**-Native TV-OUT:** If you want native iOS TVOUT mirror or you use and external 3rd party TVOUT app, you can turn off MAME4iOS native TVOUT.

**-Overscan TV-OUT:** You can set the amount of TV overscan correction.

## FAVORITES

You can mark (or unmark) your ROMS in the MAME4iOS game selection window as favorites by pressing the X button (you can also delete the GAME physical files). A favorite ROM appears in blue in the game list. The favorites are saved to the file: Favorites.ini.

This file is compatible with the standard MAME Favorites.ini file format so you can copy this over from your PC version of MAME to the iOS version.

In the filtering options you can filter your ROMS by favorites, category, manufacturer, driver source and year plus you can also filter out ROM clones.

## SAVE/LOAD STATE

You can save or load game states by pressing the MENU button when you are gaming, and select save or load state option. Also you can press button A+COIN (Load) or A+START (Save) on a external controller. Then you should press button B (slot1) or button X (slot 2) to save or load the state

## WiiMote/Sixaxis

(only MAME4iOS for jailbroken devices)

MAME4iOS lets you use up to 4 Sixaxis, WiiMotes or Wii Classic controllers over bluetooth to play (local multiplayer).

MAME4iOS uses btstack project to support Sixaxis/WiiMote:

[http://code.google.com/p/btstack/](http://code.google.com/p/btstack/)

To use WiiMote/Sixaxis you have to first launch MAME4iOS menu pressing MENU button, and select WiiMote/Sixaxis option. Then, press to find first WiiMote/Sixaxis. Make your WiiMote discoverable by pressing the 1+2 buttons at the same time (on newer WiiMoters you should press the small red button near battery instead). To make your Sixaxis discoverable, press the PS button on the Sixaxis controller

You can add new WiiMote/Sixaxis anytime, selecting WiiMote/Sixaxis option again. If a WiiMote/Sixaxis is disconnected (battery drained) you can reconnect it or connect another WiiMote/Sixaxis and continue playing.

To connect the PS3 controller to your iOS device, you must store the Bluetooth address of your iOS device in your controller:

Step 1\. On Windows, download and run [SixaxisPairTool](http://www.dancingpixelstudios.com/sixaxiscontroller/tool.html).

Step 2\. Connect your iOS device to your computer with the lightning cable or 30-pin cable. Connect your PS3 controller to your computer with a USB cable and wait for the Bluetooth address to come up. Once it's paired with your computer, get your iOS device's Bluetooth address by heading into Settings > About > Bluetooth. Enter that address into SixaxisPairTool and click update. Now your iOS device should be linked to your PS3 controller.

On Mac, Download [SixPair Tool](http://ringwald.ch/cydia/blutrol/SixPairMac-v1.0.zip) and run the app.

WiiMote Buttons mapping:

*   2 = B
*   1 = X
*   \+ = START
*   \- = SELECT
*   B = Y
*   A = A
*   home: exit game

Sixaxis Buttons mapping:

*   Circle = B
*   Cross = X
*   start = START
*   select = SELECT
*   triangle = Y
*   square = A
*   PS: exit game
*   L1,R2: L1
*   R1,L2: R1

In landscape mode touch anywhere on the screen to show the emulator options.

## iCADE (or compatible)

The best way to use iCade with MAME4iOS is in fullscreen portrait mode, hit the option button and choose options. The onscreen controls will fade out when you start using the iCade buttons. To get on screen controls back, just exit the app.

If the iCade is off (the fake coin slot light is off) just hit an iCade button or move the joystick.(you must have paired the iCade via bluetooth before)

When the iCade turns off, the SW keyboard may popup and then backdown, this is normal don't be alarmed

iCade KEY MAPPINGS:

*   TOP: [RED/COIN] [BLACK/EXIT] [BLACK/Y] [WHITE/B]
*   BOT: [RED/START] [BLACK/OPTION] [BLACK/A] [WHITE/X]

Thanks to Todd Laney for sending me patches, and Martijn Bosschaart who has supported me to get the iCade HW.

## iMpulse

MAME4iOS works correctly out of the box for iMpulse, also has built-in support for local multiplayer (TwiMpulse). Anayway, if you need to redefine second player buttons, you should press coin (left shoulder button) before so MAME4iOS initializes second iMpulse controller.

## TV-OUT

To connect an iPad or iPhone to your TV or a projector, you can either use the Apple HDMI, Component AV Cable, Apple Composite AV Cable, Apple Dock Connector to VGA Adapter, or other compatible cable.

Use TV Out settings to set up how iPad or iPhone plays videos on your TV.

When the cable is connected to a TV or projector, MAME4iOS will automatically use it when playing a game.

Set the TV signal to NTSC or PAL: Choose Video > TV Signal and select NTSC or PAL. NTSC and PAL are TV broadcast standards, used in different regions. If you are in the Americas, NTSC is probably the correct choice. Elsewhere, try PAL. If you're not sure, check the documentation that came with your TV or projector.

You can set the amount of overscan corrections in options menu.

If you like iOS TVOUT mirror or you use and external 3rd party TVOUT app, you can turn off MAME4iOS native TVOUT in options menu.

## INSTALLATION

After installing, place your MAME-titled zipped roms in /var/mobile/Media/ROMs/MAME4iOS/roms folder for MAME4iOS for jailbroken devices

On MAME4iOS for NO jailbroken devices, use iTunes file sharing (if your MAME4iOS build has it available) or use a 3rd party app like iFunBox or iExplorer to copy ROMs on sandboxed MAME4iOS 'Documents' folder:

Step 1\. Downloaded iFunBox (or a similar utility) and plug your iOS device into your computer.

Step 2\. Launch iFunBox and select your iOS device on the left hand side.

Step 3\. If you don't have a jailbroken device, click on apps icon. Now you should see a list of all of your device’s applications. Locate MAME4iOS, click it, and select Documents. If you have a jailbroken device, click on raw file system icon and locate /var/mobile/Media/ROMs/MAME4iOS/roms folder.

Step 4\. And that’s all there is to it. Move your ROMs into this folder, launch MAME4iOS, and start playing!

## DIRECTORIES

*   artwork/ -> Artwork directory
*   cfg/ -> MAME configuration files directory
*   hi/ -> Hiscores directory
*   nvram/ -> NVRAM files directory
*   roms/ -> ROMs directory
*   samples/ -> Samples directory
*   snap/ -> Screen snapshots directory
*   sta/ -> Save states directory

## SUPPORTED GAMES

MAME4iOS Reloaded uses only '0.139u1' romset.

Games have to be copied into the roms/ folder.

## ROM NAMES

Romsets have to be MAME 0.139u1 ones (September 2010).NOTE: File and directory names in iOS are case-sensitive. Put all file and directory names using low case!.

## SOUND SAMPLES

The sound samples are used to get complete sound in some of the oldest games. They are placed into the 'samples' directory compressed into ZIP files. The directory and the ZIP files are named using low case!.

## ARTWORK

Starting with the release of MAME 0.107 in July 2006, thanks to Aaron Giles, MAME supports hi-resolution artwork for bezels, backdrops, overlays, marquees, control panels, instruction cards, etc., and includes a new file format for the layout (.lay)

Save these files to your MAME4iOS artwork directory. To use them, use a higher emulated resolution (instead to auto) to improve rendering. This could hurt performance

[http://mameworld.info/mrdo/mame_artwork.php](http://mameworld.info/mrdo/mame_artwork.php)<a>

## ORIGINAL CREDITS

MAME 0.139u1 original version by Nicola Salmoria and the MAME Team.

## PORT CREDITS

Port to iOS by David Valdeita (Seleuco)

## DEVELOPMENT

*   2013-04-05 Version 1.6\. Added Peer to peer netplay multiplayer over WI-FI or Bluetooth. Options menu reworked. Added Vector defaults options. Added Emulation speed and thread type options. Sixaxis fixes. Some other bug fixes.
*   2013-04-05 Version 1.5\. Added native l2cap bluetooth support for up to 4 PS3 Sixaxis controllers (you must store the Bluetooth address of your iOS device in your controller with a 3rd party utility like SixaxisPairTool). Added button and stick size selectors. Fixed permissions errors when creating files on jailbroken devices. Bluetooth manager bug fixes.
*   2013-03-17 Version 1.4\. Added in app touch layout customization. Added hiscores saving (MKChamp patch). Added switch to force 60Hz video for smoother gameplay in some games (use with caution since could broke other games like cave ones). Added autofire with different speeds. Added threaded video and thread priority switches. Fixed some anonymous timers on sega and cave drivers to fix save states problems (AWJ patch). Fixed 2nd controller mapping issues. Fixed simultaneous analog and digital input on external controllers. Added support for newer Wiimotes.
*   2013-02-09 Version 1.3.1 Minor bug fixes. Updated to Jailbroken devices.
*   2013-01-14 Version 1.3\. Added iPhone 5 support. Universal armv7+armv7s binary. Code refactoring for iOS 6\. Added game filtering (manufacturer, driver source, year, category, keyword, clones). Added favorites. Added option to delete games in rom manager. Added iTunes file sharing to upload roms. Added auto selection for 1-6 buttons & 2-8 ways stick. Added iMpulse controller support (+ TwiMpulse). Added low latency audio option. Improved rom manager. A lot of bug fixes.
*   2012-06-02 Version 1.2\. Fixed compatibility issue with iOS 5.1.1 jailbreak. Added local multiplayer (up to 4 players). Added true analog control (selectable as option). Fixed Taito X system. Added P1 Player as P2,P3,P4 input option. Some bug fixes.
*   2012-04-08 Version 1.1\. Upgraded to MAME 0.139u1\. Added 4/3, pixel aspect video aspects (now works MAME menu aspect ratio selector), improved iPad touch control layout, improved ROM manager, Added emulated resolution selector to improve artwork rendering, added configuration input menus, added missing options like frameskip.
*   2012-03-09 Version 1.0 WIP. First version.

## KNOWN PROBLEMS

-Button mapping problems: Remove cfg files or folder besides rom folder.

-Directories cannot be created or preferences cannot be saved (jailbroken MAME4iOS). Just go to MAME4iOS.app file in your iDevice directory and set the permissions to 777. also needs to be on the MAME4iOS folder under /var/mobile/Media/ROMS. (recursive)

This is what you need to do. SSH into your iPad and then run this command on the two directories like this: chmod -R 777 /var/mobile/Media/ROMs/MAME4IOS chmod -R 777 /Applications/MAME4iOS.app Make sure of the following:

1.  You're logged in as root
2.  You type in the commands case sensitive
3.  MAME4iOS is not running

You can use other apps but this works for sure.

## INTERESTING WEBPAGES ABOUT MAME

*   [http://mamedev.org](http://mamedev.org)
*   [http://www.mameworld.info/](http://www.mameworld.info/)

## ART

Retina skin and touch control layout thanks to Bryn Thompson.

## Thanks

Todd Laney for sending me iCade patches, and Martijn Bosschaart for support me with an iCade.

## MAME4iOS LICENSE

MAME4iOS is released under a dual-license (GPL / MAME license) of your choice. Under the GPL license in addition you have some extra rights granted by a special license exception which allow you to link the MAME4iOS GPL source with the not GPL MAME source. The exception also gives you the rights to eliminate it if you don't like it or if you want to include the MAME4iOS source in another GPL program. So, MAME4iOS is 100% GPL. You can more easily think at it as a sort of double license. A GPL or a GPL + exception. You have all the rights of the GPL, and, if you want, some others. The only limitation is for MAME4iOS. MAME4iOS cannot include external GPL source without the explicit permission of the source copyright holder.</a><a id="license">

## MAME LICENSE

*   [http://mamedev.org](http://mamedev.org)

Copyright 1997-2013, Nicola Salmoria and the MAME team. All rights reserved.

Redistribution and use of this code or any derivative works are permitted provided that the following conditions are met:

*   Redistributions may not be sold, nor may they be used in a commercial product or activity.
*   Redistributions that are modified from the original source must include the complete source code, including the source code for all components used by a binary built from the modified sources. However, as a special exception, the source code distributed need not include anything that is normally distributed (in either source or binary form) with the major components (compiler, kernel, and so on) of the operating system on which the executable runs, unless that component itself accompanies the executable.
*   Redistributions must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
