#!/bin/bash -e

# Install detection script
install -m 755 files/configure-zram-size "${ROOTFS_DIR}/usr/local/bin/configure-zram-size"

# Install systemd service for zram configuration
install -m 644 files/configure-zram.service "${ROOTFS_DIR}/etc/systemd/system/configure-zram.service"

# Enable services
on_chroot << EOF
systemctl enable zramswap.service
systemctl enable configure-zram.service
EOF
