#!/bin/bash
cd $BUILD_FOLDER
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $ROOTFS/usr