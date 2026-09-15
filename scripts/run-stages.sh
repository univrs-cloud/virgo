#!/bin/bash
set -euo pipefail
# Never run these stages against the build host's root filesystem.
BASE_DIR=/live-build/config/virgo
[[ -f "$BASE_DIR/build.env" && -f /etc/debian_version ]] || {
    echo "This runner must be invoked by live-build inside its chroot." >&2; exit 1;
}
source "$BASE_DIR/build.env"
source "$BASE_DIR/scripts/common"
export ROOTFS_DIR="" DEBIAN_FRONTEND=noninteractive
export LC_ALL=C LANG=C
dpkg-query -W > /var/lib/virgo-build-packages
shopt -s nullglob
for stage in stage0 stage1 stage2; do
    for substage in "$BASE_DIR/$stage"/*/; do
        log "$stage/$(basename "$substage")"
        cd "$substage"
        for number in {00..99}; do
            if [[ -f "$number-debconf" ]]; then
                envsubst '${LOCALE_DEFAULT} ${KEYBOARD_KEYMAP} ${KEYBOARD_LAYOUT}' \
                    < "$number-debconf" | debconf-set-selections
            fi
            for kind in packages-nr packages; do
                if [[ -f "$number-$kind" ]]; then
                    packages=()
                    while IFS= read -r line || [[ -n "$line" ]]; do
                        read -r -a words <<< "${line%%#*}"
                        packages+=("${words[@]}")
                    done < "$number-$kind"
                    options=()
                    [[ "$kind" == packages-nr ]] && options+=(--no-install-recommends)
                    if ((${#packages[@]})); then
                        apt-get -o Acquire::Retries=3 install -y "${options[@]}" "${packages[@]}"
                    fi
                fi
            done
            if [[ -f "$number-patches/series" ]]; then
                while read -r patch_name rest; do
                    [[ -z "$patch_name" || "$patch_name" == \#* ]] && continue
                    patch --batch --forward -d / -p2 < "$number-patches/$patch_name"
                done < "$number-patches/series"
            fi
            for suffix in run.sh run-chroot.sh; do
                [[ ! -f "$number-$suffix" ]] || bash -e "$number-$suffix"
            done
        done
    done
done
