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
cd gcc-12.2.0
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
rm -rf gcc-12.2.0

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
cd zlib-1.2.13
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
rm -fv /usr/lib/libz.a
cd ..
rm -rf zlib-1.2.13

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
cd ../..
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

tar -xvf gmp.tar.xz
cd gmp-6.2.1
cp -v configfsf.guess config.guess
cp -v configfsf.sub   config.sub
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.1
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf gmp-6.2.1

tar -xvf mpfr.tar.xz
cd mpfr-4.1.0
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.1.0
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf mpfr-4.1.0

tar -xvf mpc.tar.gz
cd mpc-1.2.1
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.2.1
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf mpc-1.2.1

tar -xvf attr.tar.gz
cd attr-2.5.1
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.1
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf attr-2.5.1

tar -xvf acl.tar.xz
cd acl-2.3.1
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.1
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf acl-2.3.1

tar -xvf libcap.tar.xz
cd libcap-2.63
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib -j$(nproc)
make prefix=/usr lib=lib install -j$(nproc)
cd ..
rm -rf libcap-2.63

tar -xvf shadow.tar.xz
cd shadow-4.11.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
    -i etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc \
            --disable-static  \
            --with-group-name-max-length=32
make -j$(nproc)
make exec_prefix=/usr install -j$(nproc)
pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
echo "\nroot\nroot\n" | passwd root
cd ..
rm -rf shadow-4.11.1

tar -xvf gcc.tar.gz
cd gcc-12.2.0
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib
make -j$(nproc)
make install -j$(nproc)
ln -svr /usr/bin/cpp /usr/lib
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/12.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd ../..
rm -rf gcc-12.2.0

tar -xvf pkg-config.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf pkg-config-0.29.2

tar -xvf ncurses.tar.gz
cd ncurses-6.3
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make -j$(nproc)
make DESTDIR=$PWD/dest install -j$(nproc)
install -vm755 dest/usr/lib/libncursesw.so.6.3 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.3
cp -av dest/* /
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
cd ..
rm -rf ncurses-6.3

tar -xvf sed.tar.xz
cd sed-4.8
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf sed-4.8

tar -xvf psmisc.tar.xz
cd psmisc-23.4
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf psmisc-23.4

tar -xvf gettext.tar.xz
cd gettext-0.21
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.21
make -j$(nproc)
make install -j$(nproc)
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd ..
rm -rf gettext-0.21

tar -xvf bison.tar.xz
cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf bison-3.8.2

tar -xvf grep.tar.xz
cd grep-3.7
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf grep-3.7

tar -xvf bash.tar.gz
cd bash-5.1.16
./configure --prefix=/usr                      \
            --docdir=/usr/share/doc/bash-5.1.16 \
            --without-bash-malloc              \
            --with-installed-readline
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf bash-5.1.16

tar -xvf libtool.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
rm -fv /usr/lib/libltdl.a
cd ..
rm -rf libtool-2.4.6

tar -xvf gdbm.tar.gz
cd gdbm-1.23
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf gdbm-1.23

tar -xvf gperf.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf gperf-3.1

tar -xvf expat.tar.xz
cd expat-2.5.0
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.4.8
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf expat-2.5.0

tar -xvf inetutils.tar.xz
cd inetutils-2.2
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make -j$(nproc)
make install -j$(nproc)
mv -v /usr/{,s}bin/ifconfig
cd ..
rm -rf inetutils-2.2

tar -xvf less.tar.gz
cd less-590
./configure --prefix=/usr --sysconfdir=/etc
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf less-590

tar -xvf perl.tar.xz
cd perl-5.34.0
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.36/core_perl      \
             -Darchlib=/usr/lib/perl5/5.36/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.36/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.36/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.36/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.36/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads
make -j$(nproc)
make install -j$(nproc)
unset BUILD_ZLIB BUILD_BZIP2
cd ..
rm -rf perl-5.34.0

tar -xvf XML-Parser.tar.gz
cd XML-Parser-2.46
perl Makefile.PL
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf XML-Parser-2.46

tar -xvf intltool.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf intltool-0.51.0

tar -xvf autoconf.tar.xz
cd autoconf-2.71
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf autoconf-2.71

tar -xvf automake.tar.xz
cd automake-1.16.5
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf automake-1.16.5

tar -xvf openssl.tar.gz
cd openssl-3.0.1
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make -j$(nproc)
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install -j$(nproc)
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.0.5
cd ..
rm -rf openssl-3.0.1

tar -xvf kmod.tar.xz
cd kmod-29
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib
make -j$(nproc)
make install -j$(nproc)
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod
cd ..
rm -rf kmod-29

tar -xvf elfutils.tar.bz2
cd elfutils-0.186
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
make -j$(nproc)
make -C libelf install -j$(nproc)
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd ..
rm -rf elfutils-0.186

tar -xvf libffi.tar.gz
cd libffi-3.4.2
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=x86-64 \
            --disable-exec-static-tramp
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf libffi-3.4.2

tar -xvf python.tar.xz
cd Python-3.10.2
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --enable-optimizations
make -j$(nproc)
make install -j$(nproc)
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
cd ..
rm -rf Python-3.10.2

tar -xvf wheel.tar.gz
cd wheel-0.37.1
pip3 install --no-index $PWD
cd ..
rm -rf wheel-0.37.1

tar -xvf ninja.tar.gz
cd ninja-1.10.2
export NINJAJOBS=4
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd ..
rm -rf ninja-1.10.2

tar -xvf meson.tar.gz
cd meson-0.61.1
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
cd ..
rm -rf meson-0.61.1

tar -xvf coreutils.tar.xz
cd coreutils-9.0
patch -Np1 -i ../coreutils-9.1-i18n-1.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make -j$(nproc)
make install -j$(nproc)
mv -v /usr/bin/chroot /usr/sbin
cd ..
rm -rf coreutils-9.0

tar -xvf check.tar.gz
cd check-0.15.2
./configure --prefix=/usr --disable-static
make -j$(nproc)
make docdir=/usr/share/doc/check-0.15.2 install -j$(nproc)
cd ..
rm -rf check-0.15.2

tar -xvf diffutils.tar.xz
cd diffutils-3.8
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf diffutils-3.8

tar -xvf gawk.tar.xz
cd gawk-5.1.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf gawk-5.1.1

tar -xvf findutils.tar.xz
cd findutils-4.9.0
case $(uname -m) in
    i?86)   TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
    x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
esac
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf findutils-4.9.0

tar -xvf groff.tar.gz
cd groff-1.22.4
PAGE=A4 ./configure --prefix=/usr
make -j1
make install
cd ..
rm -rf groff-1.22.4

tar -xvf grub.tar.xz
cd grub-2.06
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make -j$(nproc)
make install -j$(nproc)
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
cd ..
rm -rf grub-2.06

tar -xvf gzip.tar.xz
cd gzip-1.11
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf gzip-1.11

tar -xvf iproute2.tar.xz
cd iproute2-5.16.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns -j$(nproc)
make SBINDIR=/usr/sbin install -j$(nproc)
cd ..
rm -rf iproute2-5.16.0

tar -xvf kbd.tar.xz
cd kbd-2.4.0
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf kbd-2.4.0

tar -xvf libpipeline.tar.gz
cd libpipeline-1.5.5
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf libpipeline-1.5.5

tar -xvf make.tar.gz
cd make-4.3
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf make-4.3

tar -xvf patch.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf patch-2.7.6

tar -xvf tar.tar.xz
cd tar-1.34
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf tar-1.34

tar -xvf texinfo.tar.xz
cd texinfo-6.8
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd
cd ..
rm -rf texinfo-6.8

tar -xvf vim.tar.gz
cd vim-8.2.4383
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make -j$(nproc)
make install -j$(nproc)
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.0228
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
cd ..
rm -rf vim-8.2.4383

tar -xvf markupSafe.tar.gz
cd MarkupSafe-2.0.1
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe
cd ..
rm -rf MarkupSafe-2.0.1

tar -xvf jinja2.tar.gz
cd Jinja2-3.0.3
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2
cd ..
rm -rf Jinja2-3.0.3

tar -xvf systemd.tar.gz
cd systemd-250
patch -Np1 -i ../systemd-251-glibc_2.36_fix-1.patch
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
mkdir -p build
cd       build

meson --prefix=/usr                 \
      --buildtype=release           \
      -Ddefault-dnssec=no           \
      -Dfirstboot=false             \
      -Dinstall-tests=false         \
      -Dldconfig=false              \
      -Dsysusers=false              \
      -Drpmmacrosdir=no             \
      -Dhomed=false                 \
      -Duserdb=false                \
      -Dman=false                   \
      -Dmode=release                \
      -Dpamconfdir=no               \
      -Ddocdir=/usr/share/doc/systemd-251 \
      ..
ninja
ninja install
systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-sysupdate
cd ../..
rm -rf systemd-250

tar -xvf dbus.tar.gz
cd dbus-1.12.20
./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --runstatedir=/run                   \
            --disable-static                     \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --docdir=/usr/share/doc/dbus-1.14.0 \
            --with-system-socket=/run/dbus/system_bus_socket
make -j$(nproc)
make install -j$(nproc)
ln -sfv /etc/machine-id /var/lib/dbus
cd ..
rm -rf dbus-1.12.20

tar -xvf man-db.tar.xz
cd man-db-2.10.1
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.10.2 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf man-db-2.10.1

tar -xvf procps-ng.tar.xz
cd procps-3.3.17
./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-4.0.0 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf procps-3.3.17

tar -xvf util-linux.tar.xz
cd util-linux-2.37.4
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --sbindir=/usr/sbin  \
            --docdir=/usr/share/doc/util-linux-2.38.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make -j$(nproc)
make install -j$(nproc)
cd ..
rm -rf util-linux-2.37.4

tar -xvf e2fsprogs.tar.gz
cd e2fsprogs-1.46.5
mkdir -v build
cd       build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make -j$(nproc)
make install -j$(nproc)
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
cd ../..
rm -rf e2fsprogs-1.46.5

tar -xvf linux.tar.xz
cd linux-5.19.2
make mrproper
make defconfig
make -j$(nproc)
make modules_install -j$(nproc)
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.19.2-lfs-11.2-systemd
cp -iv System.map /boot/System.map-5.19.2
cp -iv .config /boot/config-5.19.2
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
cd ..
rm -rf linux-5.19.2

rm -rf /tmp/*
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

set -ex