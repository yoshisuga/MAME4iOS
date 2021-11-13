#!/bin/sh

if [ "$1" == "simulator" ]; then
    export iOSSIMULATOR=1
    shift
fi

## detect if we are run from Xcode and need to do a CLEAN first
if [ "TARGET_BUILD_DIR" != "" ] && [ $(ls -1 "$TARGET_BUILD_DIR" | wc -l) -lt 2 ]; then
    make clean
fi

make -j`sysctl -n hw.logicalcpu` CDBG=-w $@ || exit -1
