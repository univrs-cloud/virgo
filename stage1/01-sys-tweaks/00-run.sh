#!/bin/bash -e
if ! id -u "$FIRST_USER_NAME" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" "$FIRST_USER_NAME"
fi
if [ -n "$FIRST_USER_PASS" ]; then
    printf '%s:%s\n' "$FIRST_USER_NAME" "$FIRST_USER_PASS" | chpasswd
fi
usermod -s /bin/bash "$FIRST_USER_NAME"
usermod -L root
