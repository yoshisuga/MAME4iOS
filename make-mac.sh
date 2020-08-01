#!/bin/sh
make macCatalyst=1 clean
make macCatalyst=1 -j`sysctl -n hw.logicalcpu` CDBG=-w
open xcode/MAME4iOS/MAME4iOS.xcodeproj/
