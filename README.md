# MAME4iOS

Original Author: David Valdeita (Seleuco)<br/>

This is a port of MAME for iOS. The currently supported rom set version is 0.139.

It has been updated to compile and run on Xcode 7/iOS 9 by Les Bird (http://www.lesbird.com/iMame4All/iMame4All_Xcode.html), and he has graciously added support for mFi Controllers.

## Installation / Sideloading

Requirements: Mac with Xcode 7

Building MAME4iOS requires a prebuilt MAME binary. This is done by running `make` at the root directory of the project. You can download a prebuilt binary here: https://mega.nz/#!HVYj2Yqa!u7W2zvPLRQ7T4TAoMqGR2NZtjEl90HMTSXUQzD-2gRE It will work for most modern iOS devices.

Even if you are not in the paid Apple Developer Program, you can sideload the app using a Mac with Xcode 7.

1. Open the Xcode project in `xcode/MAME4iOS/MAME4iOS.xcodeproj`
1. If you are a developer, build and run on your device
1. If you are not a developer, open Preferences and add your Apple ID, select your Personal Team, and create an iOS Development Profile.
1. Select the project name on the left pane and make sure your personal team is selected
1. Hit the run button to install on your device

## mFi Controller Support

Pair your mFi controller with your iOS device, and it should 'just work'. If you have an extended controller with dual analog sticks and shoulder triggers, you can use them! The shoulder triggers are mapped as analog controls so you can use them for things like pedals or other analog control.

