#!/bin/bash -e

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

install -v -d "${ROOTFS_DIR}/etc/ssh/sshd_config.d"
printf 'PermitRootLogin no\n' > "${ROOTFS_DIR}/etc/ssh/sshd_config.d/10-virgo.conf"

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	printf 'PubkeyAuthentication yes\nPasswordAuthentication no\nKbdInteractiveAuthentication no\n' \
		>> "${ROOTFS_DIR}/etc/ssh/sshd_config.d/10-virgo.conf"
fi

install -v -m 644 -D files/ssh-regenerate-host-keys.conf "${ROOTFS_DIR}/etc/systemd/system/ssh.service.d/10-host-keys.conf"

on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
EOF

on_chroot <<- EOF

	for GRP in input spi i2c gpio; do
		groupadd -f -r "\$GRP"
	done
	for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev render; do
		adduser $FIRST_USER_NAME \$GRP
	done
EOF

if [ "${PASSWORDLESS_SUDO}" = "1" ]; then
    printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$FIRST_USER_NAME" > /etc/sudoers.d/010-virgo
    chmod 0440 /etc/sudoers.d/010-virgo
    visudo -cf /etc/sudoers.d/010-virgo
fi

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

sed -i 's/^FONTFACE=.*/FONTFACE=""/;s/^FONTSIZE=.*/FONTSIZE=""/' "${ROOTFS_DIR}/etc/default/console-setup"
sed -i "s/PLACEHOLDER//" "${ROOTFS_DIR}/etc/default/keyboard"
on_chroot << EOF
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration console-setup
EOF

if [ -e "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" ]; then
  # sed -i 's/^#\?domain-name=.*/domain-name=local/' "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf"
  sed -i 's/^#\?use-ipv6=.*/use-ipv6=no/' "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf"
  sed -i 's/^#\?publish-workstation=.*/publish-workstation=yes/' "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf"
fi

install -v -m 755 -D files/avahi-allow-interfaces "${ROOTFS_DIR}/usr/local/sbin/avahi-allow-interfaces"
install -v -m 644 -D files/avahi-allow-interfaces.service "${ROOTFS_DIR}/lib/systemd/system/avahi-allow-interfaces.service"

on_chroot <<- EOF
	systemctl enable avahi-allow-interfaces
EOF
