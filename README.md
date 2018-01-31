# MAME4iOS

Original Author: David Valdeita (Seleuco)<br/>

This is a port of MAME for iOS.

MAME stands for Multi Arcade Machine Emulator, and lets you play arcade games from the past 30+ years on a device that fits in your pocket! My teenage self from decades ago would be replaying that ["mind blown GIF"](https://media0.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif) over and over again, but that GIF did not exist back then.

More than 2000 games are supported, and the currently supported rom set version is 0.139.

It has been updated to compile and run on Xcode 7+/iOS 9+ by Les Bird (http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for mFi Controllers.

This repo adds support for:

- 64-bit binary to run on modern and future iOS devices
- Multiple mFi controllers (up to 4 with dual analog support - @DarrenBranford)
- Supports using the touch screen as a lightgun (new in 2018!)
- Builds in Xcode 9, runs on iOS 11 

## Installation / Sideloading

Requirements: Mac with Xcode 7 or above

Building MAME4iOS requires a prebuilt MAME binary. It was not included in this repo due to its large size. This is done by running `make` at the root directory of the project. This will build the 64-bit version of the MAME binary by default and will only work for modern iOS devices (iPhone 5S and above, iPad Air and above, iPad mini 2 and above). To build the 32-bit version, use the command: `make iOSARMV7=1`.

Or, you can download a prebuilt binary [here (64-bit)](https://mega.nz/#!WYBx2B5D!cvuyxKehT4LQ7Iiz8kMJeh8uQ-TWWEUJlngBHKfTICo) or [here (32-bit)](https://mega.nz/#!zNYQCaBZ!a7JaLbiQ65kUQZlxxAGOsRHln2F0dDM1Rly_I5t54KE).

Place the file in the root directory of the repo. Choose the appropraite build target (MAME4iOS 64-bit or MAME4iOS 32-bit).

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode 7/8.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`
2. Make sure you have the `libmamearm64.a` (or `libmamearmv7.a`) file in the root of your project (it should not be red).
1. If you are a developer, build and run on your device
1. If you are not a developer, open Preferences and add your Apple ID, select your Personal Team, and create an iOS Development Profile.
1. Select the project name on the left pane and make sure your personal team is selected
1. Hit the run button to install on your device

## mFi Controller Support

Pair your mFi controller with your iOS device, and it should 'just work'. 

Up to 4 mfi controllers are supported. I've tested it with 2 mfi controllers and it seems to work ok. I was running MAME4iOS on my iPhone 6 Plus with a Gamevice for iPhone 6 controller and a MadCatz C.T.R.L i controller while AirPlay-ing to my Apple TV 4 and it worked great :)

### Hotkey combinations

The following hotkey combinations are supported:

- Start game (PAUSE)
- Insert coin (Hold L and press PAUSE)
- Open menu (Hold R and press PAUSE)
- Exit game (Hold X and press PAUSE)

### Dual analog support

The right stick on the extended controller profile is fully supported, with support for 4 players (thank you @DarrenBranford!)

### Trigger buttons

The trigger buttons are mapped to analog conrols and should be useful in assigning for pedal controls, for example.

### Touch Screen Lightgun Support (new in 2018)

You can now use the touch screen for lightgun games like Operation Wolf and Lethal Enforcers. Holding down your finger simulates holding down the trigger, which is mapped to the "X" button. Tap with 2 fingers for the secondary fire, or the "B" button.

In full screen landscape mode, you can hide the onscreen controls using the "D-Pad" button at the top of the screen. When using a game controller, the top button of the screen opens the menu to load/save state or access settings.

Tpuch Lightgun setup is in Settings -> Input -> Touch Lightgun, where you can disable it altogether, or use tapping the bottom of the screen to simulate shooting offscreen (for game that make you reload like Lethal Enforcers).

### tvOS

tvOS is not supported yet. The problem is that I can't compile the tvOS version of the MAME binary, as it needs to be linked with `libc++`, not `libstdc++`, which is what this MAME binary depends on. I'm not intimately familiar with the API differences between the two (it looks like it has to do with differing string functions), so I haven't gotten around to fixing it for tvOS. You can, however, run MAME on an iPhone or iPad and mirror the display to an Apple TV.
