# SolarNode Raspberry Pi Images

These images were created for the the [Raspberry Pi][1], based off the [Node OS Setup Guide -
Raspbian][2]. The [setup-pi.sh][setup-pi] script automates the process, which is discussed
in SolarNetwork Foundation's [SolarNode Raspbian Setup Guide][setup-guide].

The image names are in the form `[OS]-[hardware]-[SD size]`. **Note** that you can copy the image to
a _larger_ SD card, but you must then expand the root filesystem, or add another partition, to make
use of the additional space.

The **OS** names are as follows:

 * `solarnodeos` - the current OS setup, using native Debian packages
 * `solarnode` - the legacy OS setup; use `solarnodeos` unless you have a specific need for this

The **hardware** names are as follows:

 * `pi` - the 512MB RAM version of the [Raspberry Pi][1] (Pi 2/3 supported as well)
 	
# How to copy images to SD card

[Download the image][images] to your computer. You need a SD card adapter, either built into your
computer or an external adapter (often these connect via USB). Then, as **root** copy the image
onto a SD card. For example, using Linux the commands look something like the following:

```sh
# Copy image to SD card located at /dev/sde
xz -cd solarnodeos-deb9-pi-1GB.img.xz |dd of=/dev/sde bs=2M

# Sync to disk
sync

# Re-read the partition table
blockdev --rereadpt /dev/sde

# Just to be sure, let's check the root filesystem
e2fsck -f /dev/sde2
```

# Network setup

The OS will attempt to get a network connection using the built-in ethernet device, and use DHCP to
obtain an IP address, using the hostname **solarnode**. Once the computer has fully booted after
turning it on (this can take several minutes) check your DHCP server to find what IP address was
allocated.

## WiFi setup

You can run `dpkg-reconfigure sn-wifi` to configure the WiFi connection settings, which will prompt
you for the WiFi network details. You can also create a `/boot/wpa_supplicant.conf` file _before
booting up the Pi_ with content like the following, using a plain-text password:

```
country=nz
network={
	ssid="my wifi"
	psk="plain text password here"
}
```

You can also use the `wpa_passphrase` tool to more securely store the password. Run the tool like:

```sh
wpa_passphrase "my wifi" "plain text password"
```

It will output the full configuration, which includes a hashed version of the password. Note that
when using this form, you must omit the quotes around the `psk=` value, like this:

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

The system contains a default user of `solar` with password `solar`. That user can use `sudo` to
become the `root` user. You can access the computer via `ssh` only.

# Base SolarNode framework

A base SolarNode framework has been installed in this image. Once the computer has fully booted and
the SolarNode framework has started (this can take several minutes after the OS has booted and `ssh`
is available) you can visit

	http://solarnode/

where `solarnode` is the IP address of the device, if your DNS server does not support using the
_solarnode_ hostname.

# Image partition info

The Debian 9 1GB images are partitioned like this:

```
Device     Boot Start     End Sectors  Size Id Type
/dev/sde1        8192   96453   88262 43.1M  c W95 FAT32 (LBA)
/dev/sde2       98304 1949695 1851392  904M 83 Linux
```

The Debian 10 1GB images are partitioned like this:

```
Device     Boot  Start     End Sectors  Size Id Type
/dev/sde1         8192  139263  131072   64M  c W95 FAT32 (LBA)
/dev/sde2       139264 1953791 1814528  886M 83 Linux
```

The Debian 10 2GB images are partitioned like this:

```
Device     Boot  Start     End Sectors  Size Id Type
/dev/sde1         8192  139263  131072   64M  c W95 FAT32 (LBA)
/dev/sde2       139264 2861055 2721792  1.3G 83 Linux
```

The image is copied with a `dd` command like this:

```
# Debian 9
dd if=/dev/sde conv=sync,noerror bs=4k count=243712 of=solarnodeos-deb9-pi-1GB.img

# Debian 10 (1GB)
dd if=/dev/sde conv=sync,noerror bs=4k count=244224 of=solarnodeos-deb10-pi-1GB.img

# Debian 10 (2GB)
dd if=/dev/sde conv=sync,noerror bs=4k count=357632 of=solarnodeos-deb10-pi-2GB.img
```

The image is then compressed, and then a digest computed like this:

```
xz -c -9 solarnodeos-deb9-pi-1GB.img >solarnodeos-deb9-pi-1GB.img.xz
sha256sum solarnodeos-deb9-pi-1GB.img.xz >solarnodeos-deb9-pi-1GB.img.xz.sha256
```

These steps, and some additional cleanup tasks, are automated via a [prep-disk.sh][prep-disk] and
[prep-image.sh][prep-image] scripts.

# Setup script

The [../bin/setup-sn.sh](../bin/setup-sn.sh) script performs most of the work for customizing a
Raspbian-based OS image into SolarNodeOS. This can be executed via the
[customize](../bin/customize.sh) script, something like the following, which takes the
`2020-08-20-raspios-buster-armhf-lite.img` upstream image and produces
`solarnodeos-deb10-pi-2GB-20200907.img` (the date will be based on the current date):

```sh
sudo ../bin/customize.sh -v -z \
	-E 500 \
	-P boot -p rootfs \
	-a '-a raspberrypi -o 172.16.159.196:3142' \
	-o solarnodeos-deb10-pi-2GB-$(date '+%Y%m%d').img \
	/var/tmp/2020-08-20-raspios-buster-armhf-lite.img \
	../bin/setup-sn.sh \
	$PWD:/tmp/overlay 
```


[1]: https://www.raspberrypi.org/
[2]: https://github.com/SolarNetwork/solarnetwork/wiki/Node-OS-Setup-Guide-Raspbian
[images]: https://sourceforge.net/projects/solarnetwork/files/solarnode/pi/
[setup-pi]: https://github.com/SolarNetwork/solarnode-os-images/blob/master/debian/pi/bin/setup-pi.sh
[prep-disk]: https://github.com/SolarNetwork/solarnode-os-images/blob/master/debian/bin/prep-disk.sh
[prep-image]: https://github.com/SolarNetwork/solarnode-os-images/blob/master/debian/bin/prep-image.sh
[setup-guide]: https://github.com/SolarNetworkFoundation/solarnetwork-ops/wiki/SolarNode-Raspbian-Setup-Guide
