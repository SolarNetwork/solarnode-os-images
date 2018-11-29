# SolarRFID Raspberry Pi Images

These images were created for the the [Raspberry Pi][1] and contain a
RFID server service, based on the `rfid-server` in the [Node RFID Scanner][2]
plugin. This allows you to plug in a USB RFID card reader into a Pi
and expose the scanned card IDs via a TCP socket server on port 9090.
Compatible client software can then easily integrate with this service
to get RFID card IDs when they are scanned.

**Note** that only RFID card readers that operate as keyboard devices are
supported. This is common for USB based card readers.

# Configuring RFID card reader

The OS must be configured to create a device link named `/dev/rfidX` (where
`X` is a number) for each card reader to be used. This is handled by the
`/etc/udev/rules.d/a11-rfid-multi.rules` configuration file. This image
has sample rules that work with StrongLink USB CardReader devices. The
udev rule looks like this:

```
SUBSYSTEM=="input", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="1503", SYMLINK+="rfid%n", TAG+="systemd", ENV{SYSTEMD_WANTS}="rfid-server@rfid%n.service"
```

The **idVendor** and **idProduct** must match the values of your card reader.
You can find these out easily if you plug in the reader and then run `dmesg |tail`:

```
$ dmesg |tail
[ 2543.631320] usb 1-1.3: New USB device found, idVendor=04d9, idProduct=1503
[ 2543.631332] usb 1-1.3: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[ 2543.631341] usb 1-1.3: Product: USB CardReader
[ 2543.631349] usb 1-1.3: Manufacturer: StrongLink
```

# How to copy images to SD card

To restore these onto a SD card, run the following command:

	# Copy image to SD card located at /dev/sde
	xz -cd solarrfid-deb9-pi-1GB.img.xz |dd of=/dev/sde bs=2M
	
	# Sync to disk
	sync
	
	# Re-read the partition table
	blockdev --rereadpt /dev/sde
	
	# Just to be sure, let's check the root filesystem
	e2fsck -f /dev/sde2

# Network setup

The OS will attempt to get a network connection using the built-in
ethernet device, and use DHCP to obtain an IP address, using the hostname
**rfid-server**. Once the computer has fully booted after turning it on (this
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

# Image partition info

The 1GB images are paritioned like this:

```
Device     Boot Start     End Sectors  Size Id Type
/dev/sde1        8192   96453   88262 43.1M  c W95 FAT32 (LBA)
/dev/sde2       98304 1949695 1851392  904M 83 Linux
```

The image is copied with a `dd` command like this:

```
dd if=/dev/sde conv=sync,noerror bs=4k count=243712 of=solarrfid-deb9-pi-1GB.img
```

The image is then compressed, and then a digest computed like this:

```
xz -c -9 solarrfid-deb9-pi-1GB.img >solarrfid-deb9-pi-1GB.img.xz
sha256sum solarrfid-deb9-pi-1GB.img.xz >solarrfid-deb9-pi-1GB.img.xz.sha256
```

  [1]: https://www.raspberrypi.org/
  [2]: https://github.com/SolarNetwork/solarnetwork-node/tree/master/net.solarnetwork.node.hw.rfid/def/rfid-reader
