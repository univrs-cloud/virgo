#!/usr/bin/env python3
import sys
from pathlib import Path


def package_names(manifest):
    return {line.split()[0].split(":")[0] for line in manifest.splitlines() if line.split()}


def installation_manifest(installed, before_hooks, live):
    live_only = package_names(before_hooks) - package_names(installed)
    for name in sorted(live_only):
        print(f"removed from the installed system: {name}")
    return "".join(
        line for line in live.splitlines(keepends=True)
        if line.split() and line.split()[0].split(":")[0] not in live_only
    )


if __name__ == "__main__":
    installed, before_hooks, live, destination = map(Path, sys.argv[1:])
    manifest = installation_manifest(
        installed.read_text(), before_hooks.read_text(), live.read_text()
    )
    destination.write_text(manifest)
