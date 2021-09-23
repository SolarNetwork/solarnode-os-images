# SolarNode Orange Pi Images

These images were created for the the [Orange Pi][1], based
off the [Node OS Setup Guide - Armbian Orange Pi][2].

The image names are in the form `[OS]-[hardware]-[SD size]`. **Note**
that you can copy the image to a _larger_ SD card, but you must then
expand the root filesystem, or add another partition, to make use of
the additional space.

The *hardware* names are as follows:

 * `orangepi-zero` - the 512MB RAM version of the [Orange Pi Zero][3]

# How to copy images to SD card

To restore these onto a SD card, run the following command:

	# Copy image to SD card located at /dev/sdd
	xz -cd solarnode-deb9-orangepi-zero-1GB.img.xz |dd of=/dev/sdd bs=2M

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

Adjust the `Main()` function in `userpatches/customize-image.sh`. See [the example Main()
function](../conf/armbian-customize-image-example.sh) for more details. For example:

```
Main() {
	echo "HOWDY! $RELEASE,$LINUXFAMILY,$BOARD"
	rm -f /root/.not_logged_in_yet
} # Main
```

Copy the contents of this directory to the `userpatches/overlay` directory as the appropriate
directory named for the board being built:

```sh
rsync -avL bin conf armbian-build/userpatches/overlay/sn-orangepizero
```

## Execute build

Bring up Vagrant and then run build:

```sh
$ cd armbian-build/config/templates
$ vagrant reload
$ vagrant ssh -c 'sudo BOARD=orangepizero armbian/userpatches/overlay/sn-orangepizero/bin/armbian-build.sh -I'
```

Now you can run the `customize.sh` script to turn the Armbian image into SolarNodeOS. For example
here's a development build of Debian 11 (Bullseye):

```
sudo /opt/sn/solarnode-os-images/debian/bin/customize.sh -v -z \
        -N 1 -n 2 -e 200 -E 400 -c -r btrfs \
        -a '-a orangepizero -M 11 -q bullseye -w -Q -K conf/packages-deb11-add.txt -k conf/packages-deb11-keep.txt -p http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com -o 172.16.159.3:3142' \
        -o /var/tmp/solarnodeos-deb11-orangepi-zero-1GB-$(date '+%Y%m%d').img \
        ~/Documents/solarnode-os-images/debian/orange-pi/armbian-build/output/images/Armbian_21.11.0-trunk_Orangepizero_bullseye_current_5.10.60_minimal.img \
        ~/Documents/solarnode-os-images/debian/bin/setup-sn.sh \
        ~/Documents/solarnode-os-images/debian/orange-pi:/tmp/overlay
```

[1]: https://www.orangepi.org/
[2]: https://github.com/SolarNetwork/solarnetwork/wiki/Node-OS-Setup-Guide-Armbian-Orange-Pi
[3]: http://www.orangepi.org/orangepizero/
