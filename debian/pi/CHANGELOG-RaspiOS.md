# SolarNodeOS - Raspberry Pi OS

This document has a brief overview of the SolarNodeOS release history based on 
[Raspberry Pi OS][raspios].

# Debian 12

These are SolarNodeOS images based on the Debian 12 "bookworm" release.

## 2024-08-26

Based on the upstream RaspiOS (formerly Raspbian) `2024-07-04-raspios-bookworm-arm64-lite` image,
and is based on Debian 12.6 and the 6.6 Linux kernel. This image requires a 2GB or larger SD card.

Includes the following core SolarNode packages:

| Package                         | Version  | Description |
|:--------------------------------|:---------|:------------|
| sn-mbpoll                       | 1.5.2-1  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1  | nftables firewall management service |
| sn-osstat                       | 1.1.0-2  | SolarNode OS statistics support |
| sn-pi                           | 1.2.0-1  | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1  | Raspberry Pi USB support |
| sn-solarpkg                     | 1.3.0-1  | SolarNode package management support |
| sn-solarssh                     | 1.0.0-4  | SolarSSH support |
| sn-system                       | 1.7.1-1  | SolarNode system support |
| sn-wifi                         | 1.4.0-2  | WiFi management service |
| solarnode-app-core              | [3.34.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1  | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 4.0.0-1  | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 4.0.1-1  | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [4.4.1-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-aws              | 1.0.0-1  | SolarNode platform AWS support |
| solarnode-base-blueprint-gemini | 3.0.0-2  | SolarNode platform Gemini Blueprint support |
| solarnode-base-bouncy-castle    | 1.0.0-1  | SolarNode platform Bouncy Castle PKI support |
| solarnode-base-h2               | 1.0.1-1  | SolarNode platform H2 database support |
| solarnode-base-httpclient       | 1.1.0-1  | SolarNode platform HTTP client support |
| solarnode-base-jackson          | 1.1.0-1  | SolarNode platform Jackson JSON support |
| solarnode-base-java17           | 1.0.0-1  | SolarNode platform Java 17 support |
| solarnode-base-jaxb             | 1.0.0-2  | SolarNode platform JAXB support |
| solarnode-base-log4j2           | 2.23.1-2 | SolarNode platform Log4j2 logging support |
| solarnode-base-netty            | 1.1.0-1  | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1  | SolarNode platform Reactive Streams support |
| solarnode-base-slf4j            | 1.7.36-2 | SolarNode platform Slf4j logging support |
| solarnode-base-spring           | 2.0.0-1  | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1  | SolarNode platform Spring Security support |
| solarnode-base-tiles            | 1.0.0-3  | SolarNode platform Apache Tiles support |
| solarnode-base-xalan            | 1.0.0-2  | SolarNode platform Xalan XSLT/Xerces XML support |


## 2024-04-21

Based on the upstream RaspiOS (formerly Raspbian) `2024-03-15-raspios-bookworm-arm64-lite` image,
and is based on Debian 12.5 and the 6.6 Linux kernel. This image requires a 2GB or larger SD card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26-1 | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1 | Raspberry Pi USB support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.7.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.17.1-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [4.0.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |


## 2023-12-19

Based on the upstream RaspiOS (formerly Raspbian) `2023-12-11-raspios-bookworm-arm64-lite` image,
and is based on Debian 12.4 and the 6.1 Linux kernel. This image requires a 2GB or larger SD card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26-1 | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1 | Raspberry Pi USB support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.6.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.10.1-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [3.0.3-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |


# Debian 11

These are SolarNodeOS images based on the Debian 11 "bullseye" release.

## 2024-08-26

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.10 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD card.

Includes the following core SolarNode packages:

| Package                         | Version  | Description |
|:--------------------------------|:---------|:------------|
| sn-mbpoll                       | 1.5.2-1  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1  | nftables firewall management service |
| sn-osstat                       | 1.1.0-2  | SolarNode OS statistics support |
| sn-pi                           | 1.2.0-1  | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1  | Raspberry Pi USB support |
| sn-solarpkg                     | 1.3.0-1  | SolarNode package management support |
| sn-solarssh                     | 1.0.0-4  | SolarSSH support |
| sn-system                       | 1.7.1-1  | SolarNode system support |
| sn-wifi                         | 1.4.0-2  | WiFi management service |
| solarnode-app-core              | [3.34.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1  | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 4.0.0-1  | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 4.0.1-1  | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [4.4.1-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-aws              | 1.0.0-1  | SolarNode platform AWS support |
| solarnode-base-blueprint-gemini | 3.0.0-2  | SolarNode platform Gemini Blueprint support |
| solarnode-base-bouncy-castle    | 1.0.0-1  | SolarNode platform Bouncy Castle PKI support |
| solarnode-base-h2               | 1.0.1-1  | SolarNode platform H2 database support |
| solarnode-base-httpclient       | 1.1.0-1  | SolarNode platform HTTP client support |
| solarnode-base-jackson          | 1.1.0-1  | SolarNode platform Jackson JSON support |
| solarnode-base-java17           | 1.0.0-1  | SolarNode platform Java 17 support |
| solarnode-base-jaxb             | 1.0.0-2  | SolarNode platform JAXB support |
| solarnode-base-log4j2           | 2.23.1-2 | SolarNode platform Log4j2 logging support |
| solarnode-base-netty            | 1.1.0-1  | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1  | SolarNode platform Reactive Streams support |
| solarnode-base-slf4j            | 1.7.36-2 | SolarNode platform Slf4j logging support |
| solarnode-base-spring           | 2.0.0-1  | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1  | SolarNode platform Spring Security support |
| solarnode-base-tiles            | 1.0.0-3  | SolarNode platform Apache Tiles support |
| solarnode-base-xalan            | 1.0.0-2  | SolarNode platform Xalan XSLT/Xerces XML support |


## 2024-04-21

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.9 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26-1 | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1 | Raspberry Pi USB support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.7.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.17.1-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [4.0.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |


## 2023-12-19

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.8 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26-1 | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-pi-usb-support               | 1.2.0-1 | Raspberry Pi USB support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.6.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.10.1-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.1-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [3.0.3-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-12-05

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.8 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD
card.

> **Note** this release updates the Java runtime from 11 to 17, and Tomcat 8.5 to 9.0.
> Most SolarNode packages should not be impacted by these changes, but be sure to test any
> packages you rely on.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.6.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.9.3-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [3.0.2-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-10-29

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.8 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                     | 1.2.0-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.5.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.7.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [2.1.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-06-04

Based on the upstream RaspiOS (formerly Raspbian) `2023-05-03-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.7 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                     | 1.1.2-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.5.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.4.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [2.0.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-04-28

Based on the upstream RaspiOS (formerly Raspbian) `2023-02-21-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.6 and the 6.1.21 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| sn-mbpoll                       | 1.4.26  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                     | 1.1.2-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.5.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.3.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [2.0.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-03-09

Based on the upstream RaspiOS (formerly Raspbian) `2023-02-21-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.6 and the 5.15.84 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                         | Version | Description |
|:--------------------------------|:--------|:------------|
| mbpoll                          | 1.4.11  | Command line utility to communicate with Modbus devices |
| sn-nftables                     | 1.1.1-1 | nftables firewall management service |
| sn-osstat                       | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                           | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                     | 1.1.2-1 | SolarNode package management support |
| sn-solarssh                     | 1.0.0-3 | SolarSSH support |
| sn-system                       | 1.5.0-1 | SolarNode system support |
| sn-wifi                         | 1.4.0-2 | WiFi management service |
| solarnode-app-core              | [3.0.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2             | 2.0.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt           | 3.0.0-1 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty     | 3.0.0-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                  | [2.0.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2               | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson          | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty            | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-reactive-streams | 1.0.0-1 | SolarNode platform Reactive Streams support |
| solarnode-base-spring           | 2.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security  | 2.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                      | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2023-01-12

Based on the upstream RaspiOS (formerly Raspbian) `2022-09-22-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.6 and the 5.15.84 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                        | Version | Description |
|:-------------------------------|:--------|:------------|
| mbpoll                         | 1.4.11  | Command line utility to communicate with Modbus devices | 
| sn-nftables                    | 1.1.1-1 | nftables firewall management service |
| sn-osstat                      | 1.1.0-2 | SolarNode OS statistics support |
| sn-pi                          | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-solarpkg                    | 1.1.2-1 | SolarNode package management support |
| sn-solarssh                    | 1.0.0-3 | SolarSSH support |
| sn-system                      | 1.5.0-1 | SolarNode system support |
| sn-wifi                        | 1.4.0-2 | WiFi management service |
| solarnode-app-core             | [2.11.0-1][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2            | 1.1.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt          | 2.1.0-2 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty    | 2.1.1-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                 | [1.16.0-1][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2              | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson         | 1.0.0-2 | SolarNode platform Jackson JSON support |
| solarnode-base-netty           | 1.0.0-2 | SolarNode platform Netty support |
| solarnode-base-spring          | 1.0.0-2 | SolarNode platform Spring support |
| solarnode-base-spring-security | 1.0.0-2 | SolarNode platform Spring Security support |
| yasdishell                     | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


## 2022-04-20

Based on the upstream RaspiOS (formerly Raspbian) `2022-04-04-raspios-bullseye-arm64-lite` image,
and is based on Debian 11.3 and the 5.15.32 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                        | Version | Description |
|:-------------------------------|:--------|:------------|
| mbpoll                         | 1.4.11  | Command line utility to communicate with Modbus devices | 
| sn-nftables                    | 1.1.0-3 | nftables firewall management service |
| sn-osstat                      | 1.1.0-1 | SolarNode OS statistics support |
| sn-pi                          | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-rxtx                        | 1.0.1-2 | SolarNode RXTX support |
| sn-solarpkg                    | 1.1.1-1 | SolarNode package management support |
| sn-solarssh                    | 1.0.0-3 | SolarSSH support |
| sn-system                      | 1.4.0-2 | SolarNode system support |
| sn-wifi                        | 1.3.0-2 | WiFi management service |
| solarnode-app-core             | [2.7.0-2][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2            | 1.1.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt          | 2.1.0-2 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty    | 2.1.1-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                 | [1.13.0-3][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2              | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson         | 1.0.0-1 | SolarNode platform Jackson JSON support |
| solarnode-base-netty           | 1.0.0-1 | SolarNode platform Netty support |
| solarnode-base-spring          | 1.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security | 1.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                     | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


# Debian 10

These are SolarNodeOS images based on the Debian 10 "buster" release.

## 2022-04-20

Based on the upstream RaspiOS (formerly Raspbian) `2021-05-07-raspios-buster-armhf-lite` image,
and is based on Debian 10.12 and the 5.10.103 Linux kernel. This image requires a 2GB or larger SD
card.

Includes the following core SolarNode packages:

| Package                        | Version | Description |
|:-------------------------------|:--------|:------------|
| mbpoll                         | 1.4.11  | Command line utility to communicate with Modbus devices | 
| sn-nftables                    | 1.1.0-3 | nftables firewall management service |
| sn-osstat                      | 1.1.0-1 | SolarNode OS statistics support |
| sn-pi                          | 1.1.2-1 | Raspberry Pi SolarNode support |
| sn-rxtx                        | 1.0.1-2 | SolarNode RXTX support |
| sn-solarpkg                    | 1.1.1-1 | SolarNode package management support |
| sn-solarssh                    | 1.0.0-3 | SolarSSH support |
| sn-system                      | 1.4.0-2 | SolarNode system support |
| sn-wifi                        | 1.3.0-2 | WiFi management service |
| solarnode-app-core             | [2.7.0-2][solarnode-app-core-log] | SolarNode application core |
| solarnode-app-db-h2            | 1.1.0-1 | SolarNode DB - H2 |
| solarnode-app-io-mqtt          | 2.1.0-2 | SolarNode MQTT I/O - API |
| solarnode-app-io-mqtt-netty    | 2.1.1-1 | SolarNode MQTT I/O - Netty |
| solarnode-base                 | [1.13.0-3][solarnode-base-log] | SolarNode platform |
| solarnode-base-h2              | 1.0.0-1 | SolarNode platform H2 database support |
| solarnode-base-jackson         | 1.0.0-1 | SolarNode platform Jackson JSON support |
| solarnode-base-netty           | 1.0.0-1 | SolarNode platform Netty support |
| solarnode-base-spring          | 1.0.0-1 | SolarNode platform Spring support |
| solarnode-base-spring-security | 1.0.0-1 | SolarNode platform Spring Security support |
| yasdishell                     | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi |


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


# Debian 9

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


[raspios]: https://www.raspberrypi.com/software/operating-systems/
[solarnode-app-core-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-app-core/debian/CHANGELOG.md
[solarnode-base-log]: https://github.com/SolarNetwork/solarnode-os-packages/blob/master/solarnode-base/debian/CHANGELOG.md
