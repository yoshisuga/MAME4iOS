# MAME4iOS

Original Author: David Valdeita (Seleuco)<br/>

This is a port of MAME for iOS. The currently supported rom set version is 0.139.

It has been updated to compile and run on Xcode 7/iOS 9 by Les Bird (http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for mFi Controllers.

## Installation / Sideloading

Requirements: Mac with Xcode 7

Building MAME4iOS requires a prebuilt MAME binary. It was not included in this repo due to its large size. This is done by running `make` at the root directory of the project. Or, you can download a prebuilt binary [here](https://mega.nz/#!HVYj2Yqa!u7W2zvPLRQ7T4TAoMqGR2NZtjEl90HMTSXUQzD-2gRE). It will work for most modern iOS devices. Place the file in the root directory of the repo.

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode 7.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`
2. Make sure you have the `libmamearmv7.a` file in the root of your project (it should not be red).
1. If you are a developer, build and run on your device
1. If you are not a developer, open Preferences and add your Apple ID, select your Personal Team, and create an iOS Development Profile.
1. Select the project name on the left pane and make sure your personal team is selected
1. Hit the run button to install on your device

## mFi Controller Support

Pair your mFi controller with your iOS device, and it should 'just work'. 

Up to 4 mfi controllers are supported (this is untested as of 5/18/16).

### Hotkey combinations

The following hotkey combinations are supported:

- Start game (PAUSE)
- Insert coin (B + PAUSE)
- Open menu (A + PAUSE)
- Exit game (R + PAUSE)

### Dual analog support

The right stick on the extended controller profile is supported, but with a caveat:

- 1P right stick is mapped to 3P analog stick
- 2P right stick is mapped to 4P analog stick

So currently, 2 players can use dual sticks at the same time.

### Trigger buttons

The left trigger is mapped to -X values (-1 to 0) on the 3P analog stick, and the right trigger is mapped to +X values (0 to 1) on the 3P analog stick. 

I'm not sure if this is the best setup for it, so suggestions are welcome.

