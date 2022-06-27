.PHONY: build

build:
	./scripts/build.sh

clean:
	rm -rf iso rootfs staging fiordland.iso

qemu:
	./scripts/qemu.sh