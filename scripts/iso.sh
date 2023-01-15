SOURCE_DIR=$PWD
AIROOTFS=$SOURCE_DIR/airootfs
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging

cd $ROOTFS/boot/
mkdir -p grub
cd grub
cat > grub.cfg << EOF
set default=0
set timeout=30
# Menu Colours
set menu_color_normal=white/black
set menu_color_highlight=white/green
root (hd0,0)
#search --file --no-floppy --set root /

if loadfont unifont; then
  insmod efi_uga
  insmod efi_gop
  set gfxmode=auto
  set gfxpayload=keep
  terminal_output gfxterm
fi
menuentry "fiordland" {      
  linux   /boot/vmlinuz-5.19.2-lfs-11.2-systemd console=ttyS0,38400 console=tty0 ro
  initrd /boot/initramfs
}

menuentry "UEFI Shell" {
  chainloader /boot/shell.efi
}

menuentry "Reboot" {
  reboot
}

menuentry "Halt" {
  halt
}

EOF
cd $SOURCE_DIR
sudo grub-mkrescue --compress=xz -o fiordland.iso rootfs