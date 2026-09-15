#!/bin/bash -e
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
swap-priority = 100
EOF
