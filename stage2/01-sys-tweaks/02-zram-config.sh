#!/bin/bash -e

# Install detection script
install -m 755 files/configure-zram-size "${ROOTFS_DIR}/usr/local/bin/configure-zram-size"

# Install systemd service for zram configuration
install -m 644 files/configure-zram.service "${ROOTFS_DIR}/etc/systemd/system/configure-zram.service"

# Ensure zramswap waits for configure-zram to finish
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/zramswap.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/zramswap.service.d/wait-for-config.conf" << 'EOF'
[Unit]
Wants=configure-zram.service
After=configure-zram.service
EOF

# Enable services
on_chroot << EOF
systemctl enable zramswap.service
systemctl enable configure-zram.service
EOF
