#!/bin/bash
set -e

KERNEL_EDITION=firecracker . hack/kernel/config.sh

socket="/tmp/firecracker.socket"
kernel_path="`pwd`/target/kernel/firecracker-vmlinux-$KERNEL_VERSION"
initrd_path="`pwd`/target/initramfs.zst"

ip tuntap add tap0 mode tap
ip tuntap add tap1 mode tap
ip addr add 172.16.0.1/24 dev tap0
ip link set tap0 up



rm -f $socket
nohup firecracker --api-sock $socket > target/firecracker.out 2>&1 & echo $! > target/firecracker.pid

set -x

curl --unix-socket /tmp/firecracker.socket -i  \
  -X PUT 'http://localhost/machine-config' \
  -H 'Accept: application/json'            \
  -H 'Content-Type: application/json'      \
  -d '{
      "vcpu_count": 2,
      "mem_size_mib": 1024
  }'

curl --unix-socket /tmp/firecracker.socket -i \
  -X PUT 'http://localhost/network-interfaces/eth0' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "iface_id": "eth0",
      "guest_mac": "de:ad:be:ef:00:00",
      "host_dev_name": "tap0"
    }'

curl --unix-socket /tmp/firecracker.socket -i \
  -X PUT 'http://localhost/network-interfaces/eth1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "iface_id": "eth1",
      "guest_mac": "de:ad:be:ef:00:01",
      "host_dev_name": "tap1"
    }'

curl --unix-socket /tmp/firecracker.socket -i \
  -X PUT 'http://localhost/vsock' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "guest_cid": 3,
      "uds_path": "./v.sock"
  }'

curl --unix-socket /tmp/firecracker.socket -i \
    -X PUT 'http://localhost/boot-source'   \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d "{
        \"kernel_image_path\": \"${kernel_path}\",
        \"initrd_path\": \"${initrd_path}\",
        \"boot_args\": \"rdinit=/bin/auraed console=ttyS0 reboot=k panic=1 pci=off\"
    }"

curl --unix-socket ${socket} -i \
     -X PUT "http://localhost/actions" \
     -d '{ "action_type": "InstanceStart" }'