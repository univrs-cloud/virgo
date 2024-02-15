#!/bin/bash -e

install -v -m 644 files/virgo-api_1.0.0_all.deb "${ROOTFS_DIR}/tmp/virgo-api_1.0.0_all.deb"
install -v -m 644 files/virgo-ui_1.0.0_all.deb "${ROOTFS_DIR}/tmp/virgo-ui_1.0.0_all.deb"

on_chroot << EOF
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s lts
npm install -g n

dpkg -i /tmp/virgo-api_1.0.0_all.deb
dpkg -i /tmp/virgo-ui_1.0.0_all.deb
EOF
