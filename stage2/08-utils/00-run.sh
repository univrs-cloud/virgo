#!/bin/bash -e

on_chroot << 'EOF'
systemctl enable redis-server
EOF
