#!/bin/bash
load_build_config() {
    PREPARE_ONLY=0
    local extra_config=""
    while (($#)); do
        case "$1" in
            -c) [[ $# -ge 2 ]] || return 1; extra_config="$2"; shift 2 ;;
            --prepare) PREPARE_ONLY=1; shift ;;
            *) echo "Usage: $0 [-c config-file] [--prepare]" >&2; return 1 ;;
        esac
    done
    source "$BASE_DIR/config"
    [[ -z "$extra_config" ]] || source "$extra_config"
    RELEASE=trixie
    ARCH=amd64
    IMG_NAME=${IMG_NAME:-virgo-trixie}
    WORK_DIR=${WORK_DIR:-"$BASE_DIR/work/live-build"}
    DEPLOY_DIR=${DEPLOY_DIR:-"$BASE_DIR/deploy"}
    PUBKEY_SSH_FIRST_USER=${PUBKEY_SSH_FIRST_USER:-}
    PUBKEY_ONLY_SSH=${PUBKEY_ONLY_SSH:-0}
    [[ "$IMG_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { echo "Invalid IMG_NAME" >&2; return 1; }
    [[ "$FIRST_USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Invalid FIRST_USER_NAME" >&2; return 1; }
    [[ "$TARGET_HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || { echo "Invalid TARGET_HOSTNAME" >&2; return 1; }
    [[ "$WORK_DIR" == /* && "$DEPLOY_DIR" == /* && "$WORK_DIR" != / ]] || {
        echo "WORK_DIR and DEPLOY_DIR must be absolute paths; WORK_DIR cannot be /." >&2; return 1;
    }
}
write_build_environment() {
    local variable
    for variable in RELEASE ARCH IMG_NAME ENABLE_SSH LOCALE_DEFAULT \
        KEYBOARD_KEYMAP KEYBOARD_LAYOUT TARGET_HOSTNAME TIMEZONE_DEFAULT FIRST_USER_NAME \
        FIRST_USER_PASS PASSWORDLESS_SUDO PUBKEY_SSH_FIRST_USER PUBKEY_ONLY_SSH; do
        printf 'export %s=%q\n' "$variable" "${!variable}"
    done
}
