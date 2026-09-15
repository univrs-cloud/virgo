# virgo

Tool used to create virgoOS installer images.

Builds a Debian 13 Trixie hybrid ISO using live-build. Write the ISO to a USB
stick, boot the server, and select **Install**. Debian Installer copies the
prepared system to the selected drive and installs GRUB; no packages are
downloaded or installed during the install. Drive selection and erase
confirmation remain interactive.

The ISO supports BIOS and UEFI boot with **Secure Boot disabled**. The bundled
ZFS module is not signed by a key trusted by the server firmware.

## Dependencies

Build on an AMD64 machine or VM running Debian 13 or Ubuntu, with root access,
internet access, and at least 30 GB of free space on a Linux filesystem.

The file `depends` contains a list of tools needed.  The format of this
package is `<tool>[:<debian-package>]`, where an entry starting with `/` is
checked as a file path rather than a command.

To install the required dependencies for `virgo` you should run:

```bash
apt install $(cut -d: -f2 depends | sort -u)
```

`build.sh` checks them before building and prints anything missing.

### Hosts other than Debian 13

Ubuntu packages an older fork of live-build, which rejects options `build.sh`
passes to `lb config` (`--image-name`, `--updates`, `--bootloaders`,
`--uefi-secure-boot`). Install the Debian 13 package over it; it is
`Architecture: all` and depends only on `cpio` and `debootstrap`:

```bash
wget https://deb.debian.org/debian/pool/main/l/live-build/live-build_20250505+deb13u1_all.deb
apt install ./live-build_20250505+deb13u1_all.deb
```

The Debian version carries an epoch, so it sorts above the distribution's own
package and `apt upgrade` will not replace it. Use the `deb13u1` build rather
than a newer one from the same pool directory: the newer files are unstable
uploads, and only this one matches the Trixie the image is built against.

`debian-archive-keyring` will also not carry the Trixie signing keys, and
debootstrap will refuse to bootstrap the chroot without them. Import them:

```bash
wget https://ftp-master.debian.org/keys/archive-key-13.asc
wget https://ftp-master.debian.org/keys/archive-key-13-security.asc
mkdir -p /usr/share/keyrings/
gpg --no-default-keyring --keyring=/usr/share/keyrings/debian-archive-keyring.gpg --import archive-key-13.asc
gpg --no-default-keyring --keyring=/usr/share/keyrings/debian-archive-keyring.gpg --import archive-key-13-security.asc
```

## Getting started with building your images

Getting started is as simple as cloning this repository on your build machine. You
can do so with:

```bash
git clone --branch amd64 https://github.com/univrs-cloud/virgo.git
```

`--depth 1` can be added after `git clone` to create a shallow clone, only containing
the latest revision of the repository. Do not do this on your development machine.

Also, be careful to clone the repository to a base path **NOT** containing spaces.
This configuration is not supported by debootstrap and will lead to `virgo` not
running.

After cloning the repository, you can move to the next step and start configuring
your build.

```bash
sudo ./build.sh
```

Outputs are written to `deploy/`: the `.iso`, its SHA256 checksum, the installed
package manifest, and the ZFS build information. The build log is in
`work/live-build/build.log`.

`./build.sh --prepare` writes the live-build configuration without building, so
you can inspect `work/live-build/config` first. Run `./clean.sh` before
rebuilding; the package cache is retained.

## Config

Upon execution, `build.sh` will source the file `config` in the current
working directory.  This bash shell fragment is intended to set needed
environment variables.

The following environment variables are supported:

 * `IMG_NAME` (Default: `spica-$RELEASE-$ARCH`, for example: `spica-trixie-amd64`)

   The base name of the ISO to build. The release and architecture are fixed at
   `trixie` and `amd64` by this branch.

 * `IMG_DATE` (Default: today, `YYYY-MM-DD`)

   The build date used in the output filename.

 * `IMG_FILENAME` (Default: `$IMG_DATE-$IMG_NAME`)

   The name given to the ISO and to the checksum, package manifest and ZFS
   build information written alongside it.

 * `WORK_DIR`  (Default: `$BASE_DIR/work/live-build`)

   Directory in which `virgo` builds the target system.  This value can be
   changed if you have a suitably large, fast storage location. Must be an
   absolute path.

   **CAUTION**: If your working directory is on an NTFS partition you probably won't be able to build: make sure this is a proper Linux filesystem.

 * `DEPLOY_DIR`  (Default: `$BASE_DIR/deploy`)

   Output directory for the finished ISO and its checksum. Must be an absolute
   path.

 * `LOCALE_DEFAULT` (Default: 'en_US.UTF-8' )

   Default system locale.

 * `TARGET_HOSTNAME` (Default: 'm87' )

   Setting the hostname to the specified value.

 * `KEYBOARD_KEYMAP` (Default: 'us' )

   Default keyboard keymap.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/xkb-keymap` value.

 * `KEYBOARD_LAYOUT` (Default: 'English (US)' )

   Default keyboard layout.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/variant` value.

 * `TIMEZONE_DEFAULT` (Default: 'Etc/UTC' )

   Default time zone.

   To get the current value from a running system, look in
   `/etc/timezone`.

 * `FIRST_USER_NAME` (Default: `voyager`)

   Username for the first user. The account is created during the image build
   and ships on the installed system.

 * `FIRST_USER_PASS` (Default: `intergalactic`)

   Password for the first user. If unset, the account is locked. The `root`
   account is locked in all cases.

 * `PASSWORDLESS_SUDO` (Default: `0`)

   Setting to `1` will enable passwordless sudo for the first user. This allows
   the user to run commands with sudo without entering a password. Note that
   this is a security risk and should only be enabled if you understand the
   implications. The user will still be able to use sudo with a password even
   when this is set to `0`.

 * `ENABLE_SSH` (Default: `1`)

   Setting to `1` will enable ssh server for remote log in. Note that if you are using a common password such as the defaults there is a high risk of attackers taking over.

  * `PUBKEY_SSH_FIRST_USER` (Default: unset)

   Setting this to a value will make that value the contents of the FIRST_USER_NAME's ~/.ssh/authorized_keys.  Obviously the value should
   therefore be a valid authorized_keys file.  Note that this does not
   automatically enable SSH.

  * `PUBKEY_ONLY_SSH` (Default: `0`)

   * Setting to `1` will disable password authentication for SSH and enable
   public key authentication.  Note that if SSH is not enabled this will take
   effect when SSH becomes enabled.

A simple example for building virgoOS:

```bash
IMG_NAME='Spica'
```

The config file can also be specified on the command line as an argument the `build.sh` script.

```
./build.sh -c myconfig
```

This is parsed after `config` so can be used to override values set there.

## How the build process works

`build.sh` generates a live-build configuration, then runs `lb bootstrap`,
`lb chroot`, `lb installer` and `lb binary`. The stage directories are copied
into that configuration and run inside the chroot by a live-build hook, so
everything below happens in one chroot rather than one per stage.

The following process is followed by that hook:

 * Iterate through the stage directories `stage0`, `stage1` and `stage2` in order

 * In each stage directory iterate through each subdirectory and then run each of the
   install scripts it contains, again in alphanumeric order. **These need to be named
   with a two digit padded number at the beginning.**
   There are a number of different files and directories which can be used to
   control different parts of the build process:

     - **00-run.sh** - A unix shell script.

     - **00-run-chroot.sh** - A unix shell script. Retained for compatibility
       with the `arm64` branch; the build already runs inside the chroot, so it
       behaves the same as `00-run.sh`.

     - **00-debconf** - Contents of this file are passed to debconf-set-selections
       to configure things like locale, etc. `${LOCALE_DEFAULT}`,
       `${KEYBOARD_KEYMAP}` and `${KEYBOARD_LAYOUT}` are substituted.

     - **00-packages** - A list of packages to install. Can have more than one, space
       separated, per line.

     - **00-packages-nr** - As 00-packages, except these will be installed using
       the `--no-install-recommends -y` parameters to apt-get.

     - **00-patches** - A directory containing patch files to be applied, listed
       in a `series` file and applied with `patch -p2` against `/`.

 * Snapshot the apt sources and install `finish-install.sh`, which Debian
   Installer runs on the target through the preseed's `late_command`

 * Strip the machine identity and logs so every installed node generates its own

It is recommended to examine build.sh for finer details.

## Stage Anatomy

### Stage Overview

The build is divided up into several stages for logical clarity
and modularity.  This causes some initial complexity, but it simplifies
maintenance and allows for more easy customization.

 - **Stage 0** - apt configuration.  Adds the univrs package repository and the
   ZFS pin on top of the base system live-build has already bootstrapped, and
   installs the kernel headers, firmware and microcode.

 - **Stage 1** - truly minimal system.  This stage configures GRUB defaults,
   creates the first user, locks `root`, and tunes the journal.  Debian
   Installer writes `/etc/fstab` and installs the bootloader, so neither is
   built here.

 - **Stage 2** - the full system.  Stage 2 sets timezone and charmap
   defaults, configures NetworkManager, the firewall and mDNS, installs ZFS,
   Samba, Docker, Node.js and the Virgo packages, and creates necessary groups
   and gives the user access to sudo and the standard console hardware
   permission groups.

   Note: the image contains a number of tools for development,
   including `Python`, `Lua` and the `build-essential` package. If you are
   creating an image to deploy in products, be sure to remove extraneous development
   tools before deployment.

   The last two substages are ordering-sensitive: `10-installer` snapshots the
   apt sources before live-build rewrites them, and `99-cleanup` must run after
   every other substage.

# Troubleshooting

## `Existing build found`

`build.sh` refuses to build over a previous run. Run `./clean.sh` first. The
downloaded package cache survives, so a rebuild is not a full re-download.

## `Secure Boot`

The ZFS module is built by DKMS during the image build and is not signed by a
key the firmware trusts. Disable Secure Boot in the server firmware before
installing.

## `ARM64 systems`

An ARM64 image for Raspberry Pi hardware is generated from the `arm64` branch in
this repository, which uses a different build system:

```bash
git clone --branch arm64 https://github.com/univrs-cloud/virgo.git
```
