# SolarNode Debian OS - Raspberry Pi

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

