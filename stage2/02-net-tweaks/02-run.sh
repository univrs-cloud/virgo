#!/bin/bash -e

install -v -m 644 files/fail2ban.local "${ROOTFS_DIR}/etc/fail2ban/fail2ban.local"
install -v -m 644 files/jail.local "${ROOTFS_DIR}/etc/fail2ban/jail.local"

on_chroot << EOF
systemctl enable fail2ban
EOF
