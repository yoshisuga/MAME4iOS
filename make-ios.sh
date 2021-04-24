#!/bin/sh
if [ "$1" != "noclean" ]; then
    make clean
fi

make -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1

if [ "$1" != "noclean" ]; then
    open xcode/MAME4iOS/MAME4iOS.xcodeproj/
fi

