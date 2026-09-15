#!/usr/bin/env python3
import sys
from pathlib import Path


def installation_manifest(manifest):
    live_packages = {
        "live-boot", "live-boot-initramfs-tools", "live-boot-doc",
        "live-config", "live-config-systemd", "live-config-doc", "live-tools",
        "debian-installer-launcher",
    }
    for name in sorted(live_packages):
        print(f"removed from the installed system: {name}")
    return "".join(
        line for line in manifest.splitlines(keepends=True)
        if line.split() and line.split()[0].split(":")[0] not in live_packages
    )


if __name__ == "__main__":
    source, destination = map(Path, sys.argv[1:])
    destination.write_text(installation_manifest(source.read_text()))
