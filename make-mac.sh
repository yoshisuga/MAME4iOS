#!/bin/sh
make macCatalyst=1 ARCH=arm64 clean
make macCatalyst=1 ARCH=arm64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1

make macCatalyst=1 ARCH=x86_64 clean
make macCatalyst=1 ARCH=x86_64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1

lipo -create libmame-mac-*.a -output libmame-mac.a
rm libmame-mac-*.a

open xcode/MAME4iOS/MAME4iOS.xcodeproj/
