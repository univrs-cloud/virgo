#!/bin/bash -e
installer=$(mktemp)
curl -fsSL https://get.docker.com -o "$installer"
sh "$installer"
rm -f "$installer"
usermod -aG docker "$FIRST_USER_NAME"
systemctl enable docker
