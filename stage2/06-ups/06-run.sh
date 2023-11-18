#!/bin/bash -e

if ! grep -q "^i2c[-_]dev" "${ROOTFS_DIR}/etc/modules"; then
    printf "i2c-dev\n" >> "${ROOTFS_DIR}/etc/modules"
fi

install -v -m 755 files/ups.shutdown "${ROOTFS_DIR}/lib/systemd/system-shutdown/"
