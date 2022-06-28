KERNEL_VERSION=5.18.1
#KERNEL_VERSION=4.9.22
BUSYBOX_VERSION=1.34.1
BINUTILS_VERSION=2.27
IANA_ETC_VERSION=2.30
GCC_VERSION=6.2.0
MUSL_VERSION=1.1.16


ARCH_VAR=$(uname -m)
TARGET_VAR=$ARCH_VAR-pc-linux-gnu


mkdir -p rootfs
mkdir -p staging
mkdir -p iso/boot

SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
ISO_DIR=$SOURCE_DIR/iso

mkdir -p $ROOTFS/{bin,boot,dev,sys,home,mnt,proc,run,tmp,var,etc,sbin,lib/{firmware,modules}} $ROOTFS/usr/{,local/}{bin,include,lib,sbin,share/{color,dict,doc,info,locale,man,misc,terminfo,zoneinfo}} $ROOTFS/var/{cache,lib,local,lock,opt,run,spool,empty,log}
touch $ROOTFS/var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp $ROOTFS/var/log/lastlog
chmod -v 664  $ROOTFS/var/log/lastlog
chmod -v 600  $ROOTFS/var/log/btmp
mkdir -p $ROOTFS/media/{floppy,cdrom}
ln -sfv $ROOTFS/run $ROOTFS/var/run
ln -sfv $ROOTFS/run/lock $ROOTFS/var/lock
install -dv -m 0750 $ROOTFS/root
install -dv -m 1777 $ROOTFS/{var/,}tmp
touch $ROOTFS/var/log/lastlog
chmod -v 664 $ROOTFS/var/log/lastlog
mkdir -pv $ROOTFS/etc/network/if-{post-{up,down},pre-{up,down},up,down}.d
mkdir -pv $ROOTFS/usr/share/udhcpc
chmod +x $ROOTFS/usr/share/udhcpc/default.script
ln -sv $ROOTFS/proc/self/mounts $ROOTFS/etc/mtab
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3




cp -v -r $AIROOTFS/* $ROOTFS 


cd $STAGING
wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
#wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VERSION}.tar.xz
#wget -nc -O binutils.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
wget -nc -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
wget -nc -O iana-etc.tar.bz2 http://sethwklein.net/iana-etc-${IANA_ETC_VERSION}.tar.bz2
wget -nc -O iana-etc-patch.patch  http://patches.clfs.org/embedded-dev/iana-etc-${IANA_ETC_VERSION}-update-2.patch
#wget -nc -O gcc.tar.bz2  http://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
#wget -nc -O musl.tar.gz http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz
#wget -nc -O mpfr.tar.bz2 http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.bz2
#wget -nc -O mpc.tar.gz http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
#wget -nc -O gmp.tar.bz2 http://ftp.gnu.org/gnu/gmp/gmp-6.1.1.tar.bz2


tar -xvf kernel.tar.xz
tar -xvf busybox.tar.bz2
#tar -xvf binutils.tar.bz2
tar -xvf iana-etc.tar.bz2
#tar -xvf gcc.tar.bz2
#tar -xvf musl.tar.gz

mkdir -p $ROOTFS/cross-tools/$TARGET_VAR
ln -sfv $ROOTFS/cross-tools/$TARGET_VAR $ROOTFS/cross-tools/$TARGET_VAR/usr




set -ex

# CROSS TOOLCHAIN
: '
cd $STAGING
cd binutils-$BINUTILS_VERSION
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v ../binutils-build
cd ../binutils-build
../binutils-2.27/configure \
   --prefix=$ROOTFS/cross-tools \
   --target=${TARGET_VAR} \
   --with-sysroot=$ROOTFS \
   --disable-nls \
   --disable-werror
make configure-host -j$(nproc)
make -j$(nproc)
make install -j$(nproc)
'
: '
cd $STAGING
cd gcc-${GCC_VERSION}
tar xf ../mpfr.tar.bz2
mv -v mpfr-3.1.4 mpfr
tar xf ../gmp.tar.bz2
mv -v gmp-6.1.1 gmp
tar xf ../mpc.tar.gz
mv -v mpc-1.0.3 mpc
if [$ARCH_VAR == x86_64]; then
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
fi
'
: '
mkdir -v build
cd build
../configure                  \
    --target=$TARGET_VAR        \
    --prefix=${ROOTFS}/cross-tools       \
    --with-glibc-version=2.35 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-initfini-array   \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-decimal-float   \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
make -j$(nproc)
make install -j$(nproc)

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($TARGET_VAR-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

cd $STAGING
cd linux-${KERNEL_VERSION}
make mrproper -j$(nproc)
make headers_check -j$(nproc)
make INSTALL_HDR_PATH=$ROOTFS/cross-tools/$TARGET_VAR headers_install -j$(nproc)

cd $STAGING
cd gcc-${GCC_VERSION}
rm -rf build
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$TARGET_VAR                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=${ROOTFS}/cross-tools/include/c++/11.2.0
make -j$(nproc)
make DESTDIR=$ROOTFS install

cd $STAGING
cd musl-$MUSL_VERSION

CC=gcc  ./configure \
  CROSS_COMPILE=${TARGET_VAR}-gcc- \
  --prefix=/ \
  --target=${TARGET_VAR}

make -j$(nproc)
DESTDIR=${ROOTFS}/cross-tools/${TARGET_VAR} make install -j$(nproc)




cd $STAGING
cd gcc-${GCC_VERSION}
tar xf ../mpfr.tar.bz2
mv -v mpfr-3.1.4 mpfr
tar xf ../gmp.tar.bz2
mv -v gmp-6.1.1 gmp
tar xf ../mpc.tar.gz
mv -v mpc-1.0.3 mpc

mkdir -v build
cd build
../configure \
  --prefix=$ROOTFS/usr \
  --target=${TARGET_VAR} \
  --with-sysroot=${ROOTFS}/cross-tools/${TARGET_VAR} \
  --with-newlib \
  --enable-initfini-array \
  --disable-nls \
  --enable-languages=c,c++ \
  --enable-c99 \
  --enable-long-long \
  --disable-libmudflap \
  --disable-multilib \
  --disable-libstdcxx \

make -j$(nproc)
make install -j$(nproc)
'

: '
rm -f $STAGING/config
touch $STAGING/config
echo export CC=\""${TARGET_VAR}-gcc --sysroot=${ROOTFS}/targetfs\"" >> $STAGING/config
echo export CXX=\""${TARGET_VAR}-g++ --sysroot=${ROOTFS}/targetfs\"" >> $STAGING/config
echo export AR=\""${TARGET_VAR}-ar\"" >> $STAGING/config
echo export AS=\""${TARGET_VAR}-as\"" >> $STAGING/config
echo export LD=\""${TARGET_VAR}-ld --sysroot=${ROOTFS}/targetfs\"" >> $STAGING/config
echo export RANLIB=\""${TARGET_VAR}-ranlib\"" >> $STAGING/config
echo export READELF=\""${TARGET_VAR}-readelf\"" >> $STAGING/config
echo export STRIP=\""${TARGET_VAR}-strip\"" >> $STAGING/config
echo export PATH=\""${ROOTFS}/cross-tools/bin:${PATH}\"" >> $STAGING/config
source $STAGING/config
'

# INSTALLING SYSTEM PROGRAMS
: '
cp -v ${ROOTFS}/cross-tools/${TARGET_VAR}/lib/libgcc_s.so.1 ${ROOTFS}/lib/
${TARGET_VAR}-strip ${ROOTFS}/lib/libgcc_s.so.1

cd $STAGING
cd musl-$MUSL_VERSION
./configure \
  CROSS_COMPILE=${TARGET_VAR}- \
  --prefix=/ \
  --disable-static \
  --target=${TARGET_VAR}

make -j$(nproc)
DESTDIR=$ROOTFS make install-libs -j$(nproc)
'

cd $STAGING
cd busybox-${BUSYBOX_VERSION}
make distclean
make defconfig


sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
echo "CONFIG_STATIC_LIBGCC=y" >> .config

make  -j$(nproc)
make CONFIG_PREFIX="${ROOTFS}" install -j$(nproc)



#make busybox install -j$(nproc)
#cd _install
#cp -r ./ $ROOTFS/
cd $ROOTFS
rm -f linuxrc

cd $STAGING
cd iana-etc-${IANA_ETC_VERSION}
patch -Np1 -i ../iana-etc-patch.patch
make get
make STRIP=yes -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)

cd $ROOTFS
mkdir -p bin dev mnt proc sys tmp

#cp $SOURCE_DIR/misc-files/init $ROOTFS/boot/initrd
#chmod +x $ROOTFS/boot/initrd



#mkdir $SOURCE_DIR/INITRAMFS_BUILD
#cd $SOURCE_DIR/INITRAMFS_BUILD
cp $SOURCE_DIR/misc-files/init .
chmod a+x init
#cp -f $STAGING/busybox-${BUSYBOX_VERSION}/busybox bin/busybox
ln -sf busybox bin/sh 2> /dev/null
echo "Creating initramfs cpio archive"
find . -print0 | cpio --null -ov --format=newc | gzip --best > $SOURCE_DIR/iso/boot/rootfs.gz
#cd $ROOTFS
#find . | cpio --null -ov --format=newc | gzip --best > $SOURCE_DIR/iso/boot/rootfs.gz

cd $STAGING
cd linux-${KERNEL_VERSION}
make mrproper
cp "$SOURCE_DIR/misc-files/linux.config" '.config'
make olddefconfig
#make ${ARCH_VAR}_defconfig
#make -j$(nproc) defconfig
make -j$(nproc)
grep -q '^CONFIG_MODULES=y$' .config && make modules -j$(nproc) && make INSTALL_MOD_PATH=$ROOTFS/usr INSTALL_MOD_STRIP=1 modules_install

make INSTALL_HDR_PATH=$ROOTFS/usr INSTALL_MOD_STRIP=1 headers_install

cp System.map $SOURCE_DIR/iso/boot/System.map
cp -f "arch/x86/boot/"*Image "$SOURCE_DIR/iso/boot/vmlinuz"

cd $SOURCE_DIR/iso/boot
mkdir -p grub
cd grub
cat > grub.cfg << EOF
set default=0
set timeout=30
# Menu Colours
set menu_color_normal=white/black
set menu_color_highlight=white/green
root (hd0,0)
menuentry "fiordland" {      
    linux  /boot/vmlinuz
    initrd /boot/rootfs.gz
}
EOF

cd $SOURCE_DIR
grub-mkrescue --compress=xz -o fiordland.iso iso 
set +ex