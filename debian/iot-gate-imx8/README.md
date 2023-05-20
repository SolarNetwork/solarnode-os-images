# SolarNode IOT-GATE-iMX8 Images

Here's an example of creating a SolarNodeOS 11 image out of a Debian `bullseye` IOT-GATE-iMX8 source
image:

```sh
sudo ../bin/customize.sh -v -z \
	-N 1 -n 2 -c -M /boot -U -E 700 \
	-a '-a iot-gate-imx8 -E -V compulab -E -M 11 -q bullseye -m -w -Q -D conf/packages-deb11-del-early.txt -K conf/packages-deb11-add.txt -A conf/packages-deb11-add-late.txt -k conf/packages-deb11-keep.txt -X bin/extra-early.sh -x bin/extra-late.sh -o 172.16.159.143:3142' \
	-o /var/tmp/solarnodeos-deb11-iotgateimx8-2GB-$(date '+%Y%m%d').img \
	/var/tmp/debian.iot-gate-imx8.live-img.xz \
	../bin/setup-sn.sh \
	$PWD:/tmp/overlay
```

# Copying to eMMC

To copy the image to the eMMC on an IoT device

1. Connect a USB cable between the micro-USB "Console" serial port on the IoT and your computer
2. Connect to the USB console with a terminal emulator, e.g. `screen /dev/tty.usbserial-0236DBD7 115200`
3. Copy the image to a USB stick, plug the USB stick into the IoT, power it on
4. The IoT will boot SolarNodeOS; log in as `solar/solar`
5. Switch to `root` with `sudo su - ` and then run `cl-deploy` and follow the prompts
