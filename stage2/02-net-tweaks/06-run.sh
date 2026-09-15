#!/bin/bash -e

install -v -m 755 files/virgo-virtual-ip-guard "${ROOTFS_DIR}/usr/local/bin/virgo-virtual-ip-guard"
install -v -m 644 files/virgo-virtual-ip.service "${ROOTFS_DIR}/lib/systemd/system/virgo-virtual-ip.service"
