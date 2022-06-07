KERNEL_VERSION=5.16.4
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

cd $ROOTFS
mkdir -p bin dev mnt proc sys tmp

cp $SOURCE_DIR/misc-files/init $ROOTFS
chmod +x init

cd $ROOTFS
find . | cpio -R root:root -H newc -o | gzip > $SOURCE_DIR/iso/boot/rootfs.gz

cd $STAGING
cd linux-${KERNEL_VERSION}
make mrproper
cp $SOURCE_DIR/misc-files/linux.config .config
make olddefconfig
#make -j$(nproc) defconfig
grep -q '^CONFIG_MODULES=y$' .config && make INSTALL_MOD_PATH=$ROOTFS/usr INSTALL_MOD_STRIP=1 modules_install || true

make INSTALL_HDR_PATH=$ROOTFS/usr INSTALL_MOD_STRIP=1 headers_install


make bzImage -j$(nproc)
cp arch/x86/boot/bzImage $SOURCE_DIR/iso/boot/bzImage
cp System.map $SOURCE_DIR/iso/boot/System.map

make INSTALL_HDR_PATH=$ROOTFS headers_install -j$(nproc)

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
    linux  /boot/bzImage
    initrd /boot/rootfs.gz
}
EOF

cd $SOURCE_DIR
grub-mkrescue --compress=xz -o fiordland.iso iso 
set +ex