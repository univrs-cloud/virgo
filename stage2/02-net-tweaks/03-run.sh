#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/etc/iptables"
install -v -m 644 files/rules.v4 "${ROOTFS_DIR}/etc/iptables/rules.v4"
install -v -m 644 files/rules.v6 "${ROOTFS_DIR}/etc/iptables/rules.v6"

on_chroot << EOF
systemctl enable netfilter-persistent
EOF
