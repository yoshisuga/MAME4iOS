# MAME4iOS

Original Author: David Valdeita (Seleuco)  

This is a port of MAME for iOS, iPadOS, tvOS and macOS. MAME4iOS is designed to run for modern iOS and macOS platforms, including support for the latest Apple technology platform enhancments such as Metal graphics and the M1 processor.

[Download IPAs for iOS and tvOS here](https://github.com/yoshisuga/MAME4iOS/releases)

[Chat on Discord!](https://discord.gg/ZC6wkmU)

[See what's new](WHATSNEW.md)

## Screenshots

![iPhone Screenshot](README.images/screenshot-iphone-small.jpg)
![AppleTV Screenshot](README.images/screenshot-atv-small.png)
![macOS Screenshot](README.images/screenshot-mac.png)

## Summary

MAME stands for Multi Arcade Machine Emulator, and lets you play arcade games from the past 30+ years on a device that fits in your pocket! My teenage self from decades ago would be replaying that ["mind blown GIF"](https://media0.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif) over and over again, but that GIF did not exist back then.

More than 2000 games are supported, and the currently supported romsets are 0.238 (November 2021) and 0.139u1 (September 2010). Note that there are separate apps for the latest MAME and the classic 0.139u1 versions. This is done because the supported romsets differ greatly between the the MAME versions.

It has been updated to compile and runs on the latest Xcode by [Les Bird](http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for MFI Controllers.

Since then, a large number of features have been added:

- 64-bit binary to run on modern and future iOS and macOS devices, including Macs using the M1 series of processors
- Supports modern device screen sizes for iPhone and iPad
- tvOS support (new in 2019!)
- Multiple MFI controllers (up to 4 with dual analog support - @DarrenBranford)
- Supports using the touch screen as a lightgun
- Turbo mode toggle for buttons
- Touch analog for games like Arkanoid
- An in-app web server to transfer files from your computer (new in 2019!)
- A native iOS/iPadOS/tvOS frontend (by @ToddLa, new in 2020!)
- A native Metal rendering engine (by @ToddLa, new in 2020!)
- Transfer ROMs, Artwork, and ROMSETs via AirDrop or iOS File Sharing (new in 2020!)
- Builds in the latest Xcode

## Building / Installation / Sideloading

### Xcode

Requirements: iOS 13.4 or higher, tvOS 13.4 or higher, or Mac 10.15.5 (Catalina) or higher to run.

Requirements: Mac 10.13.6 with Xcode 11.4 or above to bulid.

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode.

1. Open the Xcode project in `MAME4iOS.xcodeproj`  

2. Set the Organization and Team Identifer in `MAME4iOS.xcconfig`

    ```
    ORG_IDENTIFIER   = com.example    // CHANGE this to your Organization Identifier.
    DEVELOPMENT_TEAM = ABC8675309     // CHANGE this to your Team ID. (or select in Xcode project editor)
    ```
    
    - The `ORG_IDENTIFIER` is a reverse DNS string that uniquely identifies your organization.
    - You can also set the Development Team via the drop down in the Xcode project editor, for each Target.  
    - You can find your TeamID [here](https://developer.apple.com/account/#/membership).
        
3. Enable entitlements in `MAME4iOS.xcconfig` (optional, only if you have a developer account)  
    - entitlements are required for tvOS TopShelf and iCloud Import/Export/Sync.

4. Select the MAME binary to link to, in `MAME4iOS.xcconfig`
    - 139u1 or latest `MAME 2xx` version.

5. Choose the appropriate build target in Xcode:
    - `MAME4iOS Release` (iPhone/iPad/macOS)
    - `MAME tvOS Release` (AppleTV)

6. Build:
    1. If you are a developer: Build and `▶︎` Run on your device. _Done._
        - *NOTE* first time build may take a long time.
    2. If you are not a developer…
        1. `Xcode` → `Preferences` add your Apple ID, select your Personal Team, and create an iOS Development Profile.
        2. Select the project name on the left pane and make sure your personal team is selected
        3. Hit the `▶︎` Run button to install on your device. _Done._
        
## How to build latest version of `MAME` (optional)

By default `MAME4iOS` will use pre-combiled libraries for the latest MAME, if you need a Simulator build, or just want to build `MAME`, you need to...

- clone [this fork](https://github.com/ToddLa/mame) of `MAME`
- run `./make-ios.sh [ios | tvos | ios-simulator | tvos-simulator | macOS]` in the forked `MAME`
- go watch [this](https://www.imdb.com/title/tt3748528/) then [this](https://en.wikipedia.org/wiki/Star_Wars_Trilogy) while you wait for `MAME` to build.
- now switch directories to your `MAME4iOS` project
- run  `./get-libmame.sh ios <path to your MAME clone>`
- edit `xcode/MAME4iOS/MAME4iOS.xcconfig` to select the `libmame` library.
- build and run in Xcode.

## Issues running latest `MAME`
* most `MAME` 139 ROMs dont work on 2xx, but that is just normal life in `MAME` world, see [this](#mixing-139-and-2xx-roms).
* if you run a `Computer` machine, and you use a USB keyboard, ⌘+DELETE is is the ui_mode_key.
* `MAME` Configure menu has a `Add To Favorites` and `Select New Machine` that dont interact with the `MAME4iOS` Ux.
* Games that use DRC (like NFL Blitz....) will not work correctly and may crash hang, if `Use DRC` is enabled, This is an issue with the arm64 support in `MAME`.

## Mixing 139 and 2xx ROMs
Some `romsets` are not compatible between MAME 139 and newer versions, the best way to use both `romsets` at the same time is to make sure the newer ones are stored in the `7z` format and the 139 ones in the `zip` format.  This way both files can co-exist.

## tvOS

MAME for tvOS support was added in early 2019, and it currently can run games has full native UI support and MFI controller support with most notably:

- MFI controllers, Xbox One, PS4 DualShock, and Siri Remote support.

## Using MAME

When you start MAME4iOS, you are now presented with an updated and native iOS/tvOS MAME UI

### MAME UI Controls

- Onscreen D-Pad or MFI Controller D-Pad: Move through the menu
- A Button: Start Game

### In-Game

- Coin: `SELECT/COIN` for Player 1
- Start: `START` for Player 1
- Menu: Open the MAME4iOS menu
- Exit: Exit the game

## Adding ROMs to MAME4iOS

### iOS

For iOS users, you can download ROMs using Safari and save them to the `roms` directory by choosing the "Save to Files" (go to "On My iPhone" -> MAME4iOS) option after downloading a ROM. 

You can also use the "Start Server" option in the menu to start the webserver, and enter the address shown on the web browser on your computer.

You can also use the "Import ROMs" option to open up the native iOS file browser and load files that are saved locally or that exist on iCloud.

You can use "Import from iCloud" to download ROMs previously uploaded to iCloud.

### tvOS

on tvOS the only options are to copy ROMs via "Start Server" or downloading via "Import from iCloud".

## Adding Softare to MAME4iOS

MAME4iOS supports two types of Software

1. Software List (aka MESS) based software, installed via ZIP files into `roms`

2. Single file based image (cart, flop, dsk, ...), installed into `software`

## ROMless Machines

MAME4iOS includes a set of Machines/Systems that dont need any ROMs installed to run, and can be used "out of the box".

## ROMless Arcade Machines

Name        |Description
------------|-----------------------
pongf       |Pong (Rev E) [TTL]        
pongd       |Pong Doubles [TTL]        
rebound     |Rebound (Rev B) [TTL]   
breakout    |Breakout [TTL]     

## ROMless Console Machines

The following is a list of *some* of the Consoles and file types supported by MAME "out of the box"

Name    |Description                                                |Media File Types
--------|-----------------------------------------------------------|----------------
a2600   |Atari 2600 (NTSC)                                          |a26, bin
a2600p  |Atari 2600 (PAL)                                           |a26, bin
gen_nomd|Genesis Nomad (USA Genesis handheld)                       |md, smd, bin, gen
genesis |Genesis (USA, NTSC)                                        |cmd, smd, bin, gen
megadrij|Mega Drive (Japan, NTSC)                                   |md, smd, bin, gen
megadriv|Mega Drive (Europe, PAL)                                   |md, smd, bin, gen
megajet |Mega Jet (Japan Mega Drive handheld)                       |md, smd, bin, gen
famicom |Famicom                                                    |unif, nes, unf
fds     |Famicom (w/ Disk System add-on)                            |fds
nes     |Nintendo Entertainment System / Famicom (NTSC)             |unif, nes, unf
nespal  |Nintendo Entertainment System (PAL)                        |unif, nes, unf
snes    |Super Nintendo Entertainment System / Super Famicom (NTSC) |sfc
snespal |Super Nintendo Entertainment System (PAL)                  |sfc
1292apvs|1292 Advanced Programmable Video System                    |rom, tvc, bin, pgm
1392apvs|1392 Advanced Programmable Video System                    |rom, tvc, bin, pgm
pico    |Pico (Europe, PAL)                                         |md, bin
picoj   |Pico (Japan, NTSC)                                         |md, bin
picou   |Pico (USA, NTSC)                                           |md, bin
vboy    |Virtual Boy                                                |vb, bin
sgx     |SuperGrafx                                                 |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso
pce     |PC Engine                                                  |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso
tg16    |TurboGrafx 16                                              |cue, gdi, toc, chd, bin, cdr, nrg, pce, iso

### tvOS

You can upload ROMs to MAME on your AppleTV using a computer. After MAME starts, you'll be shown a welcome screen with the address of the AppleTV that you can enter in your web browser. Add MAME ROMs to the `roms` directory using the provided web uploader.

## Game Controller Support

Pair your MFi, Xbox, or Dual Shock controller with your iOS device, and it should 'just work'.
Up to 4 controllers are supported.

### Hotkey combinations (while in-game)

| | |  
---------------- |-------------
MENU             |Open MAME4iOS MENU   
MENU+L1       |Player Coin                 
MENU+R1       |Player Start               
MENU+L2       |Player 2 Coin                
MENU+R2       |Player 2 Start               
MENU+A          |Speed 2x                
MENU+B          |Pause MAME   
MENU+X          |Exit Game                 
MENU+Y          |Open MAME menu   
MENU+DOWN  |Save State ①               
MENU+UP        |Load State ①                
MENU+LEFT     |Save State ②                
MENU+RIGHT  |Load State ②               

### Hotkey combinations (while in choose game UX)

| | |  
---------------- |-------------
MENU             |Game Context Menu  
OPTION           |MAME4iOS Settings              
A                |Play              

### Dual analog support

The right stick on the extended controller profile is fully supported, with support for 4 players (thank you @DarrenBranford!)

### Trigger buttons

The trigger buttons are mapped to analog controls and should be useful in assigning for pedal controls, for example.

## Siri Remote
MAME4iOS is now usable on a AppleTV using only the stock Siri Remote. You can only play games that use only the A and B buttons.

to start playing a game, hit MENU and select "Coin + Start" from the list.

    TRACKPAD MOVE   - emulate a dpad or joystick
    TRAKPAD CLICK   - A button
    PLAY            - B button
    MENU            - bring up the MAME4iOS menu

## Touch Screen Lightgun Support (new in 2018, iOS only)

You can now use the touch screen for lightgun games like Operation Wolf and Lethal Enforcers. Holding down your finger simulates holding down the trigger, which is mapped to the "X" button. Tap with 2 fingers for the secondary fire, or the "B" button.

In full screen landscape mode, you can hide the onscreen controls using the "D-Pad" button at the top of the screen. When using a game controller, the top button of the screen opens the menu to load/save state or access settings.

Touch Lightgun setup is in Settings -> Input -> Touch Lightgun, where you can disable it altogether, or use tapping the bottom of the screen to simulate shooting offscreen (for game that make you reload like Lethal Enforcers).

#### Shortcuts while in Touch Screen Lightgun mode

- Touch with 2 fingers: secondary fire ("B" button)
- Touch with 3 fingers: press start button
- Touch with 4 fingers: insert coin

## Turbo Mode Toggle for Buttons (new in 2018)

Under Settings -> Game Input, there's a section called "Turbo Mode Toggle", that lets you turn on turbo firing for individual buttons. Holding down the button causes the button to fire in turbo mode.

## Touch Analog Mode (new in 2019, iOS only)

Also in Settings -> Game Input, you'll find a section called "Touch Analog" and "Touch Directional Input". "Touch Analog" lets you use your touchscreen as an analog device for games using input controls such as trackballs and knobs. These include games like Arkanoid or Crystal Castles. You can adjust the sensitivity of the analog controls, and also choose to hide the d-pad/analog stick in this mode.

"Touch Directional Input" is rather experimental and is for vertical shooters so you can move around using your finger. It still needs some work so just a word of caution :)

## License

MAME4iOS is distributed under the terms of the GNU General Public License, 2 (GPL-2.0).
