#!/bin/bash

Scheme_Name="AgoraMessageTubeKit"
echo "Scheme_Name: ${Scheme_Name}"

TARGETNAME="AgoraMessageTubeKit"
echo "TARGETNAME: ${TARGETNAME}"

currentPath=`pwd`
echo "currentPath: ${currentPath}"

buildFolder="${currentPath}/build"
echo "build folder path: ${buildFolder}"

if [ -e "$buildFolder" ] 
then
    rm -r "${buildFolder}"
    echo "remove build folder path: ${buildFolder}"
fi

xcodebuild clean build -project "AgoraMessageTubeKit.xcodeproj" -target $TARGETNAME -configuration Debug -sdk iphonesimulator -arch i386 -arch x86_64
xcodebuild clean build -project "AgoraMessageTubeKit.xcodeproj"  -target $TARGETNAME -configuration Debug -sdk iphoneos -arch armv7 -arch armv7s -arch arm64

cd "${buildFolder}"
finalFolder="${buildFolder}/FinalFramework"

mkdir "${finalFolder}"
echo "finalFolder: ${finalFolder}"

lipo -create Debug-iphoneos/AgoraMessageTubeKit.framework/AgoraMessageTubeKit Debug-iphonesimulator/AgoraMessageTubeKit.framework/AgoraMessageTubeKit -output AgoraMessageTubeKit

oldFrameworkFolder="${buildFolder}/Debug-iphoneos/AgoraMessageTubeKit.framework"
cp -r "${oldFrameworkFolder}" "${finalFolder}"

oldFrameworkFile="${finalFolder}/AgoraMessageTubeKit.framework/AgoraMessageTubeKit"
echo "oldFrameworkFile: ${oldFrameworkFile}"

rm -f "${oldFrameworkFile}"
mv AgoraMessageTubeKit "${finalFolder}/AgoraMessageTubeKit.framework"