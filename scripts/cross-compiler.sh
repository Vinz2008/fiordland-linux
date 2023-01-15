SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging

if [[ -d "$ROOTFS/cross-tools" ]]
then
echo "cross compiler already build run"
echo "run 'rm -rf rootfs/cross-tools or make clean_cross-compiler' to remove it"
exit 0
fi

TARGET_VAR=$(uname -m)-lfs-linux-gnu
export PATH=$PATH:$ROOTFS/cross-tools/bin

mkdir -p $ROOTFS/cross-tools

# CROSS COMPILATION TOOLS
cd $STAGING

wget -nc -O binutils.tar.xz https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz
wget -nc -O gcc.tar.xz https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
wget -nc -O mpfr.tar.xz https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz
wget -nc -O gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget -nc -O mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
wget -nc -O linux.tar.xz https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.19.2.tar.xz
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
cd linux-5.19.2
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $ROOTFS/usr

cd $STAGING
rm -rf linux-5.19.2
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