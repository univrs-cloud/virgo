#!/bin/bash -e
# Debian Installer writes the target fstab and installs GRUB after copying the OS.
install -d /etc/default/grub.d
cat > /etc/default/grub.d/virgo.cfg <<'EOF'
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX_DEFAULT=""
EOF
