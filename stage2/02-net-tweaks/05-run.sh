#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/etc/sysctl.d"
install -v -m 644 files/90-nonlocal-bind.conf "${ROOTFS_DIR}/etc/sysctl.d/90-nonlocal-bind.conf"
