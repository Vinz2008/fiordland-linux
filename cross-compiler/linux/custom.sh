#!/bin/bash
package_folder=$1
install_folder=../../../cross-tools

cd $package_folder
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $install_folder/usr