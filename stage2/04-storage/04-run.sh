#!/bin/bash -e

install -v -d "${ROOTFS_DIR}/etc/multipath/conf.d"
install -v -m 600 files/multipath.conf "${ROOTFS_DIR}/etc/multipath/conf.d/"

install -v -d "${ROOTFS_DIR}/usr/lib/aarch64-linux-gnu/udisks2/modules"
install -v -m 600 files/empty "${ROOTFS_DIR}/usr/lib/aarch64-linux-gnu/udisks2/modules/"

install -v -m 644 files/zfs.conf "${ROOTFS_DIR}/etc/modprobe.d/"

install -v -m 644 files/smb.conf "${ROOTFS_DIR}/etc/samba/"

on_chroot << EOF
if [ -n "${FIRST_USER_PASS}" ]; then
  echo -e "${FIRST_USER_PASS}\n${FIRST_USER_PASS}" | smbpasswd -a -s "${FIRST_USER_NAME}"
fi
EOF
