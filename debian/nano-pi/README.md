# SolarNode Nano Pi Images

These images were created for the the NanoPi by [Friendly Elec][1].

The image names are in the form `[OS]-[hardware]-[SD size]`. **Note**
that you can copy the image to a _larger_ SD card, but you must then
expand the root filesystem, or add another partition, to make use of
the additional space.

The *hardware* names are as follows:

 * `nanopi-air` - the 512MB RAM version of the [NanoPi NEO Air][2]
 	
# How to copy images to SD card

To restore these onto a SD card, run the following command:

	# Copy image to SD card located at /dev/sdd
	xz -cd solarnode-deb9-nanopi-air-1GB.img.xz |dd of=/dev/sdd bs=2M
	
	# Sync to disk
	sync
	
	# Re-read the partition table
	blockdev --rereadpt /dev/sdd
	
	# Just to be sure, let's check the root filesystem
	e2fsck -f /dev/sdd1

# Network setup

The OS will attempt to get a network connection using the built-in
ethernet device, and use DHCP to obtain an IP address, using the hostname
**solarnode**. Once the computer has fully booted after turning it on (this
can take several minutes) check your DHCP server to find what IP address was
allocated.

# Login user

The system contains a default user of `solar` with password `solar`. That user can
use `sudo` to become the `root` user. You can access the computer via `ssh` only.

# Base SolarNode framework

A base SolarNode framework has been installed in this image. Once the computer has
fully booted and the SolarNode framework has started (this can take several minutes
after the OS has booted and `ssh` is available) you can visit

	http://solarnode/

where `solarnode` is the IP address of the device, if your DNS server does not
support using the _solarnode_ hostname.

# Image partition info

The 1GB images are paritioned like this:

```
Device     Boot Start     End Sectors  Size Id Type
/dev/sdd1        8192 1949695 1941504  948M 83 Linux
```

The 2GB images are partitioned like this:

```
Device     Boot  Start     End Sectors  Size Id Type
/dev/sde1        40960  143359  102400   50M  c W95 FAT32 (LBA)
/dev/sde2       143360 2717695 2574336  1.2G 83 Linux
```

The image is copied with a `dd` command like this:

```
# 1GB
dd if=/dev/sdd conv=sync,noerror bs=4k count=243712 of=solarnode-deb9-orangepi-zero-1GB.img

# 2GB
dd if=/dev/sde conv=sync,noerror bs=4k count=357632 of=solarnodeos-deb9-orangepi-zero-2GB.img
```

The image is then compressed, and then a digest computed like this:

```
xz -c -9 solarnode-deb9-orangepi-zero-1GB.img >solarnode-deb9-orangepi-zero-1GB.img.xz
sha256sum solarnode-deb9-orangepi-zero-1GB.img.xz >solarnode-deb9-orangepi-zero-1GB.img.xz.sha256
```

# Development

The Armbian build process was used to turn Armbian into SolarNodeOS by following these steps:

## Setup Armbian build for Vagrant

Either check out directly or create a symbolic link to the build repository named `armbian-build`.

Add the following to the `Main()` function:

```
if [ -e /tmp/overlay/sn-$BOARD/bin/setup-sn.sh ]; then
	echo "SolarNode setup script discovered at /tmp/overlay/sn-$BOARD/bin/setup-sn.sh"
	export LANG=C LC_ALL="en_US.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	/tmp/overlay/sn-$BOARD/bin/setup-sn.sh -i /tmp/overlay/sn-$BOARD
	rm -f /root/.not_logged_in_yet
fi
```

Copy the contents of this directory to the `userpatches/overlay` directory as the appropriate
directory named for the board being built:

```sh
rsync -av bin conf armbian-build/userpatches/overlay/sn-nanopiair
```

## Execute build

Bring up Vagrant and then run build:

```sh
$ cd armbian-build/config/templates
$ vagrant reload
$ vagrant ssh -c 'sudo armbian/userpatches/overlay/sn-nanopiair/bin/armbian-build.sh'
```

  [1]: https://friendlyarm.com/
  [2]: http://wiki.friendlyarm.com/wiki/index.php/NanoPi_NEO_Air
