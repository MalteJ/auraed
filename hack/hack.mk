build-container:
	cd hack/build-container && ./mk-build-container
	mkdir -p target
	touch hack/build-container

container-release:
	docker run -it --rm -u $${UID} -v "`pwd`:/aurae/auraed" -v "`pwd`/../api:/aurae/api" aurae-builder bash -c "cd /aurae/auraed && make release"

kernel:
	mkdir -p target/rootfs/boot
	docker run -it --rm -u $${UID} -v "`pwd`:/aurae" aurae-builder bash -c "cd hack/kernel && KERNEL_EDITION=aurae . config.sh && ./mk-kernel"

firecracker-kernel:
	mkdir -p target/rootfs/boot
	docker run -it --rm -u $${UID} -v "`pwd`:/aurae" aurae-builder bash -c "cd hack/kernel && KERNEL_EDITION=firecracker . config.sh  && ./mk-kernel"

menuconfig:
	docker run -it --rm -u $${UID} -v "`pwd`:/aurae" -e "KERNEL_EDITION=$${KERNEL_EDITION}" aurae-builder bash -c "cd hack/kernel && . config.sh && ./mk-menuconfig"

initramfs: container-release
	mkdir -p target/rootfs/bin
	cp target/release/auraed target/rootfs/bin/auraed
	cd target/rootfs && rm -f init && ln -s bin/auraed init
	docker run -it --rm -u $${UID} -v "`pwd`:/aurae" aurae-builder bash -c "cd hack/initramfs && ./mk-initramfs"

virsh-init:
	./hack/libvirt/init.sh

virsh-start: virsh-init
	virsh --connect qemu:///system create target/libvirt.xml

virsh-stop:
	virsh --connect qemu:///system destroy aurae

virsh-console:
	virsh --connect qemu:///system console aurae

virsh-shutdown:
	virsh --connect qemu:///system shutdown aurae --mode acpi

firecracker-start:
	sudo ./hack/firecracker/run.sh

firecracker-stop:
	[ -f target/firecracker.pid ] && kill `cat target/firecracker.pid`
	rm -f target/firecracker.pid
	ip link del tap1
	ip link del tap0

network:
	sudo brctl addbr vm-br0
	sudo ip link set up dev vm-br0
	sudo ip addr add fe80::1/64 dev vm-br0
	sudo ip addr add 169.254.42.1/24 dev vm-br0