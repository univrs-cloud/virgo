#!/bin/bash -e
# live-build manages the base Debian sources; add virgoOS and the ZFS pin.
install -m 644 files/virgo.sources /etc/apt/sources.list.d/
install -m 644 files/virgo-packages-keyring.gpg /usr/share/keyrings/
install -d /etc/apt/preferences.d
install -m 644 files/90_zfs /etc/apt/preferences.d/
install -m 644 files/02periodic /etc/apt/apt.conf.d/02periodic
apt-get update
