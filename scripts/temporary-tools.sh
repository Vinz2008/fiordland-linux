# TEMPORARY TOOLS

SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
TARGET_VAR=$(uname -m)-lfs-linux-gnu
export PATH=$PATH:$ROOTFS/cross-tools/bin
sudo chmod a=rwx rootfs/* -R

cd $STAGING
wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
wget -nc -O m4.tar.xz https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
wget -nc -O ncurses.tar.gz https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz
wget -nc -O bash.tar.gz https://ftp.gnu.org/gnu/bash/bash-5.1.16.tar.gz
wget -nc -O coreutils.tar.xz https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz
wget -nc -O diffutils.tar.xz https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz
wget -nc -O file.tar.gz https://astron.com/pub/file/file-5.41.tar.gz
wget -nc -O findutils.tar.xz https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
wget -nc -O gawk.tar.xz https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz
wget -nc -O grep.tar.xz https://ftp.gnu.org/gnu/grep/grep-3.7.tar.xz
wget -nc -O gzip.tar.xz https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz
wget -nc -O make.tar.gz https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
wget -nc -O patch.tar.xz https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
wget -nc -O sed.tar.xz https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz
wget -nc -O tar.tar.xz https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz
wget -nc -O xz.tar.xz https://tukaani.org/xz/xz-5.2.5.tar.xz
wget -nc -O binutils.tar.xz https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz
wget -nc -O gcc.tar.xz https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
wget -nc -O mpfr.tar.xz https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
wget -nc -O gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget -nc -O mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz


set -ex

cd $STAGING
tar -xvf m4.tar.xz
cd m4-1.4.19
./configure --prefix=/usr   \
            --host=$TARGET_VAR \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf m4-1.4.19
tar -xvf ncurses.tar.gz
cd ncurses-6.3
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include -j$(nproc)
  make -C progs tic -j$(nproc)
popd
./configure --prefix=/usr                \
            --host=$TARGET_VAR              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --disable-stripping          \
            --enable-widec
make -j$(nproc)
make DESTDIR=$ROOTFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $ROOTFS/usr/lib/libncurses.so

cd $STAGING
rm -rf ncurses-6.3
tar -xvf bash.tar.gz
cd bash-5.1.16
./configure --prefix=/usr                   \
            --build=$(support/config.guess) \
            --host=$TARGET_VAR                 \
            --without-bash-malloc
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)
ln -svf bash $ROOTFS/bin/sh

cd $STAGING
rm -rf bash-5.1.16
tar -xvf coreutils.tar.xz
cd coreutils-9.0
./configure --prefix=/usr                     \
            --host=$TARGET_VAR                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)
mv -v $ROOTFS/usr/bin/chroot $ROOTFS/usr/sbin
mkdir -pv $ROOTFS/usr/share/man/man8
mv -v $ROOTFS/usr/share/man/man1/chroot.1 $ROOTFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $ROOTFS/usr/share/man/man8/chroot.8

cd $STAGING
rm -rf coreutils-9.0
tar -xvf diffutils.tar.xz
cd diffutils-3.8
./configure --prefix=/usr --host=$TARGET_VAR
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf diffutils-3.8
tar -xvf file.tar.gz
cd file-5.41
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make -j$(nproc)
popd
./configure --prefix=/usr --host=$TARGET_VAR --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf file-5.41
tar -xvf findutils.tar.xz
cd findutils-4.9.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$TARGET_VAR                \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf findutils-4.9.0
tar -xvf gawk.tar.xz
cd gawk-5.1.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$TARGET_VAR \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf gawk-5.1.1
tar -xvf grep.tar.xz
cd grep-3.7
./configure --prefix=/usr   \
            --host=$TARGET_VAR
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)


cd $STAGING
rm -rf grep-3.7
tar -xvf gzip.tar.xz
cd gzip-1.11
./configure --prefix=/usr --host=$TARGET_VAR
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf gzip-1.11
tar -xvf make.tar.gz
cd make-4.3
./configure --prefix=/usr   \
            --without-guile \
            --host=$TARGET_VAR \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf make-4.3
tar -xvf patch.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$TARGET_VAR \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf patch-2.7.6
tar -xvf sed.tar.xz
cd sed-4.8
./configure --prefix=/usr   \
            --host=$TARGET_VAR
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf sed-4.8
tar -xvf tar.tar.xz
cd tar-1.34
./configure --prefix=/usr                     \
            --host=$TARGET_VAR                   \
            --build=$(build-aux/config.guess)
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)


cd $STAGING
rm -rf tar-1.34
tar -xvf xz.tar.xz
cd xz-5.2.5
./configure --prefix=/usr                     \
            --host=$TARGET_VAR                  \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)


cd $STAGING
rm -rf xz-5.2.5
tar -xvf binutils.tar.xz
cd binutils-2.38
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build
cd build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$TARGET_VAR            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $STAGING
rm -rf binutils-2.38
tar -xvf gcc.tar.xz
cd gcc-11.2.0
tar -xf ../mpfr.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc.tar.gz
mv -v mpc-1.2.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd build
mkdir -pv $TARGET_VAR/libgcc
ln -s ../../../libgcc/gthr-posix.h $TARGET_VAR/libgcc/gthr-default.h
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$TARGET_VAR                               \
    --prefix=/usr                                  \
    CC_FOR_TARGET=$TARGET_VAR-gcc                     \
    --with-build-sysroot=$ROOTFS                      \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)
ln -sv gcc $ROOTFS/usr/bin/cc
cd ../..
rm -rf gcc-11.2.0