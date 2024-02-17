#!/bin/bash -e

if ! grep -q "^i2c[-_]dev" "${ROOTFS_DIR}/etc/modules"; then
    printf "i2c-dev\n" >> "${ROOTFS_DIR}/etc/modules"
fi

install -v -m 644 files/virgo-ups_1.0.0_all.deb "${ROOTFS_DIR}/tmp/virgo-ups_1.0.0_all.deb"

on_chroot << EOF
dpkg -i /tmp/virgo-ups_1.0.0_all.deb
EOF
