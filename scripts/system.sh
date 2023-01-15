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


SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging

export PATH=$PATH:$ROOTFS/cross-tools/bin

set -ex

set +ex

cd $SOURCE_DIR

# PREPARE CHROOT

mkdir $ROOTFS/packages
cd $ROOTFS/packages

wget -nc -O gcc.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz
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
wget -nc -O zlib.tar.xz https://zlib.net/zlib-1.2.13.tar.gz
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
wget -nc -O expat.tar.xz https://downloads.sourceforge.net/expat/expat-2.5.0.tar.bz2
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
wget -nc -O wheel.tar.gz https://anduin.linuxfromscratch.org/LFS/wheel-0.37.1.tar.gz
wget -nc -O ninja.tar.gz https://github.com/ninja-build/ninja/archive/v1.10.2/ninja-1.10.2.tar.gz
wget -nc -O meson.tar.gz https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz
wget -nc -O coreutils.tar.xz https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.2/coreutils-9.1-i18n-1.patch
wget -nc -O check.tar.gz https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz
wget -nc -O diffutils.tar.xz https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz
wget -nc -O gawk.tar.xz https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz
wget -nc -O findutils.tar.xz https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
wget -nc -O groff.tar.gz https://ftp.gnu.org/gnu/groff/groff-1.22.4.tar.gz
wget -nc -O grub.tar.xz https://ftp.gnu.org/gnu/grub/grub-2.06.tar.xz
wget -nc -O gzip.tar.xz https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz
wget -nc -O iproute2.tar.xz https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-5.16.0.tar.xz
wget -nc -O kbd.tar.xz https://www.kernel.org/pub/linux/utils/kbd/kbd-2.4.0.tar.xz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.2/kbd-2.5.1-backspace-1.patch
wget -nc -O libpipeline.tar.gz https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.5.tar.gz
wget -nc -O make.tar.gz https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
wget -nc -O patch.tar.xz https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
wget -nc -O tar.tar.xz https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz
wget -nc -O vim.tar.gz https://anduin.linuxfromscratch.org/LFS/vim-8.2.4383.tar.gz
wget -nc -O markupSafe.tar.gz https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-2.0.1.tar.gz
wget -nc -O jinja2.tar.gz https://files.pythonhosted.org/packages/source/J/Jinja2/Jinja2-3.0.3.tar.gz
wget -nc -O systemd.tar.gz https://github.com/systemd/systemd/archive/v250/systemd-250.tar.gz
wget -nc https://www.linuxfromscratch.org/patches/lfs/11.2/systemd-251-glibc_2.36_fix-1.patch
wget -nc -O dbus.tar.gz https://dbus.freedesktop.org/releases/dbus/dbus-1.12.20.tar.gz
wget -nc -O man-db.tar.xz https://download.savannah.gnu.org/releases/man-db/man-db-2.10.1.tar.xz
wget -nc -O procps-ng.tar.xz https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.17.tar.xz
wget -nc -O e2fsprogs.tar.gz https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.46.5/e2fsprogs-1.46.5.tar.gz
wget -nc -O linux.tar.xz https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.19.2.tar.xz

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
sudo chroot "$ROOTFS" /usr/bin/env -i HOME=/root TERM=xterm-256color PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /usr/bin/bash /chroot.sh


sudo umount -l $ROOTFS/dev/pts $ROOTFS/dev $ROOTFS/proc $ROOTFS/sys $ROOTFS/run
rm $ROOTFS/chroot.sh


# BUILD PACKAGES

set +ex


cd $STAGING
#wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
#wget -nc -O binutils.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
#wget -nc -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
#wget -nc -O gcc.tar.bz2  http://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
#wget -nc -O musl.tar.gz http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz
#wget -nc -O mpfr.tar.bz2 http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.bz2
#wget -nc -O mpc.tar.gz http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
#wget -nc -O gmp.tar.bz2 http://ftp.gnu.org/gnu/gmp/gmp-6.1.1.tar.bz2




#tar -xvf bc.tar.bz2
#tar -xvf busybox.tar.bz2
#tar -xvf binutils.tar.bz2
#tar -xvf gcc.tar.bz2
#tar -xvf musl.tar.gz
#tar -xvf kernel.tar.xz



set -ex






#cd $SOURCE_DIR/iso/boot



#grub-mkimage -d iso/boot/grub/i386-pc -o iso/boot/grub/i386-pc/core-img -O i386-pc -p iso/boot/grub biosdisk iso9660
#cat iso/boot/grub/i386-pc/cdboot.img iso/boot/grub/i386-pc/core.img > iso/boot/grub/i386-pc/eltorito.img
#grub-mkimage -O x86_64-efi -p iso/boot/grub -o iso/efi/boot/bootx64.efi iso9660
#grub-mkimage -O i386-efi -p iso/boot/grub -o iso/efi/boot/bootia32.efi iso9660
set +ex