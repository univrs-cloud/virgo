#!/bin/bash -e

# Configure traditional swap to 512MB
# raspberrypi-sys-mods uses /etc/dphys-swapfile for swap configuration

if [ -f "${ROOTFS_DIR}/etc/dphys-swapfile" ]; then
    # Modify existing config
    sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' "${ROOTFS_DIR}/etc/dphys-swapfile"
    # Ensure it's not using auto-sizing
    sed -i 's/^#CONF_SWAPSIZE=/CONF_SWAPSIZE=/' "${ROOTFS_DIR}/etc/dphys-swapfile"
    # Uncomment if commented
    sed -i '/^#.*CONF_SWAPSIZE=/ s/^#//' "${ROOTFS_DIR}/etc/dphys-swapfile"
fi
