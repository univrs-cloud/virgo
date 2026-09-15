#!/bin/bash -e

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-login --gecos "" ${FIRST_USER_NAME}
fi

if [ -n "${FIRST_USER_PASS}" ]; then
	echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
	usermod -s /bin/bash "${FIRST_USER_NAME}"
fi
echo "root:root" | chpasswd
EOF
