#!/bin/bash -e
install -d /etc/NetworkManager/conf.d
install -m 644 files/90-virgo.conf /etc/NetworkManager/conf.d/
systemctl mask networking.service ifup@.service ifupdown-pre.service \
    systemd-networkd.service systemd-networkd.socket \
    systemd-networkd-wait-online.service systemd-networkd-wait-online@.service \
    systemd-resolved.service dhcpcd.service dhcpcd@.service
systemctl enable NetworkManager.service NetworkManager-wait-online.service
