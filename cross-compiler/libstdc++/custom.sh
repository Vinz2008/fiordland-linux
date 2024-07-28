#!/bin/bash
# there will be a lot of hardcoded paths, but it is neede because we build in the folder of a different packages, but we need to do it after some other packages


cd ../staging/gcc-13.2.0
rm -rf build
mkdir -v build
cd build

../libstdc++-v3/configure           \
    --host=$(uname -m)-lfs-linux-gnu  \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$(uname -m)-lfs-linux-gnu/include/c++/13.2.0

make -j$(nproc)
make DESTDIR=$ROOTFS install
rm -fv $ROOTFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la