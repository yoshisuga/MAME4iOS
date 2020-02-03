#!/bin/sh
make clean
make iOSSIMULATOR=1 -j 32 CDBG=-w
cp libmamearm64.a libmamearm64-tvos.a
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
