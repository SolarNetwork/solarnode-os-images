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
