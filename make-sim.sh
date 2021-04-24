#!/bin/sh
make clean
make iOSSIMULATOR=1 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
