# SolarNode OS (Debian)

This directory contains scripts and support for Debian-based SolarNodeOS images for various 
hardware devices, like the Raspberry Pi.

# Customize script

The [bin/customize.sh](bin/customize.sh) script is the main tool for taking an "upstream" Debian
based operating system image and turning it into SolarNodeOS. It relies on `systemd-nspawn` to
configure the operating system. Its job is just to create a temporary container out of the 
upstream image and then run some other "setup" script within the container to do the actual
work of customizing the OS. When the setup script is complete, it will stop the container and
create a new image file out of it. The [setup-sn.sh](#setup-script) script is the one used to turn
upstream OS images into SolarNodeOS images.

The `customize.sh` script can also resize the output image and even change the filesystem type, for
example change the upstream `ext4` filesystem into `btrfs`.

For example use, see the README files in the various device-specific directories under this one,
such as the [Raspberry Pi](pi/#setup-script).

## Customizing SolarNodeOS images

The [bin/customize.sh](bin/customize.sh) script is also a handy way to customize SolarNodeOS images
into vendor-specific SolarNodeOS variants. Instead of running the [setup-sn.sh](#setup-script) "setup"
script, you provide your own.

## Requirements

A Linux host system is required. This can be a virtual machine, as long as nested virtual machine
support is enabled. A Debian-based system is recommended, which must be version 10 (Buster) or
later.

The following assumes you are using a Debian host. You need some packages installed to run the
setup scripts:

```sh
sudo apt-get install git systemd-container qemu binfmt-support qemu-user-static
```

# Setup script

The [bin/setup-sn.sh](bin/setup-sn.sh) script is the main tool for performing the steps of 
converting a "vanilla" upstream OS into SolarNodeOS. What it does is remove all but the software
necessary for SolarNode to run and  install the base SolarNode platform and core SolarNode system
packages. The script is flexible enough so it can be used in different build settings, such as:

 * transforming a Raspbian OS into SolarNodeOS
 * integrating into the Armbian build process to build SolarNodeOS directly

Although the script has been primarily designed for Raspberry Pi and similar devices, it does also
work for devices like the eBox 330MX. YMMV on other devices!

## Setup package selection

The `setup-sn.sh` script looks for 4 configuration files that define what packages are desired in
the final SolarNodeOS image. Each file contains a list of package names, one per line. By default
the script looks for these in a relative `conf` directory.

| File                            | Description |
|:--------------------------------|:------------|
| `setup-packages-add-early.txt`  | Packages to add early in the setup process, before doing much else. |
| `setup-packages-keep.txt`       | Packages that should remain in the output image (i.e. do not remove). |
| `setup-packages-add.txt`        | Packages that should be added (installed) in the output image. |
| `setup-packages-del-late.txt`   | Packages to delete near the end, even if they were included in the `setup-packages-keey.txt` file. |

To summarise how packages are installed/removed, the script performs the following steps:

 1. Install packages listed in `setup-packages-add-early.txt`.
 2. Remove packages **not** listed in **either** `setup-packages-keep.txt` or `setup-packages-add.txt`.
 3. Install packages listed in `setup-packages-add.txt`.
 4. Remove packages listed in `setup-packages-del-late.txt`.
