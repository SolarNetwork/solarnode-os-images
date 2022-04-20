# SolarNodeOS - Debian Raspberry Pi

This document has a brief overview of the SolarNodeOS release history.

# SolarNodeOS - Debian 11

These are SolarNodeOS images based on the Debian 11 "bullseye" release. **Note** these images are
not based on RaspiOS. Rather they are derived from "vanilla" Debian Raspberry Pi images. They are
also hardware-specific, so for example `pi3` is for the Pi 3B+ while `pi4` is for the Pi 4.

## 2022-03-02

Based on Debian upstream 2022.01.21 images with Debian 11.2 and the 5.10 series Linux kernel. This
image requires a 1GB SD card at a minimum.

Includes the following core SolarNode packages:

| Package                     | Version | Description |
|:----------------------------|:--------|:------------|
| libmodbus5                  | 3.1.6-2 | Shared library used by `mbpoll`. |
| libyasdi                    | 1.8.1-Build9 | Shared library used by `yasdishell`. |
| mbpoll                      | 1.4.11+dfsg-2 | Command line utility to communicate with Modbus devices. | 
| sn-nftables                 | 1.1.0-2 | Firewall configuration. |
| sn-osstat                   | 1.1.0-2 | Support for OS statistic collection. |
| sn-pi                       | 1.1.1-4 | Raspberry Pi specific system configuration. |
| sn-solarpkg                 | 1.1.1-1 | SolarNode package management support. |
| sn-solarssh                 | 1.0.0-3 | SolarSSH support. |
| sn-system                   | 1.4.0-1 | Core OS support for SolarNode. |
| sn-wifi                     | 1.3.0-2 | WiFi configuration management. |
| solarnode-app-core          | [2.3.5-1][solarnode-app-core-log] | SolarNode application core. |
| solarnode-app-io-mqtt       | 2.1.0-2 | SolarNode MQTT I/O API. |
| solarnode-app-io-mqtt-netty | 2.1.1-1 | SolarNode MQTT I/O Netty implementation. |
| solarnode-base              | [1.12.0-1][solarnode-base-log] | SolarNode application base framework. |
| yasdishell                  | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |


[solarnode-app-core-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-app-core/debian/CHANGELOG.md
[solarnode-base-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-base/debian/CHANGELOG.md
