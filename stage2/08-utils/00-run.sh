#!/bin/bash -e

install -v -d -m 775 -o pcp -g pcp "${ROOTFS_DIR}/var/log/pcp/pmlogger"

on_chroot << EOF
curl -fsSL -o /usr/local/bin/n https://raw.githubusercontent.com/tj/n/master/bin/n 
chmod 0755 /usr/local/bin/n
n 22

systemctl enable redis-server
systemctl disable pmcd pmlogger pmlogger_farm pmproxy
systemctl disable pmlogger_check.timer pmlogger_daily.timer pmlogger_farm_check.timer
EOF
