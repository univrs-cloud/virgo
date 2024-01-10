#!/bin/bash -e

if ! grep -q "^i2c[-_]dev" "${ROOTFS_DIR}/etc/modules"; then
    printf "i2c-dev\n" >> "${ROOTFS_DIR}/etc/modules"
fi

install -v -m 755 files/ups.shutdown "${ROOTFS_DIR}/lib/systemd/system-shutdown/"
install -v -m 755 files/ups.service "${ROOTFS_DIR}/lib/systemd/system/"
install -v -m 755 files/ups.sh "${ROOTFS_DIR}/usr/sbin/"
install -v -d "${ROOTFS_DIR}/usr/share/virgo/ups"
install -v -m 644 files/__init__.py "${ROOTFS_DIR}/usr/share/virgo/ups/"
install -v -m 644 files/settings.py "${ROOTFS_DIR}/usr/share/virgo/ups/"
install -v -m 644 files/service.py "${ROOTFS_DIR}/usr/share/virgo/ups/"
install -v -m 644 files/input_button.py "${ROOTFS_DIR}/usr/share/virgo/ups/"
install -v -m 644 files/power_monitor.py "${ROOTFS_DIR}/usr/share/virgo/ups/"

on_chroot << EOF
#systemctl enable ups.service
EOF
