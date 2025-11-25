#!/bin/bash -e

install -v -m 755 files/01-custom "${ROOTFS_DIR}/etc/update-motd.d/"

on_chroot << EOF
> /etc/motd
rm -f /etc/update-motd.d/10-uname
EOF
