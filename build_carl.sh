#!/bin/bash

# Valid: Release or Debug
BUILD_TYPE=${BUILD_TYPE:-Release}

mkdir CARL_build
pushd CARL_build >/dev/null
cmake ../CARL -DCMAKE_BUILD_TYPE=$BUILD_TYPE
make
popd >/dev/null

if [ -n "$ANDROID_NDK_HOME" ]; then
	mkdir CARL_build_android
	pushd CARL_build_android >/dev/null
	cmake ../CARL -DCMAKE_SYSTEM_NAME=Android -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_ANDROID_ARCH_ABI="arm64-v8a" -DCMAKE_ANDROID_NDK="$ANDROID_NDK_HOME"
	make
	popd >/dev/null
else
	echo " ** ANDROID_NDK_HOME is not defined - skipping Android build"
fi
