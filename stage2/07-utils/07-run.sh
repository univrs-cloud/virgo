#!/bin/bash -e

install -v -m 644 files/virgo-stats_1.0.0_all.deb "${ROOTFS_DIR}/tmp/virgo-stats_1.0.0_all.deb"

on_chroot << EOF
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source /root/.bashrc
nvm install --lts

sudo ln -s /root/.nvm/versions/node/v20.11.0/bin/node /usr/bin/node
sudo ln -s /root/.nvm/versions/node/v20.11.0/bin/npm /usr/bin/npm

dpkg -i /tmp/virgo-stats_1.0.0_all.deb
EOF
