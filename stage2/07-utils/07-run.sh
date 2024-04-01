#!/bin/bash -e

on_chroot << EOF
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s lts
npm install -g n
EOF
