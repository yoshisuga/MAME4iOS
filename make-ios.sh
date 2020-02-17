#!/bin/sh
make clean
make -j`sysctl -n hw.logicalcpu` CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
