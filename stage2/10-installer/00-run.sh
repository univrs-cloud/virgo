#!/bin/bash -e

install -v -d "${ROOTFS_DIR}/usr/share/virgo/sources.list.d"
install -v -m 0755 files/finish-install.sh "${ROOTFS_DIR}/usr/share/virgo/finish-install.sh"

# Snapshot the sources that built this image; live-build rewrites them after the hooks run.
if [ -f "${ROOTFS_DIR}/etc/apt/sources.list" ]; then
	install -v -m 644 "${ROOTFS_DIR}/etc/apt/sources.list" "${ROOTFS_DIR}/usr/share/virgo/sources.list"
fi
cp -a "${ROOTFS_DIR}/etc/apt/sources.list.d/." "${ROOTFS_DIR}/usr/share/virgo/sources.list.d/"

install -v -m 644 "${ROOTFS_DIR}/etc/hostname" "${ROOTFS_DIR}/etc/hosts" "${ROOTFS_DIR}/usr/share/virgo/"
