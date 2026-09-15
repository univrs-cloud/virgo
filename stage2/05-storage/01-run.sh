#!/bin/bash -e

install -v -d "${ROOTFS_DIR}/usr/share/virgo"

on_chroot << 'EOF'
dpkg-query -W zfs-dkms zfsutils-linux > /usr/share/virgo/zfs-build.txt
found_kernel=0
for image in /boot/vmlinuz-*-amd64; do
	[ -f "$image" ] || continue
	kernel=${image#/boot/vmlinuz-}
	if [ ! -d "/usr/src/linux-headers-$kernel" ]; then
		echo "Missing headers for target kernel $kernel" >&2
		exit 1
	fi
	# uname -r here would return the build host's kernel.
	dkms autoinstall -k "$kernel"
	modinfo -k "$kernel" zfs >> /usr/share/virgo/zfs-build.txt
	found_kernel=1
done
if [ "$found_kernel" != 1 ]; then
	echo "No AMD64 kernel found" >&2
	exit 1
fi
EOF
