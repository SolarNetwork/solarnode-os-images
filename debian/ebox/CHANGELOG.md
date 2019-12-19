# SolarNode Debian OS - eBox

## 20190-12-18

 * Update to latest Jessie 8.11
 * Convert to SolarNode OS style.

Includes the following core SolarNode OS packages:

| Package            | Version | Description |
|:-------------------|:--------|:------------|
| libmodbus          | 3.1.4-1 | Shared library used by `mbpoll`. |
| mbpoll             | 1.4.11  | Command line utility to communicate with ModBus devices. | 
| sn-iptables        | 1.0.0-2 | Firewall configuration. |
| sn-osstat          | 1.0.0-1 | Support for OS statistic collection. |
| sn-pi              | 1.0.0-1 | Raspberry Pi specific system configuration. |
| sn-rxtx            | 1.0.0-1 | Support for librxtx in SolarNode. |
| sn-solarpkg        | 1.0.2-1 | SolarNode package management support. |
| sn-solarssh        | 1.0.0-1 | SolarSSH support. |
| sn-system          | 1.0.0-1 | Core OS support for SolarNode. |
| sn-wifi            | 1.0.0-3 | Core OS support for SolarNode. |
| yasdishell         | 1.8.1-Build9 | Interactive shell for SMA inverters using libyasdi. |
| solarnode-base     | 1.5.1-1 | SolarNode application base framework. |
| solarnode-app-core | 1.4.0-1 | SolarNode application core. |


## 2017-12-11

 * Update to latest Jessie 8.10
 * Update to SolarNode base framework 20171121


## 2017-11-07

 * Update to latest Debian packages
 * Update to SolarNode base framework 20171105
 * Add auto-expand root file system support


## 2017-10-05

 * Add S3 backup support
 * Update to SolarNode base framework 20101005
 * Remove unnecessary OS packages


## 2017-07-25

 * Update to latest Jessie 8.9
 * Update to SolarNode base framework 20170725


## 2017-06-29

 * Update to latest Debian packages
 * Update to SolarNode platform 20170628
 * Configure SolarSSH support with systemd


## 2017-05-09

 * Update to Jessie 8.8.
 * Update to SolarNode bundle release 20170509
 * Add configuration to limit journald log to 10M
 * Add configuration systemd to not generate core dumps

