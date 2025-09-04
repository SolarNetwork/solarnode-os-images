# SolarNode IOT-LINK-iMX93 Images

This directory contains support for building SolarNodeOS images for the Compulab IoT Link iMX93
device.

## Copying to eMMC

To copy the image to the eMMC on an IoT device

1. Connect a USB cable between the micro-USB "Console" serial port on the IoT and your computer
2. Connect to the USB console with a terminal emulator, e.g. `screen /dev/tty.usbserial-0236DBD7 115200`
3. Copy the image to a USB stick, plug the USB stick into the IoT, power it on
4. The IoT will boot SolarNodeOS; log in as `solar/solar`
5. Run `sn-reset -a && sn-stop` to reset SolarNode to a clean state
6. Run `sudo rm -f /etc/ssh/ssh_host*` to remove `ssh` host keys, so not copied to eMMC.
7. Run `sudo cl-deploy` and follow the prompts (on the final screen, choose **No** when asked to restart)

```sh
sn-reset -a && sn-stop
sudo rm -f /etc/ssh/ssh_host*
sudo cl-deploy
sudo shutdown -h now
```

Once shut down, disconnect power, unplug the USB stick, and reconnect power to boot from eMMC.

:bulb: **Note** that when running `cl-deploy` you must select the eMMC target on the first screen,
even though there is only one choice. Select it with the <kbd>Space</kbd> key, then 
<kbd>Enter</kbd> to move to the next screen. The screen will look like this:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Available Devices:                                                           │
│ ┌──────────────────────────────────────────────────────────────────────────┐ │
│ │                            ( ) /dev/mmcblk0                              │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────────────┤
│                       <  OK  >            <Cancel>                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

After typing <kbd>Space</kbd> it will change to this:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Available Devices:                                                           │
│ ┌──────────────────────────────────────────────────────────────────────────┐ │
│ │                            (*) /dev/mmcblk0                              │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────────────┤
│                       <  OK  >            <Cancel>                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Building

Here's an example of creating a SolarNodeOS 12 image out of a Debian `bookworm` IOT-LINK-iMX93
source image using the [customize.sh](../README.md#customize-script) script:

```sh
sudo ../bin/customize.sh -v -z \
	-N 1 -n 2 -c -M /boot -U \
	-E 1312 \   
	-a '-a iot-link -V compulab -E -M 12 -q bookworm -m -w -Q -Z UTC -D conf/packages-deb12-del-early.txt -K conf/packages-deb12-add.txt -k conf/packages-deb12-keep.txt -X bin/extra-early.sh -x bin/extra-late.sh -o 172.16.159.128:3142' \
	-o /var/tmp/solarnodeos-deb12-iotlink_imx93-2GB-$(date '+%Y%m%d').img \
	/var/tmp/debian-bookworm-arm64-rt_iot-link_live-img.img.xz \
	../bin/setup-sn.sh \
	$PWD:/tmp/overlay
```

:bulb: **Note** Compulab distributes the source image as a `.zip` file, but `customize.sh` works
with `.xz` files, so the original image was uncompressed and re-compressed. For example:

```sh
unzip iot-link_debian-linux_2025-07-23.zip
xz debian-bookworm-arm64-rt_iot-link_live-img.img
```