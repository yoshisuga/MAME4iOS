# $(TARGET)
### Version $(APP_VERSION) ($(APP_DATE)) 

<img src="mame_logo.png" width="60%">

## INTRODUCTION

MAME stands for Multi Arcade Machine Emulator, and lets you play arcade games from the past 30+ years on your iOS device.

More than 8000 games are supported, and the currently supported romsets are 0.250 (December 2022).

MAME for iOS was originally developed by David Valdeita (Seleuco), and is currently maintained by a dedicated enthusiasts (Yoshi Sugawara and Todd Laney).

Since the original version, a large number of features have been added, including:

- Metal Graphics Renderer
- Game Controller Support
- Touch Screen Lightgun Support
- Touch Screen Mouse Support
- On-screen Keyboard

See the official [web page](https://github.com/yoshisuga/MAME4iOS) for news, source code & additional information.

Chat with us on [Discord](https://discord.gg/ZC6wkmU).

To see [MAME license](#MAME4iOS-LICENSE), go to the end of this document.

## CONTROLS

The emulator controls are the following ones:

**Virtual pad** Movement in pad, mouse and analog control of the four players.

**Buttons B,X,A,Y,L,R** Buttons A,B,C,D,E,F.

**Buttons START+COIN** (pressed simultaneously) Access to the MAME menu.

**Button COIN** Insert credits (UP+COIN = 2P credits, RIGHT+COIN = 3P credits, DOWN+COIN = 4P credits).

**Button START** Start (UP+START = 2P start, RIGHT+START = 3P start, DOWN+START = 4P start).

**Button EXIT** Exit to selection menu to select another game.

**Button MENU** Open $(TARGET) menu, global settings.

**NOTE** To type OK when MAME requires it, press LEFT and then RIGHT.

## GLOBAL OPTIONS

**FIlter** the method used to expand the emulator screen.
- **Nearest** Dont appy any filtering, aka `FatBits`
- **Linear**  Apply a smoothing image filter over the emulator screen.

**Skin** choose the artwork and layout of the onscreen controlls. 
- **Default** - the default $(TARGET) look.
- **Light Border** - Default + a bright thick border
- **Dark Border** - Default + a think dark border
- **Classic** - the old $(TARGET) look.

**Screen Shader**  effect to apply to the emulator screen. 
- **None** dont use any effect.
- **Default** use the default `simpleTron`.
- **simpleTron** simple CRT effect.
- **megaTron** more advanced CRT effect.
- **ulTron** even more advanced CRT effect.

**Vector Shader** effect to apply to vector games. 
- **None** dont use any effect.
- **Default** use the default `lineTron`.
- **lineTron** simple vector effect with fade out.

**Full Screen** Uses all available screen or shows the emulator windowed.

**Full Screen with Controler** automaticly enters Full Screen when a controler, keyboard, iCade is detected.

**Keep Aspect Ratio** 'Enabled' keeps the aspect ratio; 'Disabled' will use all available screen.

**Integer Scaling Only** 'Enabled' will only scale image by integer amounts.

**Change Current Layout** Changes the current touch controller current layout.

**Reset Current Layout to Default** Restores the current layout.

**Animated** Animates ON/OFF DPad/Stick. Disable to gain performance.

**Touch Type** Set the touch stick to works as analog stick, digital stick or dpad.

**Stick Type** Limits the joystick's range of motion: 8-way,4-way,2-way The most common reason to use a gate in an actual arcade setting is the retrofitting of an older machine that is not compatible with a new 8-way stick. A classic example of this is Pac-Man. The game was originally designed for a 4-way stick, and is programmed to respond only when a new input occurs. If the user is holding the stick in the down position, then suddenly makes a motion to move to the right, what often happens is that the stick first moves into the down-right diagonal, which the game does not recognize as new input since down is still being held. However, right is also now considered held, and when the user completes the motion to move right, it is also not a new input, and Pac-Man will still be moving down.

**Full Screen Buttons** Show 1-4/6 Buttons: Hide/show B/Y/A/X/L/R buttons if needed.

**Button A = B + X** Select it to use A button as B and X simultaneous press.

**Buttons Size** Lets you change the touch buttons size.

**Fullscreen Stick Size** Lets you change the stick size (not DPAD) on lanscape or portrait fullscreen mode.

**Nintendo Button Layout** if enabled the 🅐 🅑 and 🅧 🅨 buttons will be swapped to match a Nintendo layout.  This option has no effect on a physical game controller.

**External Controller** Enable external controller: iCade, iControlPad as iCade mode or iMpulse.

**P4,P3,P2 as P1** Send Player 1 input data to Player2,3,4 so you can use the 2-4 players at the same time. Funny :). It makes some weird problems with some roms like D&D.

**Button B as Autofire** If enabled, press B to switch autofire on/off.

**DPAD Touch DZ** Enable/Disable a deadzone on DPAD touch center. It could be better for some games. Disable if you don't like it.

**Stick Touch DZ** Touch stick deadzone selector. Lower to gets more sensitivity.

**Sound** Enable or set the default sound rate for games.

**Cheats** Enables the reading of the cheat database, if present, and the Cheat menu in the user interface.

**Save Hiscores** If enabled, saves hiscores on some games not saving on NVRAM. It could cause problems with some games or save states.

**Show FPS** Shows ON/OFF fps.

**Force Pixel Aspect** Enable it to force pixel aspect ratio bypassing MAME video selection.

**Show Info/Warnings** Shows Game Info and any warnings when a game is selected.

## FAVORITES

You can mark (or unmark) your ROMS in the $(TARGET) game selection window as favorites by long pressing to get a context menu. 

You can mark (or unmark) your ROMS in the MAME DOS MENU by pressing the X button. A favorite ROM appears in blue in the game list. The favorites are saved to the file: Favorites.ini. This file is compatible with the standard MAME Favorites.ini file format so you can copy this over from your PC version of MAME to the iOS version.

## RESET
when you make a mistake and need to undo

### Global Settings Reset (aka Factory Reset)
`Settings` > `Reset to Defaults`
* restore all $(TARGET) settings to default.
* delete Recent and Favorite games.
* delete all cached Title Images. 
* delete all MAME key mappings or settings. 
* select `Delete all ROMs` to also remove all data.

### Per Game Settings Reset
context menu, select `Delete`, then choose `Delete Settings`. 
* delete any MAME key mappings or settings for game
* delete any hiscores
* delete any saved state.
* delete cached Title image. 

### Delete Game 
You can also remove a game totally, context menu `Delete`, choose `Delete All Files`

## Hardware keyboard

handle input from a hardware keyboard, the following are examples of hardware keyboards.

* a USB or Bluetooth keyboard connected to a iOS device or AppleTV
* Apple Smart Keyboard connected to an iPad

below is a list of a small subset of the keys supported by $(TARGET), for a full list look [here](https://docs.mamedev.org/usingmame/defaultkeys.html).

| | |  
-|-
     ARROW KEYS      | emulate a dpad or joystick
     LEFT CONTROL    | 🅐 
     LEFT OPTION/ALT | 🅑
     SPACE           | 🅨
     LEFT SHIFT      | 🅧
     Z        | L1
     X       | R1
     1               | Player 1 START
     2               | Player 2 START
     5               | Player 1 COIN
     6               | Player 2 COIN
     TAB             | MAME UI MENU
     ESC or ⌘+.      | MAME UI EXIT
     ⌘+DELETE        | MAME toggle UI MODE (aka SCRLOCK)
     RETURN          | MAME UI SELECT (aka 🅐)

These keys are specific to `$(TARGET)`

| | |  
-|-
     ⌘+ENTER       | TOGGLE FULLSCREEN
     ⌘+I           | TOGGLE INTEGER SCALE
     ⌘+Z           | TOGGLE FPS DISPLAY
     ⌘+U           | TOGGLE HUD DISPLAY
     ⌘+F           | TOGGLE FILTER (Nearest and Linear)
     ⌘+P           | TOGGLE PAUSE
     ⌘+A                  | TOGGLE `Keep Aspect Ratio`
     ⌘+X                  | TOGGLE `Force Pixel Aspect`
     ⌘+M                  | TOGGLE `Mouse Capture`
     ⌘+S           | TOGGLE SPEED 2X
     ⌘+1               | Player 1 COIN+START
     ⌘+2               | Player 2 COIN+START

## Game Controlers

<div style="background:white">
<img src="https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/HJ162" width=25%><img src="https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/HNKT2" width=25%><img src="https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/HNKS2" width=25%><img src="https://images-na.ssl-images-amazon.com/images/I/81oyj8wrlCL._SL1500_.jpg" width=25%>
</div>

Some of the supported game controllers include, but are not limited to:
* Xbox Wireless Controller with Bluetooth (Model 1708)
* PlayStation DUALSHOCK®4 Wireless Controller
* MFi (Made for iOS) Bluetooth controllers, like the SteelSeries Nimbus, Horipad Ultimate, and more may be supported.
* XInput compatible controllers. (Pair via Options > Accessibility > Switch Control)
* iCade
* 8BitDo M30, Zero, and others
* Steam Game Controllers
* iMpulse

To start playing a game using a controller, do one of the following.
* hit MENU and select `Coin + Start` or `1 Player Start`
* hit MENU+L1 to add a Coin, then hit MENU+R1 to Start.
* hit SELECT, then START

## Xbox Controller

| | |  
-|-
`VIEW`     |SELECT                
`GUIDE`   |MENU (on iOS 14+)  
`MENU`     |START              
`VIEW`+`MENU`|MENU

## Playstation Dualshock

| | |  
-|-
`SHARE`     |SELECT                
`PS Button`           |MENU  (iOS 14+)
`OPTIONS`     |START      
`SHARE`+`OPTIONS`|MENU

## SteelSeries Nimbus Controller (MFi)

| | |  
-|-
`MENU` or `PAUSE`           |MENU   

## Nimbus+ Controller

| | |  
-|-
`OPTIONS`     |SELECT                
`HOME`           |MENU (on iOS 14+)   
`MENU`           |START      
`OPTIONS`+`MENU`|MENU

## Steam Game Controlers

To use a Steam Controller, make sure it is updated to BLE Firmware, and it paired with iOS device, see [here](https://support.steampowered.com/kb_article.php?ref=7728-QESJ-4420).

Steam Controller Buttons

| | |  
-|-
`BACK`     |SELECT                 
`STEAM Button`           |MENU   
`START`     |START              

## MENU button on game controllers

* if your controller has a dedicated `MENU` button pressing it will bring up the in-game menu.
* if your controller only has `SELECT` and `START` you can long press either one to bring up the in-game menu, or press both at the same time.
* you can use use any of `SELECT`, `START`, or `MENU` to perform a menu action, listed below, for example both `MENU+X` and `SELECT+X` will exit the game.

## MENU combination actions

To perform a menu action do one of the following
* hold down `MENU` or `SELECT` or `START` and press the combo button. ie MENU+X
* hold down the combo button and press `MENU` or `SELECT` or `START`. ie X+MENU

| | |  
-|-
MENU+L1     |Player Coin                 
MENU+R1     |Player Start               
MENU+L2     |Player 2 Coin                
MENU+R2     |Player 2 Start               
MENU+A       |Speed 2x            
MENU+B       |Pause MAME   
MENU+X       |Exit Game                 
MENU+Y       |Open MAME Configure menu   
MENU+DOWN  |Save State ①               
MENU+UP        |Load State ①                
MENU+LEFT     |Save State ②                
MENU+RIGHT  |Load State ②               

### Hotkey combinations (while in choose game UX)

| | |  
---------------- |-------------
MENU             |Game Context Menu  
OPTION           |$(TARGET) Settings              
A                |Play              

## Multiplayer game start using game controllers

You can start a multiplayer game (1,2,3 or 4) players from the $(TARGET) menu.

If a user inserts a COIN or hits START with a game controller, it will be interpeted as a COIN/START for that player.  

You can insert a COIN or do a START for another player from the main Game Controller by pressing one of the following.

| | |  
-|-
MENU+L2|Player 2 COIN
MENU+R2|Player 2 SELECT

## SAVE/LOAD STATE

You can save or load game states by pressing the MENU button when you are gaming, and select save or load state option. Also you can press button MENU+UP (Load) or MENU+DOWN (Save) on a external controller. 

## Siri Remote
$(TARGET) is now usable on a AppleTV using only the stock Siri Remote. You can only play games that use only the A and B buttons.

to start playing a game, hit `MENU` and select `1 Player Start` from the list.

| | |  
-|-
TRACKPAD MOVE   | emulate a dpad or joystick
TRAKPAD CLICK   | A button
PLAY            | B button
MENU          | bring up the $(TARGET) menu

## iCADE (or compatible)
<img src="iCadeControls.png" width=100%>

The best way to use iCade with $(TARGET) is in fullscreen portrait mode, hit the option button and choose options. The onscreen controls will fade out when you start using the iCade buttons. Tap the screen to get $(TARGET) menu.

If the iCade is off (the fake coin slot light is off) just hit an iCade button or move the joystick.(you must have paired the iCade via bluetooth before)

Thanks to Todd Laney for sending me patches, and Martijn Bosschaart who has supported me to get the iCade HW.

## iMpulse

$(TARGET) works correctly out of the box for iMpulse, also has built-in support for local multiplayer (TwiMpulse). Anayway, if you need to redefine second player buttons, you should press coin (left shoulder button) before so $(TARGET) initializes second iMpulse controller.

## XInput Controller

If you have an XInput compatible controller, use `Settings` > `Accessibility` > `Switch Control` > `Switches` > `Bluetooth Devices` to pair controller, then use as normal in $(TARGET).

## TV-OUT

To connect an iPad or iPhone to your TV or a projector, you can either use the Apple HDMI, Component AV Cable, Apple Composite AV Cable, Apple Dock Connector to VGA Adapter, or other compatible cable.

When the cable is connected to a TV or projector, $(TARGET) will automatically use it when playing a game.

## ROM INSTALLATION

use `Import...`, `Start Web Server`, or `Import from iCloud` from `$(TARGET)` `Settings` 


## MANUAL ROM INSTALLATION

Use the Files app to manually add ROM files to the `roms` folder in the $(TARGET) folder. 

## DIRECTORIES

| | |  
-|-
`artwork/` | Artwork directory
`titles/` | Title images directory
`cfg/` | MAME configuration files directory
`hiscore/` | Hiscores directory
`nvram/` | NVRAM files directory
`roms/ `| ROMs directory
`software/ `| Software directory
`samples/` | Samples directory
`snap/` | Screen snapshots directory
`sta/` | Save states directory

## SUPPORTED GAMES

Games (zip files) have to be imported into the `roms/` folder.

## ROM NAMES

**NOTE** File and directory names in iOS are case-sensitive. Put all file and directory names using lower case!.

## SOUND SAMPLES

The sound samples are used to get complete sound in some of the oldest games. They are placed into the 'samples' directory compressed into ZIP files. The directory and the ZIP files are named using low case!.

## ARTWORK

Starting with the release of MAME 0.107 in July 2006, thanks to Aaron Giles, MAME supports hi-resolution artwork for bezels, backdrops, overlays, marquees, control panels, instruction cards, etc., and includes a new file format for the layout (.lay)

Save these [files](http://mameworld.info/mrdo/mame_artwork.php) to your $(TARGET) `artwork` directory, or import via AirDrop.

## ORIGINAL CREDITS

MAME 0.139u1 original version by Nicola Salmoria and the MAME Team.

## PORT CREDITS

Port to iOS by David Valdeita (Seleuco)

Ongoing maintenance, enhancements and modernization by: Yoshi Sugawara and Todd Laney

Custom Metal Shaders provided by: MrJ 

## KNOWN PROBLEMS

-Button mapping problems: Remove cfg files or folder besides rom folder, or do a `Settings` > `Reset`.

## INTERESTING WEBPAGES ABOUT MAME

*   [http://mamedev.org](http://mamedev.org)
*   [http://www.mameworld.info/](http://www.mameworld.info/)

## ART

Retina skin and touch control layout thanks to Bryn Thompson.

## $(TARGET) LICENSE

$(TARGET) is released under a dual-license (GPL / MAME license) of your choice. Under the GPL license in addition you have some extra rights granted by a special license exception which allow you to link the $(TARGET) GPL source with the not GPL MAME source. The exception also gives you the rights to eliminate it if you don't like it or if you want to include the $(TARGET) source in another GPL program. So, $(TARGET) is 100% GPL. You can more easily think at it as a sort of double license. A GPL or a GPL + exception. You have all the rights of the GPL, and, if you want, some others. The only limitation is for $(TARGET). $(TARGET) cannot include external GPL source without the explicit permission of the source copyright holder.

## MAME LICENSE

*   [http://mamedev.org](http://mamedev.org)

Copyright 1997-2013, Nicola Salmoria and the MAME team. All rights reserved.

Redistribution and use of this code or any derivative works are permitted provided that the following conditions are met:

*   Redistributions may not be sold, nor may they be used in a commercial product or activity.
*   Redistributions that are modified from the original source must include the complete source code, including the source code for all components used by a binary built from the modified sources. However, as a special exception, the source code distributed need not include anything that is normally distributed (in either source or binary form) with the major components (compiler, kernel, and so on) of the operating system on which the executable runs, unless that component itself accompanies the executable.
*   Redistributions must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
