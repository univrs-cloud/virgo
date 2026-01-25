#!/bin/bash -e

sed -i 's/^#\?Compress=.*/Compress=yes/' /etc/systemd/journald.conf
sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=50M/' /etc/systemd/journald.conf
sed -i 's/^#\?SyncIntervalSec=.*/SyncIntervalSec=5m/' /etc/systemd/journald.conf
