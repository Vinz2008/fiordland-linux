KERNEL_VERSION=5.4.3
BUSYBOX_VERSION=1.35.0

mkdir -p rootfs
mkdir -p staging
mkdir -p iso/boot

SOURCE_DIR=$PWD
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
ISO_DIR=$SOURCE_DIR/iso

mkdir -p $ROOTFS/{boot,dev,sys,home,mnt,proc,run,tmp,var} $ROOTFS/usr/{bin,lib} $ROOTFS/var/{empty,log}

cd $STAGING
wget -nc -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz
wget -nc -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2


tar -xvf kernel.tar.xz
tar -xvf busybox.tar.bz2

set -ex
cd busybox-${BUSYBOX_VERSION}
make defconfig
sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
make busybox install -j$(nproc)
cd _install
cp -r ./ $ROOTFS/
cd $ROOTFS
rm -f linuxrc