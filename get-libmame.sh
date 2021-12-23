#!/bin/sh

##
## get-libmame.sh [target] [clean | source]
##
## get version of libmame from MAME project, or the web
##
## target is one of the following
##      ios     get libmame-ios.a for iOS
##      tvos    get libmame-tvos.a for tvOS
##      mac     get libmame-mac.a for Catalyst
##      all     get all
##
## source is path to MAME project or blank for default (../MAME)
##

if [ "$1" == "" ] || [ "$1" == "clean" ]; then
    $0 ios $1
    exit
fi

if [ "$1" == "all" ]; then
    $0 ios $2
    $0 tvos $2
    $0 mac $2
    exit
fi

if [ "$1" != "ios" ] && [ "$1" != "tvos" ] && [ "$1" != "mac" ] && [ "$1" != "ios-simulator" ] && [ "$1" != "tvos-simulator" ]; then
    echo "USAGE: $0 [ios | tvos | mac | all] [path to MAME]"
    exit
fi

LIBMAME="libmame-$1.a"
LIBMAME_URL="https://github.com/ToddLa/mame/releases/latest/download/$LIBMAME.gz"

## only do a clean and get out
if [ "$2" == "clean" ]; then
    echo CLEAN $LIBMAME
    rm -f $LIBMAME
    exit
fi

## copy from local custom build
if [ -f "$2/$LIBMAME" ]; then
    echo COPY "$2/$LIBMAME"
    cp "$2/$LIBMAME" .
    exit
fi

## copy from local custom build
if [ -f "../MAME/$LIBMAME" ]; then
    echo COPY "../MAME/$LIBMAME"
    cp "../MAME/$LIBMAME" .
    exit
fi

## download from GitHub if no local version, *or* version on GitHub is newer
if [ ! -f "$LIBMAME" ] || [ 200 == `curl --silent --head --output /dev/null --write-out "%{http_code}" -z $LIBMAME -L $LIBMAME_URL` ]; then
    echo DOWNLOAD $LIBMAME
    curl -L $LIBMAME_URL | gunzip > $LIBMAME || (rm -r $LIBMAME; echo "DOWNLOAD $LIBMAME ** FAILED")
fi

