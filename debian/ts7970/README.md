# SolarNode TS-7970 Images

These images were created for the the [TS-7970][1], based 
off the [Node OS Setup Guide - Debian 9][2].

The image names are in the form `[OS]-[hardware]-[SD size]`. **Note**
that you can copy the image to a _larger_ SD card, but you must then
expand the root filesystem, or add another partition, to make use of
the additional space.

The *hardware* names are as follows:

 * `ts7970` - the 1GB RAM version of the [TS-7970][1]
 	
# How to copy images to SD card

To restore these onto a SD card, run the following command:

	# Copy image to SD card located at /dev/sde
	xz -cd solarnode-deb9-ts7970-1GB.img.xz |dd of=/dev/sde bs=2M
	
	# Sync to disk
	sync
	
	# Re-read the partition table
	blockdev --rereadpt /dev/sde
	
	# Just to be sure, let's check the root filesystem
	e2fsck -f /dev/sde1

# Network setup

The OS will attempt to get a network connection using the built-in
ethernet device, and use DHCP to obtain an IP address, using the hostname
**solarnode**. Once the computer has fully booted after turning it on (this
can take several minutes) check your DHCP server to find what IP address was
allocated.

## WiFi setup

You can configure a WiFi connection by creating a `/boot/wpa_supplicant.conf` file
with content like the following, using a plain-text password:

```
country=nz
network={
	ssid="my wifi"
	psk="plain text password here"
}
```

You can also use the `wpa_passphrase` tool to more securely store the password. Run the 
tool like:

```sh
wpa_passphrase "my wifi" "plain text password"
```

It will output the full configuration, which includes a hashed version of the password.
Note that when using this form, you must omit the quotes around the `psk=` value, like
this:

```
country=nz
network={
	ssid="my wifi"
	psk=6a24edf1592aec4465271b7dcd204601b6e78df3186ce1a62a31f40ae9630702
}
```

Note that the OS will move the `/boot/wpa_supplicant.conf` file to 
`/etc/wpa_supplicant/wpa_supplicant-wlan0.conf` when it boots up. 

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
/dev/sdd1        2048 1939455 1937408  946M 83 Linux
```

The image is copied with a `dd` command like this:

```
dd if=/dev/sdd conv=sync,noerror bs=4k count=242432 of=solarnode-deb9-ts7970-1GB.img
```

The image is then compressed, and then a digest computed like this:

```
xz -c -9 solarnode-deb9-ts7970-1GB.img >solarnode-deb9-ts7970-1GB.img.xz
sha256sum solarnode-deb9-ts7970-1GB.img.xz >solarnode-deb9-ts7970-1GB.img.xz.sha256
```

  [1]: https://www.embeddedarm.com/products/TS-7970
  [2]: https://github.com/SolarNetwork/solarnetwork/wiki/Node-OS-Setup-Guide-Debian-9
