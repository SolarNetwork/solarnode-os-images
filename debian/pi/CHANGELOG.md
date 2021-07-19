# SolarNodeOS - Debian 10 Raspberry Pi

This is a SolarNodeOS image based on the Debian 10 "buster" release.

## 2021-07-19

Based on the upstream RaspiOS (formerly Raspbian) `2021-05-07-raspios-buster-armhf-lite` image,
and is based on Debian 10.10 and the 5.10.17 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package                     | Version | Description |
|:----------------------------|:--------|:------------|
| libmodbus                   | 3.1.6-1 | Shared library used by `mbpoll`. |
| mbpoll                      | 1.4.11  | Command line utility to communicate with Modbus devices. | 
| sn-nftables                 | 1.1.0-1 | Firewall configuration. |
| sn-osstat                   | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi                       | 1.1.0-2 | Raspberry Pi specific system configuration. |
| sn-solarpkg                 | 1.1.1-1 | SolarNode package management support. |
| sn-solarssh                 | 1.0.0-3 | SolarSSH support. |
| sn-system                   | 1.2.6-1 | Core OS support for SolarNode. |
| sn-wifi                     | 1.3.0-2 | WiFi configuration management. |
| solarnode-app-core          | [1.22.1-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-app-io-mqtt       | 1.1.0-1 | SolarNode MQTT I/O API. |
| solarnode-app-io-mqtt-netty | 1.0.1-1 | SolarNode MQTT I/O Netty implementation. |
| solarnode-base              | [1.11.0-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell                  | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |


## 2021-06-01

Based on the upstream RaspiOS (formerly Raspbian) `2021-05-07-raspios-buster-armhf-lite` image,
and is based on Debian 10.9 and the 5.10.17 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package                     | Version | Description |
|:----------------------------|:--------|:------------|
| libmodbus                   | 3.1.6-1 | Shared library used by `mbpoll`. |
| mbpoll                      | 1.4.11  | Command line utility to communicate with Modbus devices. | 
| sn-nftables                 | 1.1.0-1 | Firewall configuration. |
| sn-osstat                   | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi                       | 1.1.0-2 | Raspberry Pi specific system configuration. |
| sn-solarpkg                 | 1.1.1-1 | SolarNode package management support. |
| sn-solarssh                 | 1.0.0-3 | SolarSSH support. |
| sn-system                   | 1.2.6-1 | Core OS support for SolarNode. |
| sn-wifi                     | 1.3.0-2 | WiFi configuration management. |
| solarnode-app-core          | [1.18.1-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-app-io-mqtt       | 1.0.1-1 | SolarNode MQTT I/O API. |
| solarnode-app-io-mqtt-netty | 1.0.1-1 | SolarNode MQTT I/O Netty implementation. |
| solarnode-base              | [1.9.0-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell                  | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |


## 2021-04-14

Based on the upstream RaspiOS (formerly Raspbian) `2021-03-04-raspios-buster-armhf-lite` image,
which is based on Debian 10.8 and the 5.10.17 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.6-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-2 | Raspberry Pi specific system configuration. |
| sn-solarpkg        | 1.1.0-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-3 | SolarSSH support. |
| sn-system          | 1.2.3-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.3.0-2 | WiFi configuration management. |
| solarnode-app-core | [1.14.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.8.1-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |


## 2021-03-03

Based on the upstream RaspiOS (formerly Raspbian) `2021-01-11-raspios-buster-armhf-lite` image,
which is based on Debian 10.7 and the 5.4.83 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-solarpkg        | 1.1.0-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-3 | SolarSSH support. |
| sn-system          | 1.2.3-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.3.0-2 | WiFi configuration management. |
| solarnode-app-core | [1.12.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.8.1-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |

## 2021-02-17

Based on the upstream RaspiOS (formerly Raspbian) `2021-01-11-raspios-buster-armhf-lite` image,
which is based on Debian 10.7 and the 5.4.83 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-solarpkg        | 1.1.0-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-3 | SolarSSH support. |
| sn-system          | 1.2.3-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.2.0-1 | WiFi configuration management. |
| solarnode-app-core | [1.10.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.8.0-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |

## 2020-09-01

Based on the upstream RaspiOS (formerly Raspbian) `2020-08-20-raspios-buster-armhf-lite` image,
which is based on Debian 10.4 and the 5.4.51 Linux kernel. This image requires a 2GB SD card at a
minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-solarpkg        | 1.1.0-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-3 | SolarSSH support. |
| sn-system          | 1.2.3-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.2.0-1 | WiFi configuration management. |
| solarnode-app-core | [1.10.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.7.0-2][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |

## 2020-06-12

Updates the base OS to the Debian 10.4 release and updates the core SolarNode packages. This image
requires a 2GB SD card at a minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.1-2 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.3-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.1.1-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| solarnode-app-core | [1.8.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.5.2-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |

## 2020-04-14

Updates the base OS to the Debian 10.3 release and updates the core SolarNode
packages. This image requires a 2GB SD card at a minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.1-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.3-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.1.1-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| solarnode-app-core | [1.7.0-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-base     | [1.5.2-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |

## 2020-01-28

Updates the base OS to the Debian 10.2 release and updates the core SolarNode
packages. This image requires a 2GB SD card at a minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11-1 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.1-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.3-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.1.1-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |
| solarnode-app-core | [1.5.0-1][solarnode-app-core-log] | SolarNode core application. |
| solarnode-base     | [1.5.2-1][solarnode-base-log] | SolarNode base platform. |


## 2019-10-25

Updates the base OS to the Debian 10.1 release and updates the core SolarNode
packages. This image requires a 2GB SD card at a minimum.

Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with Modbus devices. | 
| sn-nftables        | 1.1.0-1 | Firewall configuration. |
| sn-osstat          | 1.1.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.1.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.1-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.2-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.1.0-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |
| solarnode-base     | 1.3.1-1 | SolarNode application base framework. |
| solarnode-app-core | 1.2.0-1 | SolarNode application core. |

## 2019-07-19

Initial release based on Debian 10 "buster". The major differences in this
update from Debian 9 are:

 * OpenJDK 11 replaces Oracle 8 JRE
 * `nftables` replaces `iptables` for firewall
 
Because of the change from Java 8 to 11, there might be unexpected issues in
this release. Please test your application thoroughly and report any issues you
find.
 
Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with ModBus devices. | 
| sn-nftables        | 1.0.0-1 | Firewall configuration. |
| sn-osstat          | 1.0.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.0.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.0-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.2-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.0.0-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |
| solarnode-base     | 1.1.0-1 | SolarNode application base framework. |
| solarnode-app-core | 1.0.2-1 | SolarNode application core. |


# SolarNodeOS - Debian Rasperry Pi

The way SolarNode OS images has changed to use native Debian packages. The
filename for them has changed to use _solarnodeos_ in place of _solarnode_.

## 2019-05-30

Initial release. Includes the following core SolarNode packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11 | Command line utility to communicate with ModBus devices. | 
| sn-iptables        | 1.0.0-2 | Firewall configuration. |
| sn-osstat          | 1.0.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.0.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.0-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.2-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.0.0-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-1 | WiFi configuration management. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |
| solarnode-base     | 1.0.1-1 | SolarNode application base framework. |
| solarnode-app-core | 1.0.1-2 | SolarNode application core. |


# SolarNode Debian OS - Raspberry Pi

These images have been created without native Debian packages.

## 2018-11-30

 * Update to latest Raspbian packages

## 2018-10-24

 * Add service to automatically start/restart wpa\_supplicant when
   the wlan0 configuration is created/changed.

## 2018-10-17

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20181017

## 2018-08-14

 * Add `solarstat` tool to support OS Statistics plugin.
 * Update to SolarNode base framework 20180814

## 2018-07-23

 * Add SolarSSH cleanup task
 * Update to latest Raspbian packages

## 2018-05-12

 * Recreate image from scratch using latest Raspbian Lite image
 * Add `solarnode-wpa-config` service to copy `/boot/wpa_supplicant.conf` to
   right place when OS boots, like what Raspbian provides

## 2018-04-20

 * Enable hardware watchdog with systemd and automatic crash reboot
 * Update to latest Raspbian packages

## 2018-04-09

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20180409

## 2017-12-21

 * Add `mbpoll` package for command line Modbus testing
 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20171221

## 2017-12-12

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20171121
 * Add Debian 9 (Stretch) image
 * Replace exim4 MTA with (smaller) dma
 * Remove more unnecessary packages

## 2017-11-08

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20171105
 * Add auto-expand root file system support


## 2017-11-03

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20171103


## 2017-10-24

 * Fix /etc/fstab to use labels so image more easily works with libguestfs


## 2017-10-05

 * Add S3 backup support
 * Update to SolarNode base framework 20171005
 * Remove 60+ unnecessary OS packages


## 2017-09-29

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20170929


## 2017-07-25

 * Update to latest Raspbian packages
 * Update to SolarNode base framework 20170725
 * Adjust JVM memory parameters with `-XX:MaxMetaspaceSize` -Xmx128m for
   better performance


## 2017-06-29

 * Update the system.ssh plugin to address a potential startup bug.


## 2017-06-28

 * Update to latest Raspbian packages
 * Update to SolarNode platform 20170628
 * Configure SolarSSH support with systemd


## 2017-05-09

 * Update to latest Raspbian packages
 * Update to SolarNode bundle release 20170509
 * Add configuration to limit journald log to 10M
 * Add configuration systemd to not generate core dumps

[solarnode-app-core-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-app-core/debian/CHANGELOG.md
[solarnode-base-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-base/debian/CHANGELOG.md
