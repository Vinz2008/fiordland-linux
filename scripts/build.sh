KERNEL_VERSION=5.18.1
BUSYBOX_VERSION=1.34.1

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
make distclean
make defconfig
sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
make busybox install -j$(nproc)
cd _install
cp -r ./ $ROOTFS/
cd $ROOTFS
rm -f linuxrc

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