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
- Turbo mode toggle for buttons (new in 2018!)
- Builds in Xcode 9, runs on iOS 11 

## Xcode 10 / iOS 12

MAME4iOS does not build on Xcode 10. The binary built using Xcode 9 does, however run on iOS 12.

The reason why it does not build on Xcode 10 is because libstdc++ is not included in Xcode 10. The runtime binary is still included in iOS 12 for backwards compatibility, but there's no way (at least I can find) to build and run the app in Xcode 10 unless the libstdc++ runtime library (dylib) is somehow included in the binary. I've tried to include a libstdc++ dylib that I found for arm64 but could not code sign it for inclusion. I don't know enough to compile libstdc++ to an arm64 dylib :(

The other option is to fix the MAME library to compile using libc++. It would involve a lot of code changes, though.

If anyone has any ideas on how to build this under Xcode 10/iOS 12 please make a PR or log an issue!

## Installation / Sideloading

### IPA 

If you can re-sign using your certificate, here is a [link to the IPA](https://mega.nz/#!TZoASCSR!HIKFsZeEY1x87kDbXx5R6oAlqxIPPhfMqDtLYj2DULc).

### Xcode

Requirements: Mac with Xcode 7 or above

Building MAME4iOS requires a prebuilt MAME binary (It was not included in this repo due to its large size): 

1. _Make sure you have the latest version of the Xcode commandline tools installed:_<br> 
`xcode-select --install`
2. In Terminal: `cd [path to MAME4iOS root]`<br> 
  <sup>(alternatively, you can drag & drop a folder on Terminal after `cd` if don't know how to get the directory path)</sup><br> 
3. Get MAME binary:
    - Build:
        - 64-bit version: `make`<br>
        <sup>For iPhone 5S, iPad Air, iPad mini, and up…</sup><br>
        - 32-bit version: `make iOSARMV7=1`
    - Download: 
        - [64-bit](https://mega.nz/#!GJZH3ShT!XVK53FgH5E8WuuSBD57rSwfidtQ2afxWQq9iaPXR4QE)<br>
        <sup>Place the file in the root directory of the repo.</sup><br>
4. Choose the appropriate build target:
    - `MAME4iOS 64-bit` 
    - `MAME4iOS 32-bit`

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode 7/8.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`<br>
    <sup>Make sure you have the `libmamearm64.a` (or `libmamearmv7.a`) file in the root of your project (it should not be red).</sup><br>
2. Build:
    1. If you are a developer: Build and `▶︎` Run on your device. _Done._
    2. If you are not a developer…
        1. `File` → `Preferences` add your Apple ID, select your Personal Team, and create an iOS Development Profile.
        2. Select the project name on the left pane and make sure your personal team is selected
        3. Hit the `▶︎` Run button to install on your device. _Done._

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

Touch Lightgun setup is in Settings -> Input -> Touch Lightgun, where you can disable it altogether, or use tapping the bottom of the screen to simulate shooting offscreen (for game that make you reload like Lethal Enforcers).

#### Shortcuts while in Touch Screen Lightgun mode

- Touch with 2 fingers: secondary fire ("B" button)
- Touch with 3 fingers: press start button
- Touch with 4 fingers: insert coin

### Turbo Mode Toggle for Buttons (new in 2018)

Under Settings -> Game Input, there's a section called "Turbo Mode Toggle", that lets you turn on turbo firing for individual buttons. Holding down the button causes the button to fire in turbo mode.

### tvOS

tvOS is not supported yet. The problem is that I can't compile the tvOS version of the MAME binary, as it needs to be linked with `libc++`, not `libstdc++`, which is what this MAME binary depends on. I'm not intimately familiar with the API differences between the two (it looks like it has to do with differing string functions), so I haven't gotten around to fixing it for tvOS. You can, however, run MAME on an iPhone or iPad and mirror the display to an Apple TV.
