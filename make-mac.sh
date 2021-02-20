#!/bin/sh
make macCatalyst=1 clean
make macCatalyst=1 ARCH=arm64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1
cp libmamearm64-mac.a libmamearm64-mac-arm64.a

make macCatalyst=1 clean
make macCatalyst=1 ARCH=x86_64 -j`sysctl -n hw.logicalcpu` CDBG=-w || exit -1
cp libmamearm64-mac.a libmamearm64-mac-x64.a

lipo -create libmamearm64-mac-x64.a libmamearm64-mac-arm64.a -output libmamearm64-mac.a
rm libmamearm64-mac-x64.a libmamearm64-mac-arm64.a

open xcode/MAME4iOS/MAME4iOS.xcodeproj/
