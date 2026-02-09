#!/bin/bash -e

install -v -m 644 files/fail2ban.local "${ROOTFS_DIR}/etc/fail2ban/"
install -v -m 644 files/jail.local "${ROOTFS_DIR}/etc/fail2ban/"

on_chroot << EOF
systemctl enable fail2ban
EOF
