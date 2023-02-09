.PHONY: system

all: setup cross-compiler temporary-tools system iso
	./scripts/all.sh


setup:
	./scripts/setup.sh

cross-compiler:
	./scripts/cross-compiler.sh

temporary-tools:
	./scripts/temporary-tools.sh

system:
	./scripts/system.sh

optional:
	./scripts/optional.sh

iso:
	./scripts/iso.sh

clean:
	sudo umount -R rootfs/dev rootfs/proc rootfs/sys rootfs/run || /bin/true
	sudo chown -R vincent:vincent rootfs/ || /bin/true
	rm -rf iso rootfs staging/ fiordland.iso

clean_cross-compiler:
	rm -rf rootfs/cross-tools

clean_staging:
	rm -rf staging

qemu:
	./scripts/qemu.sh