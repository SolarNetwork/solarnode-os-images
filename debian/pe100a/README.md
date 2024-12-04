# ASUS Debian image notes

# Customize command

```sh
# remove -i for fully automated
sudo bash /Users/matt/Documents/SolarNetwork/Developer/git/solarnode-os-images/debian/bin/customize.sh -v -z \
	-N 1 -n 3 -c -M /boot/firmware \
	-v -E 1560 -i \
	-a '-a pe100a -V asus -M 10 -q buster -G -m -w -Q -Z UTC -K conf/packages-deb10-add.txt -k conf/packages-deb10-keep.txt -A conf/packages-deb10-add-late.txt -x bin/asus-extra-late.sh' \
	-o /var/tmp/solarnodeos-deb10-pe100a-2GB-$(date '+%Y%m%d').img \
	/var/tmp/PE100A_debian_1.0.31_202404240616_UTC_release/pe100a-debian-raw.img \
	/Users/matt/Documents/SolarNetwork/Developer/git/solarnode-os-images/debian/bin/setup-sn.sh \
	/Users/matt/Documents/SolarNetwork/Developer/git/solarnode-os-images/debian/pe100a:/tmp/overlay
```

**NOTE** The setup argument `-o 172.16.159.167:3142` is omitted; apt cache not working for some unknown reason.

# Source image notes

## Login

Can `ssh` in as `asus` user, `asus` password. The `asus` user has `sudo` permissions.

## Image partitions

```
Disk /dev/loop0: 3.09 GiB, 3313500160 bytes, 6471680 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 0A01E94D-C7DC-4940-A264-EB442B2B5ADE

Device        Start     End Sectors Size Type
/dev/loop0p1  16384  147455  131072  64M Linux filesystem
/dev/loop0p2 147456  163839   16384   8M Linux filesystem
/dev/loop0p3 163840 6455295 6291456   3G Linux filesystem
```

```sh
# lsblk -o name,mountpoint,label,size,uuid /dev/loop0
NAME      MOUNTPOINT LABEL        SIZE UUID
loop0                             3.1G 
├─loop0p1            Boot pe100a   64M 523C-51CE
├─loop0p2                           8M 
└─loop0p3                           3G 09f77807-d422-49c9-9eac-1b5a70129d68
```

```sh
# mount -o ro /dev/loop0p1 /mnt/SOLARBOOT
# mount -o ro /dev/loop0p3 /mnt/SOLARNODE
# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p1     64M   25M   40M  39% /mnt/SOLARBOOT
/dev/loop0p3    2.9G  2.3G  373M  87% /mnt/SOLARNODE
```

### Extra software

### asus_failover

Some `asus_failover` software installed outside of packages:

```
root@pe100a:/etc/fo# systemctl status asus_failover
● asus_failover.service - ASUS Failover Service
   Loaded: loaded (/lib/systemd/system/asus_failover.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2021-01-18 18:40:37 UTC; 3 years 10 months ago
 Main PID: 3846 (asus_failover)
    Tasks: 12 (limit: 3574)
   Memory: 202.3M
   CGroup: /system.slice/asus_failover.service
           └─3846 /etc/fo/asus_failover
```

Can remove service link via `systemctl disable asus_failover` or:

```
rm /etc/systemd/system/multi-user.target.wants/asus_failover.service
```

### EdgeX

Manually remove all EdgeX configuration and support.

## Firewall

Kernel does not support sn-iptables or sn-nftables.

```
# nftables
Jan 20 13:10:32 solarnode nft[2338]: netlink.c:62: Unable to initialize Netlink socket: Protocol not supported

# iptables
Dec 03 22:48:14 solarnode iptables-restore[4760]: iptables-restore/1.8.2 Failed to initialize nft: Protocol not supported
```

## WiFi

The `rfkill` module is not provided in the kernel, so `sn-wifi` package not supported.
