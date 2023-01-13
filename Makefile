.PHONY: build

all:
	./scripts/all.sh


setup:
	./scripts/setup.sh

cross-compiler:
	./scripts/cross-compiler.sh

temporary-tools:
	./scripts/temporary-tools.sh

build:
	./scripts/build.sh

clean:
	sudo umount -R rootfs/dev rootfs/proc rootfs/sys rootfs/run || /bin/true
	sudo chown -R vincent:vincent rootfs/{usr,lib,var,etc,bin,sbin,cross-tools,lib64} || /bin/true
	rm -rf iso rootfs staging fiordland.iso

clean_cross-compiler:
	rm -rf rootfs/cross-tools

qemu:
	./scripts/qemu.sh