#!/bin/sh

C_RED="\033[0;91m"
C_WHITE="\033[0;97m"
C_BLUE="\033[0;94m"
C_RESET="\033[0m"

# get the DEVELOPMENT_TEAM and VERSION out of the xcconfig(s)
if [ -f Developer.xcconfig ]; then
    DEVELOPMENT_TEAM=`grep -oe "^DEVELOPMENT_TEAM\s*=\s*[a-zA-Z0-9]*" Developer.xcconfig | cut -w -f3`
fi
if [ "$DEVELOPMENT_TEAM" == "" ]; then
    DEVELOPMENT_TEAM=`grep -oe "^DEVELOPMENT_TEAM\s*=\s*[a-zA-Z0-9]*" MAME4iOS.xcconfig | cut -w -f3`
fi

if [ -f Developer.xcconfig ]; then
    VERSION=`grep -oe "^CURRENT_PROJECT_VERSION\s*=\s*[\.0-9]*" Developer.xcconfig | cut -w -f3`
fi
if [ "$VERSION" == "" ]; then
    VERSION=`grep -oe "^CURRENT_PROJECT_VERSION\s*=\s*[\.0-9]*" MAME4iOS.xcconfig | cut -w -f3`
fi

if [ "$DEVELOPMENT_TEAM" == "" ] || [ "$DEVELOPMENT_TEAM" == "ABC8675309" ]; then
    echo "${C_RED}Before running, edit the DEVELOPMENT_TEAM identifier in the .xcconfig file so that code signing works.${C_RESET}"
    echo "${C_RED}DEVELOPMENT_TEAM = ${DEVELOPMENT_TEAM}${C_RESET}"
    exit -1
fi

if [ "$1" == "clean" ]; then
    rm -r ../dist
    exit
fi

# get the latest MAME version
MAMELIB="../../libmame-ios.a"

if [ ! -f $MAMELIB ]; then
    pushd ../..
    ./get-libmame.sh
    popd
fi

# look for the version string inside the MAMELIB ie "0.248 (mame0248-96-gc00e10bd5de)"
MAMELIB_VERSION=`strings $MAMELIB | grep -e "^0\.[0-9]* (mame0" | cut -w -f1 | cut -d . -f2`

# create a exportOptions.plist with the correct DEVELOPMENT_TEAM
[ -d ../dist ] || mkdir ../dist
cat << EOF > "../dist/exportOptions.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${DEVELOPMENT_TEAM}</string>
    <key>iCloudContainerEnvironment</key>
    <string>Development</string>
</dict>
</plist>
EOF

declare -a SCHEMES=("MAME4iOS Release" "MAME tvOS Release" "MAME4iOS Release")
declare -a SCHEME_NAMES=("MAME4iOS" "MAME4tvOS" "MAME4mac")
declare -a SCHEME_DESTS=("generic/platform=iOS" "generic/platform=tvOS" "generic/platform=macOS,variant=Mac Catalyst,name=Any Mac")
declare -a CONFIGS=("MAMELIB=libmame-139u1" "MAMELIB=libmame")
declare -a CONFIG_NAMES=("139" "latest")

for i in "${!SCHEMES[@]}"
do
  SCHEME="${SCHEMES[$i]}"
  NAME="${SCHEME_NAMES[$i]}"
  DEST="${SCHEME_DESTS[$i]}"
  for j in "${!CONFIGS[@]}"
  do
    CONFIG="${CONFIGS[$j]}"
    CONFIG_NAME="${CONFIG_NAMES[$j]}"
    if [ "$CONFIG_NAME" == "latest" ] && [ "$MAMELIB_VERSION" != "" ]; then
        CONFIG_NAME="$MAMELIB_VERSION"
    fi
    
    ARCHIVE_NAME="${NAME}-${VERSION}-${CONFIG_NAME}"
    echo "${C_BLUE}Scheme:${C_WHITE}${SCHEME} ${C_BLUE}Config:${C_WHITE}${CONFIG} ${C_BLUE}SDK:${C_WHITE}${SDK} ${C_BLUE}Archive:${C_WHITE}${ARCHIVE_NAME}${C_RESET}"

    xcodebuild -project MAME4iOS.xcodeproj \
        -scheme "${SCHEME}" \
        -archivePath "../dist/${ARCHIVE_NAME}" \
        -allowProvisioningUpdates \
        -destination "${DEST}" \
        ${CONFIG} \
        archive || exit -1
        
    xcodebuild -exportArchive \
        -archivePath "../dist/${ARCHIVE_NAME}.xcarchive" \
        -exportOptionsPlist "../dist/exportOptions.plist" \
        -exportPath ../dist \
        -allowProvisioningUpdates || exit -1

    # exportArchive will create an IPA file named: ${PRODUCT_NAME}.ipa (you can't specify the filename of the IPA)
    if [ "${NAME}" == "MAME4mac" ]; then
        mv ../dist/MAME4iOS.app ../dist/${ARCHIVE_NAME}.app || exit -1
    else
        mv ../dist/${NAME}.ipa ../dist/${ARCHIVE_NAME}.ipa || exit -1
    fi
  done
done
