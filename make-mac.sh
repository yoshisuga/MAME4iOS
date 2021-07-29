#!/bin/sh
make macCatalyst=1 ARCH=arm64 clean
make macCatalyst=1 ARCH=arm64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1

make macCatalyst=1 ARCH=x86_64 clean
make macCatalyst=1 ARCH=x86_64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1

lipo -create libmame-139u1-mac-*.a -output libmame-139u1-mac.a
rm libmame-139u1-mac-*.a

open xcode/MAME4iOS/MAME4iOS.xcodeproj/
