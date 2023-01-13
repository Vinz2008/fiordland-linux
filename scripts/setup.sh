set +h

mkdir -p rootfs
mkdir -p staging
mkdir -p rootfs/boot
mkdir -p rootfs/efi/boot
mkdir -p rootfs/boot/grub/i386-pc

SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging

set -ex

mkdir -p $ROOTFS/{boot,dev,sys,home,mnt,proc,run,tmp,etc,opt,srv}
mkdir -p $ROOTFS/usr/{,local/}{bin,include,lib,sbin,share/{color,dict,doc,info,locale,man,misc,terminfo,zoneinfo}} $ROOTFS/var/{cache,lib,local,lock,opt,run,spool,empty,log}


case $(uname -m) in
  x86_64) mkdir -pv $ROOTFS/lib64/{firmware,modules} ;;
esac



cd $ROOTFS
for i in bin lib sbin; do
  ln -svf usr/$i $ROOTFS/$i
done

cd $SOURCE_DIR

touch $ROOTFS/var/log/{btmp,lastlog,faillog,wtmp}
#chgrp -v utmp $ROOTFS/var/log/lastlog
chmod -v 664  $ROOTFS/var/log/lastlog
chmod -v 600  $ROOTFS/var/log/btmp
mkdir -p $ROOTFS/media/{floppy,cdrom}
ln -sfvf $ROOTFS/run $ROOTFS/var/run
ln -sfvf $ROOTFS/run/lock $ROOTFS/var/lock
install -dv -m 0750 $ROOTFS/root
install -dv -m 1777 $ROOTFS/{var/,}tmp
touch $ROOTFS/var/log/lastlog
chmod -v 664 $ROOTFS/var/log/lastlog
mkdir -pv $ROOTFS/etc/network/if-{post-{up,down},pre-{up,down},up,down}.d
mkdir -pv $ROOTFS/usr/share/udhcpc
ln -svf $ROOTFS/proc/self/mounts $ROOTFS/etc/mtab
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