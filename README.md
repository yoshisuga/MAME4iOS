# MAME4iOS

Original Author: David Valdeita (Seleuco)  

This is a port of MAME 0.139u1 for iOS 12+, iPadOS 12+, tvOS 12+ and on both macOS Catalina & Big Sur using Mac Catalyst.

[Download IPAs for iOS and tvOS here](https://github.com/yoshisuga/MAME4iOS/releases)

[Chat on Discord!](https://discord.gg/ZC6wkmU)

[See what's new](WHATSNEW.md)

## Screenshots

![iPhone Screenshot](README.images/screenshot-iphone-small.jpg)
![AppleTV Screenshot](README.images/screenshot-atv-small.png)
![macOS Screenshot](README.images/screenshot-mac.png)

## Summary

MAME stands for Multi Arcade Machine Emulator, and lets you play arcade games from the past 30+ years on a device that fits in your pocket! My teenage self from decades ago would be replaying that ["mind blown GIF"](https://media0.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif) over and over again, but that GIF did not exist back then.

More than 2000 games are supported, and the currently supported romset version is MAME 0.139u1 (September 2010).

It has been updated to compile and runs on Xcode 11+/iOS/tvOS 12+ by [Les Bird](http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for MFI Controllers.

This repo adds additional support for:

- 64-bit binary to run on modern and future iOS devices
- Supports modern device screen sizes, including iPhone X/XR/XS/XS Max and iPad Pro
- A native iOS/iPadOS/tvOS frontend (by @ToddLa, new in 2020!)
- A native Metal rendering engine (by @ToddLa, new in 2020!)
- tvOS support (new in 2019!)
- An in-app web server to transfer files from your computer (new in 2019!)
- Transfer ROMs, Artwork, and ROMSETs via AirDrop or iOS File Sharing (new in 2020!)
- Multiple MFI controllers (up to 4 with dual analog support - @DarrenBranford)
- Supports using the touch screen as a lightgun
- Turbo mode toggle for buttons
- Touch analog for games like Arkanoid
- Builds in Xcode 11.4/12.x and runs on latest iOS 12/13/14 versions

## Installation / Sideloading

### Xcode

Requirements: iOS 12.4 or higher, tvOS 12.4 or higher, or Mac 10.15.5 (Catalina) or higher to run.

Requirements: Mac 10.13.6 with Xcode 11.4 or above to bulid.

Building MAME4iOS requires a prebuilt MAME binary (it has not been included in this repo due to its large size):

1. Make sure you have the latest version of the Xcode commandline tools installed:  
`xcode-select --install`

2. In Terminal: `cd [path to MAME4iOS root]`  
  <sup>(alternatively, you can drag & drop a folder on Terminal after `cd` if don't know how to get the directory path)</sup><br>

3. Create the needed MAME binary by building it yourself from scratch: <br>
    *** FOR CATALINA USERS, IN THE SECURITY & PRIVACY SETTINGS, PLEASE ALLOW "TERMINAL" "TO RUN SOFTWARE LOCALLY THAT DOES NOT MEET THE SYSTEMS SECURITY POLICY" IN THE DEVELOPER TOOLS CATEGORY ON THE PRIVACY PAGE IN ORDER TO COMPLETE A SUCCESFUL BUILD *** <br>
- Build it in the above selected terminal by chosing one of the following scripts (depending on which device you are building for):<br>
        - iOS: `./make-ios.sh`<br>
        <sup>For iPhone 5S, iPad Air, iPad mini, and up…</sup><br>
        - tvOS: `./make-tvos.sh`<br>
        <sup>AppleTV (4/4k and above)</sup><br>
        - simulator: `./make-sim.sh`<br>
        <sup>iOS (version 12.4 and above)</sup><br>
        - macOS: `./make-mac.sh`<br>
        <sup>macOS(version 10.15 Catalina and above)</sup><br>
        
    4. Set the Organization and Team Identifer in `xcode/MAME4iOS/MAME4iOS.xcconfig`
        ```
        ORG_IDENTIFIER   = com.example    // CHANGE this to your Organization Identifier.
        DEVELOPMENT_TEAM = ABC8675309     // CHANGE this to your Team ID. (or select in Xcode project editor)
        ```

        - The `ORG_IDENTIFIER` is a reverse DNS string that uniquely identifies your organization.
        - You can also set the Development Team via the drop down in the Xcode project editor, for each Target.  
        - You can find your TeamID [here](https://developer.apple.com/account/#/membership).
        
5. Enable entitlements  in `xcode/MAME4iOS/MAME4iOS.xcconfig` (optional)  
    - entitlements are required for tvOS TopShelf and iCloud Import/Export/Sync.

6. Choose the appropriate build target in Xcode:
    - `MAME4iOS` (iPhone/iPad)
    - `MAME4tvOS` (AppleTV)
    - `MAME4mac` (Mac Catalyst)

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`<br>
    <sup>Make sure you have the `libmame.a` (or `libmame-tvos.a`) file in the root of your project.</sup><br>
2. Build:
    1. If you are a developer: Build and `▶︎` Run on your device. _Done._
    2. If you are not a developer…
        1. `Xcode` → `Preferences` add your Apple ID, select your Personal Team, and create an iOS Development Profile.
        2. Select the project name on the left pane and make sure your personal team is selected
        3. Hit the `▶︎` Run button to install on your device. _Done._
        
## How to build with latest `MAME`
* clone this fork of [MAME](https://github.com/ToddLa/mame)
* switch to the `ios-osd` branch.
* run `./make-ios.sh` (or `./make-ios.sh tvos`) in the forked `MAME`
* go watch [this](https://www.imdb.com/title/tt0056172/) or maybe [this](https://en.wikipedia.org/wiki/The_Godfather_(film_series)) while you wait for `MAME` to build.
* now switch directories to your `MAME4iOS` project
* instead of running  `./make-ios.sh` run  `./get-libmame.sh`
    - if your projects are not *side by side* or you did not name the fork `MAME`, then pass the path to the `MAME` fork to the script.
    - for example if you cloned into `~/MyCode/ToddMAME` then run `./get-libmame.sh ~/MyCode/ToddMAME`
* now you can build and run in Xcode.

## Issues running current `MAME`
* most `MAME` 139 ROMs dont work on 229, but that is just normal life in `MAME` world, see [Mixing 139 and 2xx ROMs](#mixing-139-and-2xx-roms).
* tracking down a sound issue and other random stuff.
* some things (like being smart about number of players, etc) does not work (yet)
* if you run a `Computer` machine you will be stuck and cant exit cuz we dont handle ui_mode and keyboards right (yet)
* the `hiscore` and `cheat` system has not been updated.

## **Software Lists**

Software lists are containing meta-data of software for computers and consoles and are coming from various sources,
they are not compiled in code but use as valuable source of information in order to preserve and document software.

### How to add software to `MAME4iOS`

* first import a *software list xml* file, you can find these files [here](https://github.com/mamedev/mame/tree/master/hash)
    - you can also copy software list xml files *by hand* to the `hash` directory.
* you might be tempted to just import *all* software list files, dont do that, it will waste diskspace on your device, and cause `MAME4iOS` to do extra work.
* after you have imported the software list xml files, you can import `ZIP` files containing software.  The name of the `ZIP` file *or* the subdirectory path in the `ZIP` file needs to match the name of a software list.

example zip file(s)
```
a2600.zip
    pacman.zip
    et.zip
```

```
MySoftware.zip
    a2600/pacman.zip
    a2600/et.zip
    n64/007goldnu.7z
```

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

## Adding ROMs to MAME

### iOS

For iOS users, you can download ROMs using Safari and save them to the `roms` directory by choosing the "Save to Files" (go to "On My iPhone" -> MAME4iOS) option after downloading a ROM. 

You can also use the "Start Server" option in the menu (from the options button or pressing Y + Menu in-game) to start the webserver, and enter the address shown on the web browser on your computer.

Yoiu can also use the "Import ROMs" option to open up the native iOS file browser and load files that are saved locally or that exist on iCloud.

### tvOS

You can upload ROMs to MAME on your AppleTV using a computer. After MAME starts, you'll be shown a welcome screen with the address of the AppleTV that you can enter in your web browser. Add MAME ROMs to the `roms` directory using the provided web uploader.

## Game Controller Support

Pair your MFi, Xbox, or Dual Shock controller with your iOS device, and it should 'just work'.
Up to 4 controllers are supported.

### Hotkey combinations (while in-game)

The following hotkey combinations are supported:

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
