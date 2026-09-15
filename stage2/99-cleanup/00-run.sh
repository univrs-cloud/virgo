#!/bin/bash -e

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*
rm -f "${ROOTFS_DIR}/var/lib/dbus/machine-id"
: > "${ROOTFS_DIR}/etc/machine-id"
ln -sfn /etc/machine-id "${ROOTFS_DIR}/var/lib/dbus/machine-id"

rm -f "${ROOTFS_DIR}/var/lib/systemd/random-seed"
rm -f "${ROOTFS_DIR}/root/.bash_history"

find "${ROOTFS_DIR}/var/log" -type f -exec truncate -s 0 {} +
