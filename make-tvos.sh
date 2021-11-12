#!/bin/sh

if [ "$1" == "simulator" ]; then
    export iOSSIMULATOR=1
    shift
fi

make tvOS=1 -j`sysctl -n hw.logicalcpu` CDBG=-w OSVERSION=12.4 $@ || exit -1
