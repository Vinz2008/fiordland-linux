.PHONY: build

build:
	./scripts/build.sh

clean:
	sudo umount -R rootfs/dev rootfs/proc rootfs/sys rootfs/run || /bin/true
	sudo chown -R vincent:vincent rootfs/{usr,lib,var,etc,bin,sbin,cross-tools,lib64} || /bin/true
	rm -rf iso rootfs staging fiordland.iso

qemu:
	./scripts/qemu.sh