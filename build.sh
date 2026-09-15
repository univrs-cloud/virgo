#!/bin/bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/scripts/build-config.sh"
load_build_config "$@"
if [[ "$PREPARE_ONLY" != 1 ]]; then
    [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 && "$EUID" == 0 ]] || {
        echo "Build on AMD64 Linux as root." >&2
        exit 1
    }
    source "$BASE_DIR/scripts/dependencies_check"
    dependencies_check "$BASE_DIR/depends"
else
    command -v lb >/dev/null || { echo "Install live-build (see README.md)." >&2; exit 1; }
fi
mkdir -p "$WORK_DIR" "$DEPLOY_DIR"
cd "$WORK_DIR"
if [[ -f .build/bootstrap || -d chroot ]]; then
    echo "Existing build found. Run ./clean.sh before rebuilding changed stages." >&2
    exit 1
fi
if [[ -e config && ! -f .virgo-live-build ]]; then
    echo "Refusing to replace an unmanaged config in $WORK_DIR" >&2; exit 1
fi
touch .virgo-live-build
rm -rf config
rm -f .build/config
lb config --ignore-system-defaults \
    --mode debian --distribution trixie --architecture amd64 \
    --binary-image iso-hybrid --image-name "$IMG_FILENAME" \
    --archive-areas "main contrib non-free non-free-firmware" \
    --backports true --security true --updates true \
    --debian-installer live --debian-installer-distribution trixie \
    --debian-installer-gui false \
    --bootloaders "syslinux grub-efi" --uefi-secure-boot disable \
    --linux-flavours amd64 --linux-packages linux-image \
    --firmware-chroot false --firmware-binary true \
    --apt-recommends true --apt-source-archives false \
    --cache true --cache-packages true --cache-stages bootstrap \
    --chroot-filesystem squashfs --checksums sha256 --source false \
    --iso-volume VIRGO_TRIXIE_AMD64 --iso-publisher "univrs.cloud" \
    --bootappend-live "boot=live components hostname=$TARGET_HOSTNAME locales=$LOCALE_DEFAULT keyboard-layouts=$KEYBOARD_KEYMAP live-config.nocomponents=user-setup,sudo,ssh,ifupdown" \
    --bootappend-install "priority=high"
mkdir -p config/virgo/scripts config/hooks/live config/package-lists \
    config/includes.installer config/includes.chroot/etc
cp -R "$BASE_DIR/stage0" "$BASE_DIR/stage1" "$BASE_DIR/stage2" config/virgo/
cp "$BASE_DIR/scripts/"{common,run-stages.sh} config/virgo/scripts/
write_build_environment > config/virgo/build.env
chmod 600 config/virgo/build.env
cp "$BASE_DIR/live-build/installer.preseed" config/includes.installer/preseed.cfg
printf 'd-i time/zone string %s\n' "$TIMEZONE_DEFAULT" >> config/includes.installer/preseed.cfg
printf '%s\n' "$TARGET_HOSTNAME" > config/includes.chroot/etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 %s\n::1 localhost ip6-localhost ip6-loopback\n' \
    "$TARGET_HOSTNAME" > config/includes.chroot/etc/hosts
cp "$BASE_DIR/live-build/00-virgo.hook.chroot" config/hooks/live/
printf '%s\n' ca-certificates curl gnupg gettext-base patch > config/package-lists/build.list.chroot
if [[ "$PREPARE_ONLY" == 1 ]]; then
    echo "Prepared live-build configuration in $WORK_DIR/config"
    exit 0
fi
exec > >(tee "$WORK_DIR/build.log") 2>&1
lb bootstrap
lb chroot
# Hook-installed packages must be retained in the installer manifest.
python3 "$BASE_DIR/scripts/install-manifest.py" \
    chroot.packages.install chroot/var/lib/virgo-build-packages chroot.packages.live \
    chroot.packages.install
rm -f chroot/var/lib/virgo-build-packages
lb installer
# Left until after lb installer, which still needs working DNS inside the chroot.
ln -sfn /run/NetworkManager/resolv.conf chroot/etc/resolv.conf
lb binary
shopt -s nullglob
images=("$IMG_FILENAME"*.iso)
[[ ${#images[@]} -eq 1 ]] || { echo "Expected exactly one ISO." >&2; exit 1; }
install -m 644 "${images[0]}" "$DEPLOY_DIR/"
install -m 644 chroot.packages.install "$DEPLOY_DIR/$IMG_FILENAME.packages"
install -m 644 chroot/usr/share/virgo/zfs-build.txt "$DEPLOY_DIR/$IMG_FILENAME.zfs-build.txt"
cd "$DEPLOY_DIR"
sha256sum "$(basename "${images[0]}")" > "$(basename "${images[0]}").sha256"
echo "Installer ISO: $DEPLOY_DIR/$(basename "${images[0]}")"
