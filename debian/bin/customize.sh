#!/usr/bin/env bash
#
# Customize an existing SolarNodeOS image using systemd-nspawn (from systemd-container
# package).
#
# For other architecture support (e.g. arm) make sure binfmt-support and qemu-user-static
# packages are installed, e.g.
#
#  apt install systemd-container qemu binfmt-support qemu-user-static

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
SRC_IMG=""
VERBOSE=""

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments> src script 
 -n            - dry run, do not make any changes
 -v            - increase verbosity of tasks

TODO
EOF
}

while getopts ":nv" opt; do
	case $opt in
		n) DRY_RUN="TRUE";;
		v) VERBOSE="TRUE";;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done

shift $(($OPTIND - 1))

SRC_IMG="$1"
if [ -z "$SRC_IMG" ]; then
	echo 'Must specify source image as argument.'
	exit 1
fi

LOOPDEV=""
SOLARNODE_PART=""
SRC_FSTYPE=""
SRC_MOUNT=$(mktemp -d -t sn-XXXXX)

setup_src_loopdev () {
	LOOPDEV=$(losetup -P -f --show $SRC_IMG)
	if [ -z "$LOOPDEV" ]; then
		echo "Error: loop device not discovered for image $SRC_IMG"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Created loop device $LOOPDEV for source image."
	fi
	
	# seems system needs a little rest before labels are available in lsblk?
	sleep 1

	SOLARNODE_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i SOLARNODE |cut -d' ' -f 1)
	if [ -z "$SOLARNODE_PART" ]; then
		echo "Error: SOLARNODE partition not discovered"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source SOLARNODE partition ${SOLARNODE_PART}."
	fi

	if ! mount "$SOLARNODE_PART" "$SRC_MOUNT"; then
		echo "Error: unable to mount $SOLARNODE_PART on $SRC_MOUNT"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Mounted source SOLARNODE filesystem on $SRC_MOUNT."
	fi

	SRC_FSTYPE=$(findmnt -f -n -o FSTYPE "$SOLARNODE_PART")
	if [ -z "$SRC_FSTYPE" ]; then
		echo "Error: SOLARNODE filesystem tpye not discovered."
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source SOLARNODE filesystem type $SRC_FSTYPE."
	fi
}

close_src_loopdev () {
	if [ -n "$VERBOSE" ]; then
		echo "Unmounting source SOLARNODE filesystem $SRC_MOUNT."
	fi
	umount "$SRC_MOUNT"
	if [ -n "$VERBOSE" ]; then
		echo "Closing source image loop device $LOOPDEV."
	fi
	losetup -d "$LOOPDEV"
	rmdir "$SRC_MOUNT"
}

setup_chroot () {
	if [ -L "$SRC_MOUNT/etc/resolv.conf" -o -e "$SRC_MOUNT/etc/resolv.conf" ]; then
		mv "$SRC_MOUNT/etc/resolv.conf" "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak"
	else
		echo wtf
		exit 1
	fi
	echo 'nameserver 1.1.1.1' >"$SRC_MOUNT/etc/resolv.conf"
}

close_chroot () {
	if [ -e "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Restoring original $SRC_MOUNT/etc/resolv.conf"
		fi
		rm -f "$SRC_MOUNT/etc/resolv.conf"
		mv "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" "$SRC_MOUNT/etc/resolv.conf"
	fi
}

execute_chroot () {
	systemd-nspawn -M solarnode-cust -D "$SRC_MOUNT" ping -c 1 www.yahoo.com
}

setup_src_loopdev
setup_chroot
execute_chroot
close_chroot
close_src_loopdev
