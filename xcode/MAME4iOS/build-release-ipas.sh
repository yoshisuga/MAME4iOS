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

declare -a SCHEMES=("MAME4iOS Release" "MAME tvOS Release" "MAME4mac Release")
declare -a SCHEME_NAMES=("MAME4iOS" "MAME4tvOS" "MAME4mac")
declare -a CONFIGS=("MAMELIB=libmame-139u1" "MAMELIB=libmame")
declare -a CONFIG_NAMES=("139" "latest")

for i in "${!SCHEMES[@]}"
do
  SCHEME="${SCHEMES[$i]}"
  NAME="${SCHEME_NAMES[$i]}"
  for j in "${!CONFIGS[@]}"
  do
    CONFIG="${CONFIGS[$j]}"
    ARCHIVE_NAME="${NAME}-${VERSION}-${CONFIG_NAMES[$j]}"
    echo "${C_BLUE}Scheme: ${SCHEME} Config: ${CONFIG} Archive: ${ARCHIVE_NAME}${C_RESET}"

    xcodebuild -project MAME4iOS.xcodeproj \
        -scheme "${SCHEME}" \
        -archivePath "../dist/${ARCHIVE_NAME}" \
        -allowProvisioningUpdates \
        ${CONFIG} \
        archive || exit -1
        
    xcodebuild -exportArchive \
        -archivePath "../dist/${ARCHIVE_NAME}.xcarchive" \
        -exportOptionsPlist "../dist/exportOptions.plist" \
        -exportPath ../dist \
        -allowProvisioningUpdates || exit -1

    # exportArchive will create an IPA file named: ${PRODUCT_NAME}.ipa (you can't specify the filename of the IPA)
    mv ../dist/${NAME}.ipa ../dist/${ARCHIVE_NAME}.ipa
    # do the mac app too
    mv ../dist/${NAME}.app ../dist/${ARCHIVE_NAME}.app
  done
done
