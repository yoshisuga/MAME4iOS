#!/bin/sh
make clean
make iOSSIMULATOR=1 -j`sysctl -n hw.logicalcpu` CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
