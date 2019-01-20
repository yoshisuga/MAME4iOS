#!/bin/sh
make clean
make -j 32 CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
