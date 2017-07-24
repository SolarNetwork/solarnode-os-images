# SolarNode Raspberry Pi Images

These images were created for the the [Raspberry Pi][1], based 
off the [SolarNode OS Setup Guide - Raspbian][2].

The image names are in the form `[OS]-[hardware]-[SD size]` and were
created using `dd` similar to this:

	dd if=/dev/sdb conv=sync,noerror,notrunc bs=4k count=244224 
		|xz -9 >solarnode-deb8.0-pi-1GB.img.xz

The *hardware* names are as follows:

 * `pi` - the 512MB RAM version of the [Raspberry Pi][1]
 	
# How to copy images to SD card

To restore these onto a SD card, run the following command:

	# Copy image to SD card located at /dev/sdb
	xz -cd solarnode-deb8.0-pi-1GB.img.xz |dd of=/dev/sdb bs=2M
	
	# Sync to disk
	sync
	
	# Re-read the partition table
	blockdev --rereadpt /dev/sdb
	
	# Just to be sure, let's check the root filesystem
	e2fsck -f /dev/sdb2

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

  [1]: https://www.raspberrypi.org/
  [2]: https://github.com/SolarNetwork/solarnetwork/wiki/SolarNode-OS-Setup-Guide-Raspbian
