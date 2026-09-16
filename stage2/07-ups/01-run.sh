#!/bin/bash -e

install -v -m 640 -o root -g nut files/nut.conf files/ups.conf files/upsd.conf files/upsd.users files/upsmon.conf "${ROOTFS_DIR}/etc/nut/"

install -v -d "${ROOTFS_DIR}/etc/systemd/system/nut-driver@.service.d"
install -v -m 644 files/retry.conf "${ROOTFS_DIR}/etc/systemd/system/nut-driver@.service.d/"

install -v -m 644 files/63-univrs-nut-hotplug.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
