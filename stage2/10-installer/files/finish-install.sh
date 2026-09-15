#!/bin/bash
set -euo pipefail
if [[ -f /usr/share/virgo/sources.list ]]; then
    install -m 644 /usr/share/virgo/sources.list /etc/apt/sources.list
fi
rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources
cp -a /usr/share/virgo/sources.list.d/. /etc/apt/sources.list.d/
install -m 644 /usr/share/virgo/hostname /usr/share/virgo/hosts /etc/
ln -sfn /run/NetworkManager/resolv.conf /etc/resolv.conf
rm -f /etc/network/interfaces
for image in /boot/vmlinuz-*-amd64; do
    kernel=${image#/boot/vmlinuz-}
    [[ "$(modinfo -k "$kernel" -F vermagic zfs)" == "$kernel "* ]] || {
        echo "Prebuilt ZFS module missing or incompatible with $kernel" >&2; exit 1;
    }
done
