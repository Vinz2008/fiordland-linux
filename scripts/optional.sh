## ONLY RUN IN CHROOT

SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging

cd $SOURCE_DIR
mkdir -p $ROOTFS/packages
cd $ROOTFS/packages

wget -nc -O lynx2.tar.bz2 https://invisible-mirror.net/archives/lynx/tarballs/lynx2.8.9rel.1.tar.bz2
wget -nc https://www.linuxfromscratch.org/patches/blfs/11.2/lynx-2.8.9rel.1-security_fix-1.patch
wget -nc -O gpm.tar.bz2 https://anduin.linuxfromscratch.org/BLFS/gpm/gpm-1.20.7.tar.bz2
wget -nc https://www.linuxfromscratch.org/patches/blfs/11.2/gpm-1.20.7-consolidated-1.patch
wget -nc -O openssh.tar.gz https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.0p1.tar.gz

wget -nc -O make-ca.tar.xz https://github.com/lfs-book/make-ca/releases/download/v1.10/make-ca-1.10.tar.xz
wget -nc -O libtasn1.tar.gz https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.18.0.tar.gz
wget -nc -O p11-kit.tar.xz https://github.com/p11-glue/p11-kit/releases/download/0.24.1/p11-kit-0.24.1.tar.xz
wget -nc -O wget.tar.gz https://ftp.gnu.org/gnu/wget/wget-1.21.3.tar.gz

wget -nc -O zsh.tar.xz https://www.zsh.org/pub/zsh-5.9.tar.xz
wget -nc -O nano.tar.xz https://www.nano-editor.org/dist/v6/nano-6.4.tar.xz
wget -nc -O sudo.tar.gz https://www.sudo.ws/dist/sudo-1.9.11p3.tar.gz


sudo mount -v --bind /dev $ROOTFS/dev
sudo mount -v --bind /dev/pts $ROOTFS/dev/pts
sudo mount -vt proc proc $ROOTFS/proc
sudo mount -vt sysfs sysfs $ROOTFS/sys
sudo mount -vt tmpfs tmpfs $ROOTFS/run

cp $SOURCE_DIR/scripts/optional-chroot.sh $ROOTFS/
chmod a+x $ROOTFS/optional-chroot.sh
sudo chroot "$ROOTFS" /usr/bin/env -i HOME=/root TERM=xterm-256color PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /usr/bin/bash /optional-chroot.sh
sudo umount -l $ROOTFS/dev/pts $ROOTFS/dev $ROOTFS/proc $ROOTFS/sys $ROOTFS/run
rm $ROOTFS/optional-chroot.sh