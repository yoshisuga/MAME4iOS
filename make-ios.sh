#!/bin/sh

if [ "$1" == "simulator" ]; then
    export iOSSIMULATOR=1
    shift
fi

make -j`sysctl -n hw.logicalcpu` CDBG=-w $@ || exit -1
