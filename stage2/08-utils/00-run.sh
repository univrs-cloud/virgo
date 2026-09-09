#!/bin/bash -e

on_chroot << 'EOF'
set -e

tmp=$(mktemp)
curl -fsSL -o "$tmp" https://raw.githubusercontent.com/tj/n/master/bin/n
chmod 0755 "$tmp"
mv "$tmp" /usr/local/bin/n
n 24

systemctl enable redis-server
EOF
