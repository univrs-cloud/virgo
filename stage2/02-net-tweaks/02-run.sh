#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/etc/NetworkManager/dispatcher.d/pre-up.d"
install -v -m 755 files/wait-for-gateway "${ROOTFS_DIR}/etc/NetworkManager/dispatcher.d/pre-up.d/10-wait-for-gateway"
install -v -m 755 files/reannounce-mdns "${ROOTFS_DIR}/etc/NetworkManager/dispatcher.d/50-reannounce-mdns"
