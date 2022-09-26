#!/bin/sh


set +ex

export HOME=/root 
export TERM=xterm-256color 
export PS1='(lfs chroot) \u:\w\$ ' 
export PATH=/usr/bin:/usr/sbin

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

cd /packages

tar -xvf gcc.tar.gz
cd gcc-11.2.0
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -v build
cd build
../libstdc++-v3/configure            \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
    --prefix=/usr                    \
    --disable-multilib               \
    --disable-nls                    \
    --host=$(uname -m)-lfs-linux-gnu \
    --disable-libstdcxx-pch
make -j$(nproc)
make -j$(nproc) install
cd ../..
rm -rf gcc-11.2.0

tar -xvf gettext.tar.xz
cd gettext-0.21
./configure --disable-shared
make -j$(nproc)
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd ..
rm -rf gettext-0.21

tar -xvf bison.tar.xz
cd bison-3.8.2
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make -j$(nproc)
make -j$(nproc) install
cd ..
rm -rf bison-3.8.2

tar -xvf perl.tar.xz
cd perl-5.34.0
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
             -Darchlib=/usr/lib/perl5/5.34/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl
make -j$(nproc)
make -j$(nproc) install
rm -rf perl-5.34.0
cd ..

tar -xvf python.tar.xz
cd Python-3.10.2
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make -j$(nproc)
make -j$(nproc) install
cd ..
rm -rf Python-3.10.2

tar -xvf texinfo.tar.xz
cd texinfo-6.8
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/usr
make -j$(nproc)
make -j$(nproc) install
cd ..
rm -rf texinfo-6.8

tar -xvf util-linux.tar.xz
cd util-linux-2.37.4
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --docdir=/usr/share/doc/util-linux-2.37.4 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            runstatedir=/run
make -j$(nproc)
make -j$(nproc) install
cd ..
rm -rf util-linux-2.37.4

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /cross-tools

tar -xvf man-pages.tar.xz
cd man-pages-5.13
make prefix=/usr install
cd ..
rm -rf man-pages-5.13

tar -xvf iana-etc.tar.gz
cd iana-etc-20220207
cp services protocols /etc
cd ..
rm -rf iana-etc-20220207

tar -xvf glibc.tar.xz
cd glibc-2.35
patch -Np1 -i ../glibc-2.35-fhs-1.patch
mkdir -v build
cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=3.2                      \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             libc_cv_slibdir=/usr/lib
make -j$(nproc)
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install -j$(nproc)
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
cat > /etc/ld.so.conf << "END"
# Start of /etc/ld.so.conf
/usr/local/lib
/opt/lib
END
cd ../..
rm -rf glibc-2.35

tar -xvf zlib.tar.xz
cd zlib-1.2.12
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
rm -fv /usr/lib/libz.a
cd ..
rm -rf zlib-1.2.12

tar -xvf bzip2.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make -j$(nproc)
make PREFIX=/usr install -j$(nproc)
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
cd ..
rm -rf bzip2-1.0.8

tar -xvf xz.tar.xz
cd xz-5.2.5
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.5
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf xz-5.2.5


tar -xvf zstd.tar.gz
cd zstd-1.5.2
make -j$(nproc)
make prefix=/usr install -j$(nproc)
rm -v /usr/lib/libzstd.a
cd ..
rm -rf zstd-1.5.2

tar -xvf file.tar.gz
cd file-5.41
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf file-5.41

tar -xvf readline.tar.gz
cd readline-8.1.2
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.1.2
make SHLIB_LIBS="-lncursesw" -j$(nproc)
make SHLIB_LIBS="-lncursesw" install -j$(nproc)
cd ..
rm -rf readline-8.1.2

tar -xvf m4.tar.xz
cd m4-1.4.19
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf m4-1.4.19

tar -xvf bc.tar.xz
cd bc-5.2.2
CC=gcc ./configure --prefix=/usr -G -O3
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf bc-5.2.2

tar -xvf flex.tar.gz
cd flex-2.6.4
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make -j$(nproc)
make install -j$(nproc)
ln -s flex /usr/bin/lex
cd ..
rm -rf flex-2.6.4

tar -xvf tcl.tar.gz
cd tcl8.6.12
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            $([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
make -j$(nproc)
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.3|/usr/lib/tdbc1.1.3|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.3|/usr/include|"            \
    -i pkgs/tdbc1.1.3/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.2|/usr/lib/itcl4.2.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.2|/usr/include|"            \
    -i pkgs/itcl4.2.2/itclConfig.sh

unset SRCDIR
make install -j$(nproc)
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers -j$(nproc)
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
rm -rf tcl8.6.12-src

tar -xvf expect.tar.gz
cd expect5.45.4
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make -j$(nproc)
make install -j$(nproc)
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
cd ..
rm -rf expect5.45.4

tar -xvf dejagnu.tar.gz
cd dejagnu-1.6.3
mkdir -v build
cd build
../configure --prefix=/usr
make install -j$(nproc)
cd ..
rm -rf dejagnu-1.6.3

tar -xvf binutils.tar.xz
cd binutils-2.38
patch -Np1 -i ../binutils-2.38-lto_fix-1.patch
sed -e "/R_386_TLS_LE /i \   || (TYPE) == R_386_TLS_IE \\" \
    -i ./bfd/elfxx-x86.h
mkdir -v build
cd build
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
make tooldir=/usr -j$(nproc)
make tooldir=/usr install -j$(nproc)
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a
cd ..
rm -rf binutils-2.38

set -ex