# MAME4iOS

Original Author: David Valdeita (Seleuco)<br/>

This is a port of MAME for iOS. The currently supported rom set version is 0.139.

It has been updated to compile and run on Xcode 7/iOS 9 by Les Bird (http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for mFi Controllers.

## Installation / Sideloading

Requirements: Mac with Xcode 7

Building MAME4iOS requires a prebuilt MAME binary. It was not included in this repo due to its large size. This is done by running `make` at the root directory of the project. Or, you can download a prebuilt binary [here](https://mega.nz/#!DBxg0BAa!xs-roEpruF4vOzJZcPrPBGc_MvIuse3DNfPobdAMDG0). It will work for most modern iOS devices. Place the file in the root directory of the repo.

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode 7.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`
2. Make sure you have the `libmamearmv7.a` file in the root of your project (it should not be red).
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

The right stick on the extended controller profile is fully supported, with support for 4 players (thank you @DarrenBradford!)

### Trigger buttons

The trigger buttons are mapped to analog conrols and should be useful in assigning for pedal controls, for example.

