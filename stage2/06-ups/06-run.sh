#!/bin/bash -e

if ! grep -q "^i2c[-_]dev" "${ROOTFS_DIR}/etc/modules"; then
    printf "i2c-dev\n" >> "${ROOTFS_DIR}/etc/modules"
fi

install -v -m 755 files/ups.shutdown "${ROOTFS_DIR}/lib/systemd/system-shutdown/"
install -v -m 755 files/ups.service "${ROOTFS_DIR}/lib/systemd/system/"
install -v -m 755 files/ups.sh "${ROOTFS_DIR}/usr/sbin/"

on_chroot << EOF
systemctl enable ups.service
EOF
