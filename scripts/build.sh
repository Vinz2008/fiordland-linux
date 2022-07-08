KERNEL_VERSION=5.18.1
#KERNEL_VERSION=4.9.22
BUSYBOX_VERSION=1.34.1
BINUTILS_VERSION=2.27
IANA_ETC_VERSION=2.30
GCC_VERSION=6.2.0
MUSL_VERSION=1.1.16


ARCH_VAR=$(uname -m)
TARGET_VAR=$ARCH_VAR-unknown-linux-gnu
HOST_VAR=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')

CC=gcc

mkdir -p rootfs
mkdir -p staging
mkdir -p iso/boot
mkdir -p iso/efi/boot
mkdir -p iso/boot/grub/i386-pc
mkdir -p rootfs/tools
mkdir -p rootfs/cross-tools



SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
ISO_DIR=$SOURCE_DIR/iso

export PATH=$PATH:$ROOTFS/cross-tools/bin


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
mknod -m 600 $ROOTFS/dev/console c 5 1
mknod -m 666 $ROOTFS/dev/null c 1 3
mknod -m 600 $ROOTFS/lib/udev/devices/console c 5 1
mknod -m 666 $ROOTFS/lib/udev/devices/null c 1 3



cp -v -r $AIROOTFS/* $ROOTFS 

# CROSS COMPILATION TOOLS
cd $STAGING

wget -nc -O bc.tar.bz2 http://alpha.gnu.org/gnu/bc/bc-1.06.95.tar.bz2
wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
wget -nc -O file.tar.gz ftp://ftp.astron.com/pub/file/file-5.15.tar.gz
wget -nc -O m4.tar.xz http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.xz
wget -nc -O ncurses.tar.gz ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz
wget -nc -O ncurses-bash.patch http://patches.cross-lfs.org/2.1.0/ncurses-5.9-bash_fix-1.patch
wget -nc -O gmp.tar.xz http://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.xz
wget -nc -O mpfr.tar.xz http://www.mpfr.org/mpfr-3.1.2/mpfr-3.1.2.tar.xz
wget -nc -O mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-1.0.1.tar.gz
wget -nc -O cloog.tar.gz http://www.bastoul.net/cloog/pages/download/cloog-0.18.0.tar.gz
wget -nc -O binutils.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-2.23.2.tar.bz2
wget -nc -O gcc.tar.bz2 ftp://gcc.gnu.org/pub/gcc/releases/gcc-4.8.1/gcc-4.8.1.tar.bz2
wget -nc -O gcc-branch_update.patch http://patches.cross-lfs.org/2.1.0/gcc-4.8.1-branch_update-3.patch
wget -nc -O gcc-pure64_specs.patch http://patches.cross-lfs.org/2.1.0/gcc-4.8.1-pure64_specs-1.patch
wget -nc -O eglibc.tar.xz https://launchpad.net/debian/+archive/primary/+sourcefiles/eglibc/2.18-2/eglibc_2.18.orig.tar.xz

tar -xvf bc.tar.bz2
tar -xvf kernel.tar.xz
tar -xvf file.tar.gz
tar -xvf m4.tar.xz
tar -xvf ncurses.tar.gz
tar -xvf gmp.tar.xz
tar -xvf mpfr.tar.xz
tar -xvf mpc.tar.gz
tar -xvf cloog.tar.gz
tar -xvf binutils.tar.bz2
tar -xvf gcc.tar.bz2
tar -xvf eglibc.tar.xz


set -ex

cd $STAGING
cd bc-1.06.95
./configure --prefix=$ROOTFS/cross-tools
make -j$(nproc)
make install -j$(nproc)


cd $STAGING
cd linux-${KERNEL_VERSION}
make mrproper
make ARCH=x86_64 INSTALL_HDR_PATH=$ROOTFS/tools headers_install


cd $STAGING
cd file-5.15
./configure --prefix=$ROOTFS/cross-tools --disable-static
make -j$(nproc)
make install -j$(nproc)

: '
cd $STAGING
cd m4-1.4.17
./configure --prefix=$ROOTFS/cross-tools
make -j$(nproc)
make install -j$(nproc)
'

: '
cd $STAGING
cd ncurses-5.9
patch -Np1 -i ../ncurses-bash.patch
./configure --prefix=$ROOTFS/cross-tools --without-debug --without-shared
make -C include -j$(nproc)
make -C progs tic -j$(nproc)
install -v -m755 progs/tic /cross-tools/bin


cd $STAGING
cd gmp-5.1.3
./configure --prefix=$ROOTFS/cross-tools --enable-cxx --disable-static
make -j$(nproc)
make install -j$(nproc)

cd $STAGING
cd mpfr-3.1.2
LDFLAGS="-Wl,-rpath,$ROOTFS/cross-tools/lib" ./configure --prefix=$ROOTFS/cross-tools --disable-static --with-gmp=$ROOTFS/cross-tools
make -j$(nproc)
make install -j$(nproc)

cd $STAGING
cd mpc-1.0.1
LDFLAGS="-Wl,-rpath,$ROOTFS/cross-tools/lib" ./configure --prefix=$ROOTFS/cross-tools --disable-static --with-gmp=$ROOTFS/cross-tools --with-mpfr=$ROOTFS/cross-tools
make -j$(nproc)
make install -j$(nproc)

cd $STAGING
cd cloog-0.18.0
LDFLAGS="-Wl,-rpath,$ROOTFS/cross-tools/lib" . ./configure --prefix=$ROOTFS/cross-tools --disable-static --with-gmp-prefix=$ROOTFS/cross-tools
make -j$(nproc)
make install -j$(nproc)

cd $STAGING
cd binutils-2.23.2
sed -i -e 's/@colophon/@@colophon/' -e 's/~doc at cygnus.com/doc@@cygnus.com/' bfd/doc/bfd.texinfo
mkdir -v ../binutils-build
cd ../binutils-build
AR=ar AS=as ../binutils-2.23.2/configure \
  --prefix=$ROOTFS/cross-tools --host=${HOST_VAR} --target=${TARGET_VAR} \
  --with-sysroot=${ROOTFS} --with-lib-path=$ROOTFS/tools/lib --disable-nls \
  --disable-static --enable-64-bit-bfd --disable-multilib
make configure-host
make
make install
cp -v ../binutils-2.23.2/include/libiberty.h $ROOTFS/tools/include

cd $STAGING
cd gcc-4.8.1
patch -Np1 -i ../gcc-branch_update.patch
patch -Np1 -i ../gcc-pure64_specs.patch
echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h
echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h
touch $ROOTFS/tools/include/limits.h
mkdir -v ../gcc-build
cd ../gcc-build
AR=ar LDFLAGS="-Wl,-rpath,$ROOTFS/cross-tools/lib" \
  ../gcc-4.8.1/configure --prefix=$ROOTFS/cross-tools \
  --build=${HOST_VAR} --host=${HOST_VAR} --target=${TARGET_VAR} \
  --with-sysroot=${ROOTFS} --with-local-prefix=$ROOTFS/tools \
  --with-native-system-header-dir=$ROOTFS/tools/include --disable-nls \
  --with-isl=$ROOTFS/cross-tools --with-cloog=$ROOTFS/cross-tools --with-mpc=$ROOTFS/cross-tools \
  --without-headers --with-newlib --disable-decimal-float --disable-libgomp \
  --disable-libmudflap --disable-libssp --disable-threads --disable-multilib \
  --disable-libatomic --disable-libitm --disable-libsanitizer \
  --disable-libquadmath --disable-target-libiberty --disable-target-zlib \
  --with-system-zlib --enable-cloog-backend=isl --disable-isl-version-check \
  --enable-languages=c --enable-checking=release
make all-gcc all-target-libgcc -j$(nproc)
make install-gcc install-target-libgcc -j$(nproc)

cd $STAGING
cd eglibc-2.18
mkdir -v ../eglibc-build
cd ../eglibc-builds
echo "libc_cv_ssp=no" > config.cache
BUILD_CC="gcc" CC="${TARGET_VAR}-gcc -m 64" \
      AR="${TARGET_VAR}-ar" RANLIB="${TARGET_VAR}-ranlib" \
      ../eglibc-2.18/configure --prefix=$ROOTFS/tools \
      --host=${TARGET_VAR} --build=${HOST_VAR} \
      --disable-profile --with-tls --enable-kernel=2.6.32 --with-__thread \
      --with-binutils=$ROOTFS/cross-tools/bin --with-headers=$ROOTFS/tools/include \
      --enable-obsolete-rpc --cache-file=config.cache

make -j$(nproc)
make install -j$(nproc)
mv -v /tools/include/gnu/stubs{-64,}.h

rm -rf $STAGING/gcc-4.8.1
rm -rf $STAGING/gcc-build
tar -xvf gcc.tar.bz2
patch -Np1 -i ../gcc-branch_update.patch
patch -Np1 -i ../gcc-pure64_specs.patch
echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"\n' >> gcc/config/linux.h
echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h
mkdir -v ../gcc-build
cd ../gcc-build
AR=ar LDFLAGS="-Wl,-rpath,$ROOTFS/cross-tools/lib" \
  ../gcc-4.8.1/configure --prefix=$ROOTFS/cross-tools \
  --build=${HOST_VAR} --target=${TARGET_VAR} --host=${HOST_VAR} \
  --with-sysroot=${ROOTFS} --with-local-prefix=$ROOTFS/tools \
  --with-native-system-header-dir=$ROOTFS/tools/include --disable-nls \
  --with-sysroot=$ROOTFS --with-local-prefix=$ROOTFS/tools --disable-nls \
  --enable-shared --disable-static --enable-languages=c,c++ \
  --enable-__cxa_atexit --enable-c99 --enable-long-long --enable-threads=posix \
  --disable-multilib --with-mpc=$ROOTFS/cross-tools --with-mpfr=$ROOTFS/cross-tools \
  --with-gmp=$ROOTFS/cross-tools --with-cloog=$ROOTFS/cross-tools \
  --enable-cloog-backend=isl --with-isl=$ROOTFS/cross-tools \
  --disable-isl-version-check --with-system-zlib --enable-checking=release \
  --enable-libstdcxx-time
make AS_FOR_TARGET="${TARGET_VAR}-as" \
    LD_FOR_TARGET="${TARGET_VAR}-ld"
make install

'

set +ex





cd $STAGING
#wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VERSION}.tar.xz
#wget -nc -O binutils.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
wget -nc -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
wget -nc -O iana-etc.tar.bz2 http://sethwklein.net/iana-etc-${IANA_ETC_VERSION}.tar.bz2
wget -nc -O iana-etc-patch.patch  http://patches.clfs.org/embedded-dev/iana-etc-${IANA_ETC_VERSION}-update-2.patch
git clone https://github.com/memtest86plus/memtest86plus.git memtest86
#wget -nc -O gcc.tar.bz2  http://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
#wget -nc -O musl.tar.gz http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz
#wget -nc -O mpfr.tar.bz2 http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.bz2
#wget -nc -O mpc.tar.gz http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
#wget -nc -O gmp.tar.bz2 http://ftp.gnu.org/gnu/gmp/gmp-6.1.1.tar.bz2




tar -xvf bc.tar.bz2
tar -xvf busybox.tar.bz2
#tar -xvf binutils.tar.bz2
tar -xvf iana-etc.tar.bz2
#tar -xvf gcc.tar.bz2
#tar -xvf musl.tar.gz




set -ex



cd $STAGING
cd memtest86/build64
make -j$(nproc)
cp memtest.bin $ISO_DIR/boot/memtest

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
#grub-mkimage -d iso/boot/grub/i386-pc -o iso/boot/grub/i386-pc/core-img -O i386-pc -p iso/boot/grub biosdisk iso9660
#cat iso/boot/grub/i386-pc/cdboot.img iso/boot/grub/i386-pc/core.img > iso/boot/grub/i386-pc/eltorito.img
#grub-mkimage -O x86_64-efi -p iso/boot/grub -o iso/efi/boot/bootx64.efi iso9660
#grub-mkimage -O i386-efi -p iso/boot/grub -o iso/efi/boot/bootia32.efi iso9660
set +ex