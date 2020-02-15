#!/bin/sh
make clean
make tvOS=1 -j`sysctl -n hw.logicalcpu` CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
