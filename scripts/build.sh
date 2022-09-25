KERNEL_VERSION=5.19.4
#KERNEL_VERSION=4.9.22
BUSYBOX_VERSION=1.34.1
BINUTILS_VERSION=2.27
GCC_VERSION=6.2.0
MUSL_VERSION=1.1.16

TARGET_VAR=$(uname -m)-lfs-linux-gnu
HOST_VAR=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')
set +h


CC=gcc

mkdir -p rootfs
mkdir -p staging
mkdir -p iso/boot
mkdir -p iso/efi/boot
mkdir -p iso/boot/grub/i386-pc
mkdir -p rootfs/cross-tools



SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
ISO_DIR=$SOURCE_DIR/iso

export PATH=$PATH:$ROOTFS/cross-tools/bin

set -ex



mkdir -p $ROOTFS/{boot,dev,sys,home,mnt,proc,run,tmp,etc,opt,srv}
mkdir -p $ROOTFS/usr/{,local/}{bin,include,lib,sbin,share/{color,dict,doc,info,locale,man,misc,terminfo,zoneinfo}} $ROOTFS/var/{cache,lib,local,lock,opt,run,spool,empty,log}


case $(uname -m) in
  x86_64) mkdir -pv $ROOTFS/lib64/{firmware,modules} ;;
esac



cd $ROOTFS
for i in bin lib sbin; do
  ln -sv usr/$i $ROOTFS/$i
done

cd $SOURCE_DIR

touch $ROOTFS/var/log/{btmp,lastlog,faillog,wtmp}
#chgrp -v utmp $ROOTFS/var/log/lastlog
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
ln -sv $ROOTFS/proc/self/mounts $ROOTFS/etc/mtab
sudo mknod -m 600 $ROOTFS/dev/console c 5 1
#ln -s $ROOTFS/dev/ttyS0 $ROOTFS/dev/console
sudo mknod -m 666 $ROOTFS/dev/tty c 5 0
sudo mknod -m 666 $ROOTFS/dev/null c 1 3
sudo mknod -m 666 $ROOTFS/dev/ttyS0 c 4 64
sudo mknod -m 666 $ROOTFS/dev/zero c 1 5
sudo chown root:tty $ROOTFS/dev/{console,tty}
set +ex

cp -v -r $AIROOTFS/* $ROOTFS 

chmod +x $ROOTFS/usr/share/udhcpc/default.script


# CROSS COMPILATION TOOLS
cd $STAGING

wget -nc -O binutils.tar.xz https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz
wget -nc -O gcc.tar.xz https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
wget -nc -O mpfr.tar.xz https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
wget -nc -O gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget -nc -O mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
wget -nc -O linux.tar.xz https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.16.9.tar.xz
wget -nc -O glibc.tar.xz https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.xz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.1/glibc-2.35-fhs-1.patch


set -ex

cd $STAGING
tar -xvf binutils.tar.xz
cd binutils-2.38
mkdir -v build
cd build
../configure --prefix=$ROOTFS/cross-tools \
             --with-sysroot=$ROOTFS \
             --target=$TARGET_VAR   \
             --disable-nls       \
             --disable-werror

make -j$(nproc)
make install -j$(nproc)

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
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
rm -rf build
mkdir -v build
cd build
../configure                  \
    --target=$TARGET_VAR         \
    --prefix=$ROOTFS/cross-tools       \
    --with-glibc-version=2.35 \
    --with-sysroot=$ROOTFS       \
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
    --disable-bootstrap \
    --enable-languages=c,c++
make -j$(nproc)
make install -j$(nproc)
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($TARGET_VAR-gcc -print-libgcc-file-name)`/install-tools/include/limits.h


cd $STAGING
rm -rf gcc-11.2.0
tar -xvf linux.tar.xz
cd linux-5.16.9
make mrproper
make headers
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $ROOTFS/usr

cd $STAGING
rm -rf linux-5.16.9
tar -xvf glibc.tar.xz
cd glibc-2.35
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $ROOTFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $ROOTFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $ROOTFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
patch -Np1 -i ../glibc-2.35-fhs-1.patch
mkdir -v build
cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure                             \
      --prefix=/usr                      \
      --host=$TARGET_VAR                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$ROOTFS/usr/include    \
      libc_cv_slibdir=/usr/lib
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)
sed '/RTLDLIST=/s@/usr@@g' -i $ROOTFS/usr/bin/ldd
$ROOTFS/cross-tools/libexec/gcc/$TARGET_VAR/11.2.0/install-tools/mkheaders

cd $STAGING
rm -rf glibc-2.35
tar -xvf gcc.tar.xz
cd gcc-11.2.0
mkdir -v build
cd build
../libstdc++-v3/configure           \
    --host=$TARGET_VAR                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/cross-tools/$TARGET_VAR/include/c++/11.2.0
make -j$(nproc)
make DESTDIR=$ROOTFS install -j$(nproc)
echo "int main(){}" > dummy.c
$TARGET_VAR-gcc dummy.c
readelf -l a.out | grep "/ld-linux"

cd $STAGING
rm -rf gcc-11.2.0

set +ex


# TEMPORARY TOOLS

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
ln -sv bash $ROOTFS/bin/sh

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

cd $SOURCE_DIR

# PREPARE CHROOT

mkdir $ROOTFS/packages
cd $ROOTFS/packages

wget -nc -O gcc.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
wget -nc -O gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz
wget -nc -O bison.tar.xz https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
wget -nc -O perl.tar.xz https://www.cpan.org/src/5.0/perl-5.34.0.tar.xz
wget -nc -O python.tar.xz https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tar.xz
wget -nc -O texinfo.tar.xz https://ftp.gnu.org/gnu/texinfo/texinfo-6.8.tar.xz
wget -nc -O util-linux.tar.xz https://www.kernel.org/pub/linux/utils/util-linux/v2.37/util-linux-2.37.4.tar.xz

wget -nc -O man-pages.tar.xz https://www.kernel.org/pub/linux/docs/man-pages/man-pages-5.13.tar.xz
wget -nc -O iana-etc.tar.gz https://github.com/Mic92/iana-etc/releases/download/20220207/iana-etc-20220207.tar.gz
wget -nc -O glibc.tar.xz https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.xz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.1/glibc-2.35-fhs-1.patch
wget -nc -O zlib.tar.xz https://zlib.net/zlib-1.2.12.tar.gz
wget -nc -O bzip2.tar.gz https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.1/bzip2-1.0.8-install_docs-1.patch
wget -nc -O xz.tar.xz https://tukaani.org/xz/xz-5.2.5.tar.xz
wget -nc -O zstd.tar.gz https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz
wget -nc -O file.tar.gz https://astron.com/pub/file/file-5.41.tar.gz
wget -nc -O readline.tar.gz https://ftp.gnu.org/gnu/readline/readline-8.1.2.tar.gz
wget -nc -O m4.tar.xz https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
wget -nc -O bc.tar.xz https://github.com/gavinhoward/bc/releases/download/5.2.2/bc-5.2.2.tar.xz
wget -nc -O flex.tar.gz https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
wget -nc -O tcl.tar.gz https://downloads.sourceforge.net/tcl/tcl8.6.12-src.tar.gz
wget -nc -O expect.tar.gz https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz
wget -nc -O dejagnu.tar.gz https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz
wget -nc -O binutils.tar.xz https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.1/binutils-2.38-lto_fix-1.patch
wget -nc -O gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget -nc -O mpfr.tar.xz https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
wget -nc -O mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
wget -nc -O attr.tar.gz https://download.savannah.gnu.org/releases/attr/attr-2.5.1.tar.gz
wget -nc -O acl.tar.xz https://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
wget -nc -O libcap.tar.xz https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.63.tar.xz
wget -nc -O shadow.tar.xz https://github.com/shadow-maint/shadow/releases/download/v4.11.1/shadow-4.11.1.tar.xz
wget -nc -O pkg-config.tar.gz https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
wget -nc -O ncurses.tar.gz https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz
wget -nc -O sed.tar.xz https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz
wget -nc -O psmisc.tar.xz https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.4.tar.xz
wget -nc -O grep.tar.xz https://ftp.gnu.org/gnu/grep/grep-3.7.tar.xz
wget -nc -O bash.tar.gz https://ftp.gnu.org/gnu/bash/bash-5.1.16.tar.gz
wget -nc -O libtool.tar.xz https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.xz
wget -nc -O gdbm.tar.gz https://ftp.gnu.org/gnu/gdbm/gdbm-1.23.tar.gz
wget -nc -O gperf.tar.gz https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
wget -nc -O expat.tar.xz https://downloads.sourceforge.net/expat/expat-2.4.6.tar.bz2
wget -nc -O inetutils.tar.xz https://ftp.gnu.org/gnu/inetutils/inetutils-2.2.tar.xz
wget -nc -O less.tar.gz https://www.greenwoodsoftware.com/less/less-590.tar.gz
wget -nc -O XML-Parser.tar.gz https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz
wget -nc -O intltool.tar.gz https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz
wget -nc -O autoconf.tar.xz https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.xz
wget -nc -O automake.tar.xz https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz
wget -nc -O openssl.tar.gz https://www.openssl.org/source/openssl-3.0.1.tar.gz
wget -nc -O kmod.tar.xz https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-29.tar.xz
wget -nc -O elfutils.tar.bz2 https://sourceware.org/ftp/elfutils/0.186/elfutils-0.186.tar.bz2
wget -nc -O libffi.tar.gz https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz
wget -nc -O ninja.tar.gz https://github.com/ninja-build/ninja/archive/v1.10.2/ninja-1.10.2.tar.gz
wget -nc -O meson.tar.gz https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz
wget -nc -O coreutils.tar.xz https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz
wget -nc -O check.tar.gz https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz
wget -nc -O diffutils.tar.xz https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz
wget -nc -O gawk.tar.xz https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz
wget -nc -O findutils.tar.xz https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
wget -nc -O groff.tar.gz https://ftp.gnu.org/gnu/groff/groff-1.22.4.tar.gz
wget -nc -O grub.tar.xz https://ftp.gnu.org/gnu/grub/grub-2.06.tar.xz
wget -nc -O gzip.tar.xz https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz
wget -nc -O iproute2.tar.xz https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-5.16.0.tar.xz
wget -nc -O kbd.tar.xz https://www.kernel.org/pub/linux/utils/kbd/kbd-2.4.0.tar.xz
wget -nc -O libpipeline.tar.gz https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.5.tar.gz
wget -nc -O make.tar.gz https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
wget -nc -O patch.tar.xz https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
wget -nc -O tar.tar.xz https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz
wget -nc -O vim.tar.gz https://anduin.linuxfromscratch.org/LFS/vim-8.2.4383.tar.gz
wget -nc -O markupSafe.tar.gz https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-2.0.1.tar.gz
wget -nc -O jinja2.tar.gz https://files.pythonhosted.org/packages/source/J/Jinja2/Jinja2-3.0.3.tar.gz
wget -nc -O systemd.tar.gz https://github.com/systemd/systemd/archive/v250/systemd-250.tar.gz
wget -nc -O dbus.tar.gz https://dbus.freedesktop.org/releases/dbus/dbus-1.12.20.tar.gz
wget -nc -O man-db.tar.xz https://download.savannah.gnu.org/releases/man-db/man-db-2.10.1.tar.xz
wget -nc -O procps-ng.tar.xz https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.17.tar.xz
wget -nc -O e2fsprogs.tar.gz https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.46.5/e2fsprogs-1.46.5.tar.gz




sudo chown -R root:root $ROOTFS/{usr,lib,var,etc,bin,sbin,cross-tools}
case $(uname -m) in
  x86_64) sudo chown -R root:root $ROOTFS/lib64 ;;
esac
sudo mount -v --bind /dev $ROOTFS/dev
sudo mount -v --bind /dev/pts $ROOTFS/dev/pts
sudo mount -vt proc proc $ROOTFS/proc
sudo mount -vt sysfs sysfs $ROOTFS/sys
sudo mount -vt tmpfs tmpfs $ROOTFS/run




# CHROOT

cp $SOURCE_DIR/scripts/chroot.sh $ROOTFS/
chmod a+x $ROOTFS/chroot.sh
chroot "$ROOTFS" /usr/bin/env -i HOME=/root TERM=xterm-256color PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /usr/bin/bash /chroot.sh


sudo umount $ROOTFS/dev $ROOTFS/dev/pts $ROOTFS/proc $ROOTFS/sys $ROOTFS/run
rm $ROOTFS/chroot.sh


# BUILD PACKAGES

set +ex


cd $STAGING
#wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
#wget -nc -O binutils.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
wget -nc -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
git clone https://github.com/memtest86plus/memtest86plus.git memtest86
#wget -nc -O gcc.tar.bz2  http://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
#wget -nc -O musl.tar.gz http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz
#wget -nc -O mpfr.tar.bz2 http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.bz2
#wget -nc -O mpc.tar.gz http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
#wget -nc -O gmp.tar.bz2 http://ftp.gnu.org/gnu/gmp/gmp-6.1.1.tar.bz2




#tar -xvf bc.tar.bz2
tar -xvf busybox.tar.bz2
#tar -xvf binutils.tar.bz2
#tar -xvf gcc.tar.bz2
#tar -xvf musl.tar.gz
tar -xvf kernel.tar.xz



set -ex


cd $STAGING
cd memtest86/build64
make -j$(nproc)
cp memtest.bin $ISO_DIR/boot/memtest

cd $STAGING
cd busybox-${BUSYBOX_VERSION}
make distclean
make defconfig
#sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
echo "CONFIG_STATIC_LIBGCC=y" >> .config
make  -j$(nproc)
make CONFIG_PREFIX="${ROOTFS}" install -j$(nproc)



#make busybox install -j$(nproc)
#cd _install
#cp -r ./ $ROOTFS/
cd $ROOTFS
rm -f linuxrc


cd $ROOTFS
mkdir -p dev mnt proc sys tmp

#cp $SOURCE_DIR/misc-files/init $ROOTFS/boot/initrd
#chmod +x $ROOTFS/boot/initrd



#mkdir $SOURCE_DIR/INITRAMFS_BUILD
#cd $SOURCE_DIR/INITRAMFS_BUILD
cp $SOURCE_DIR/misc-files/init .
chmod u+x init
#cp -f $STAGING/busybox-${BUSYBOX_VERSION}/busybox bin/busybox
ln -sf busybox bin/sh 2> /dev/null
echo "Creating initramfs cpio archive"
find . -print0 | cpio --null -ov --format=newc | gzip --best > $SOURCE_DIR/iso/boot/rootfs.gz
#cd $ROOTFS
#find . | cpio --null -ov --format=newc | gzip --best > $SOURCE_DIR/iso/boot/rootfs.gz

cd $STAGING
cd linux-${KERNEL_VERSION}
make mrproper
make x86_64_defconfig
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

menuentry "memtest" {
  linux16 /boot/memtest
}
EOF

cd $SOURCE_DIR
grub-mkrescue --compress=xz -o fiordland.iso iso 
#grub-mkimage -d iso/boot/grub/i386-pc -o iso/boot/grub/i386-pc/core-img -O i386-pc -p iso/boot/grub biosdisk iso9660
#cat iso/boot/grub/i386-pc/cdboot.img iso/boot/grub/i386-pc/core.img > iso/boot/grub/i386-pc/eltorito.img
#grub-mkimage -O x86_64-efi -p iso/boot/grub -o iso/efi/boot/bootx64.efi iso9660
#grub-mkimage -O i386-efi -p iso/boot/grub -o iso/efi/boot/bootia32.efi iso9660
set +ex