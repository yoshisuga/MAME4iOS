#!/bin/sh

C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_RESET="\033[0m"

echo "${C_RED}Before running, edit the TEAM identifier in the .xcconfig files so that code signing works.${C_RESET}\n\n"

declare -a SCHEMES=("MAME4iOS Release" "MAME tvOS Release" "MAME4mac Release")
declare -a SCHEME_NAMES=("MAME4iOS" "MAME4tvOS" "MAME4mac")
declare -a CONFIGS=("MAME4iOS.xcconfig" "MAME4iOS-latest.xcconfig")
declare -a CONFIG_NAMES=("139" "latest")

for i in "${!SCHEMES[@]}"
do
  SCHEME="${SCHEMES[$i]}"
  NAME="${SCHEME_NAMES[$i]}"
  echo "${C_BLUE}Scheme: ${SCHEME}${C_RESET}"
  for j in "${!CONFIGS[@]}"
  do
    CONFIG="${CONFIGS[$j]}"
    ARCHIVE_NAME="${NAME}-${CONFIG_NAMES[$j]}"
    echo "${C_BLUE}Config: ${CONFIG} Archive: ${ARCHIVE_NAME}${C_RESET}"
    xcodebuild -project MAME4iOS.xcodeproj \
    -config Release -scheme "${SCHEME}" \
    -archivePath "../dist/${ARCHIVE_NAME}" \
    -xcconfig ${CONFIG} \
    -allowProvisioningUpdates \
    archive

    xcodebuild -exportArchive \
    -archivePath "../dist/${ARCHIVE_NAME}.xcarchive" \
    -exportOptionsPlist exportOptions.plist \
    -exportPath ../dist \
    -allowProvisioningUpdates

    # exportArchive will create an IPA file named: ${PRODUCT_NAME}.ipa (you can't specify the filename of the IPA)
    mv ../dist/${NAME}.ipa ../dist/${ARCHIVE_NAME}.ipa
    # do the mac app too    
    mv ../dist/${NAME}.app ../dist/${ARCHIVE_NAME}.app
  done
done
