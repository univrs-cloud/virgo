#!/bin/bash -e

install -v -d "${ROOTFS_DIR}/var/log/pcp/pmlogger"

on_chroot << EOF
curl -fsSL -o /usr/local/bin/n https://raw.githubusercontent.com/tj/n/master/bin/n 
chmod 0755 /usr/local/bin/n
n 24

systemctl enable redis-server
systemctl disable pmlogger_check.timer pmlogger_daily.timer pmlogger_farm_check.timer
systemctl disable pmcd pmlogger.service pmlogger_farm.service pmproxy.service
EOF
