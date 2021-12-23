#!/bin/sh

## detect if we are run from Xcode and need to do a CLEAN first
if [ "$TARGET_BUILD_DIR" != "" ] && [ $(ls -1 "$TARGET_BUILD_DIR" | wc -l) -lt 2 ]; then
    make macCatalyst=1 ARCH=arm64  clean
    make macCatalyst=1 ARCH=x86_64 clean
fi

make macCatalyst=1 ARCH=arm64  -j`sysctl -n hw.logicalcpu` CDBG=-w $@ || exit -1
make macCatalyst=1 ARCH=x86_64 -j`sysctl -n hw.logicalcpu` CDBG=-w $@ || exit -1

if [ "$1" == "clean" ]; then
    rm libmame-139u1-mac*.a
else
    lipo -create libmame-139u1-mac-*.a -output libmame-139u1-mac.a
    rm libmame-139u1-mac-*.a
fi
