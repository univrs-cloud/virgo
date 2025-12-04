#!/bin/bash -e

on_chroot << EOF
curl -fsSL -o /usr/local/bin/n https://raw.githubusercontent.com/tj/n/master/bin/n 
chmod 0755 /usr/local/bin/n
n 22

systemctl enable redis-server
EOF
