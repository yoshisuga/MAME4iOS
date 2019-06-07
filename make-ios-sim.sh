#!/bin/sh
make clean
make iOSSIMULATOR=1 -j 32 CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
