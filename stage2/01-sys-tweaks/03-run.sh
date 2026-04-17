#!/bin/bash -e

# Install rpi-swap drop-in to configure zram-only swap (no backing file)
install -d "${ROOTFS_DIR}/etc/rpi/swap.conf.d"
install -m 644 files/90-zram-only.conf "${ROOTFS_DIR}/etc/rpi/swap.conf.d/90-zram-only.conf"
