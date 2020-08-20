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

declare -A FS_OPTS
FS_OPTS[btrfs]="-m dup"
FS_OPTS[ext4]="-q -m 2 -O ^64bit,^metadata_csum"
FS_OPTS[fat]="-n SOLARBOOT"
declare -A MNT_OPTS
MNT_OPTS[btrfs]="defaults,noatime,nodiratime,commit=600,compress-force=zstd"
MNT_OPTS[ext4]="defaults,commit=600"
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

IMG="$1"
if [ -z "$IMG" ]; then
	echo 'Must specify source image as argument.'
	exit 1
fi
if [ ! -e "$IMG" ]; then
	echo "Error: source image '$IMG' not available."
	exit 1
fi

SCRIPT="$2"
if [ -z "$SCRIPT" ]; then
	echo 'Must specify script as argument.'
	exit 1
fi
if [ ! -e "$SCRIPT" ]; then
	echo "Error: script '$SCRIPT' not available."
	exit 1
fi
shift 2

FSTYPE_SOLARNODE=""
FSTYPE_SOLARBOOT=""
LOOPDEV=""
SOLARBOOT_PART=""
SOLARNODE_PART=""
SRC_IMG=$(mktemp -t img-XXXXX)
SRC_MOUNT=$(mktemp -d -t sn-XXXXX)
SCRIPT_DIR=""

copy_src_img () {
	if [ -n "$VERBOSE" ]; then
		echo "Creating source image copy $SRC_IMG"
	fi
	if [ "${SRC_IMG##*.}" = "xz" ]; then
		if ! xzcat ${VERBOSE//TRUE/-v} "$IMG" >"$SRC_IMG"; then
			echo "Error extracting $IMG to $SRC_IMG"
			exit 1
		fi
	elif ! cp ${VERBOSE//TRUE/-v} "$IMG" "$SRC_IMG"; then
		echo "Error: unable to copy $IMG to $SRC_IMG"
		exit 1
	fi
}

clean_src_img () {
	rm -f "$SRC_IMG"
	if [ -n "$VERBOSE" ]; then
		echo "Deleted $SRC_IMG"
	fi
}

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

	SOLARBOOT_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i SOLARBOOT |cut -d' ' -f 1)
	if [ -z "$SOLARBOOT_PART" ]; then
		echo "Error: SOLARBOOT partition not discovered"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source SOLARBOOT partition ${SOLARBOOT_PART}."
	fi

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

	FSTYPE_SOLARNODE=$(findmnt -f -n -o FSTYPE "$SOLARNODE_PART")
	if [ -z "$FSTYPE_SOLARNODE" ]; then
		echo "Error: SOLARNODE filesystem type not discovered."
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source SOLARNODE filesystem type $FSTYPE_SOLARNODE."
	fi

	if ! mount "$SOLARBOOT_PART" "$SRC_MOUNT/boot"; then
		echo "Error: unable to mount $SOLARBOOT_PART on $SRC_MOUNT/boot."
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Mounted source SOLARBOOT filesystem on $SRC_MOUNT/boot."
	fi

	FSTYPE_SOLARBOOT=$(findmnt -f -n -o FSTYPE "$SOLARBOOT_PART")
	if [ -z "$FSTYPE_SOLARBOOT" ]; then
		echo "Error: SOLARBOOT filesystem type not discovered."
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source SOLARBOOT filesystem type $FSTYPE_SOLARBOOT."
	fi
}

close_src_loopdev () {
	if [ -n "$VERBOSE" ]; then
		echo "Unmounting source SOLARBOOT filesystem $SRC_MOUNT/boot."
	fi
	umount "$SRC_MOUNT/boot"
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
	SCRIPT_DIR=$(mktemp -d -t sn-XXXXX -p "$SRC_MOUNT/var/tmp")
	if [ -n "$VERBOSE" ]; then
		echo "Created script directory $SCRIPT_DIR."
	fi
	if ! cp -a ${VERBOSE//TRUE/-v} "$SCRIPT" "$SCRIPT_DIR/customize"; then
		echo "Error: unable to copy $SCRIPT to $SCRIPT_DIR"
		exit 1
	fi
	chmod ugo+x "$SCRIPT_DIR/customize"
}

clean_chroot () {
	if [ -e "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Restoring original $SRC_MOUNT/etc/resolv.conf"
		fi
		rm -f "$SRC_MOUNT/etc/resolv.conf"
		mv "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" "$SRC_MOUNT/etc/resolv.conf"
	fi
	if [ -d "$SCRIPT_DIR" ]; then
		rm -rf ${VERBOSE//TRUE/-v} "$SCRIPT_DIR"
	fi
}

execute_chroot () {
	systemd-nspawn -M solarnode-cust -D "$SRC_MOUNT" \
		--chdir=${SCRIPT_DIR##${SRC_MOUNT}} \
		./customize ${VERBOSE//TRUE/-v}
}

copy_part () {
	local part="$1"
	local fstype="$2"
	local src="$3"
	#local sector_start=$(sfdisk -ql "$LOOPDEV" -o Device,Start |tail +2 |grep 
	if [ -n "$VERBOSE" ]; then
		echo "Creating $part $fstype filesystem with options ${FS_OPTS[$fstype]}."
	fi
	if ! mkfs.$fstype ${FS_OPTS[$fstype]} "$part"; then
		echo "Error: failed to create $part $fstype filesystem."
		exit 1
	fi
	local tmp_mount=$(mktemp -d -t sn-XXXXX)
	if [ -n "$VERBOSE" ]; then
		echo "Mounting $part on $tmp_mount with options ${MNT_OPTS[$fstype]}."
	fi
	if ! mount -o ${MNT_OPTS[$fstype]} "$part" "$tmp_mount"; then
		echo "Error: failed to mount $part on $tmp_mount."
		exit 1
	fi
	rsync -aHWXhx ${VERBOSE//TRUE/--info=progress2,stats1} "$src"/ "$tmp_mount"/
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

copy_img () {
	local size=$(wc -c <"$SRC_IMG")
	local size_mb=$(echo "$size / 1024 / 1024" |bc)
	local out_img=$(mktemp -t img-XXXXX)
	if [ -n "$VEBOSE" ]; then
		echo "Creating ${size_mb}MB output image $out_img."
	fi
	if ! dd if=/dev/zero of="$out_img" bs=1M count=$size_mb; then
		echo "Error creating ${size_mb}MB output image $out_img."
		exit 1
	fi

	local out_loopdev=$(losetup -P -f --show $out_img)
	if [ -n "$VERBOSE" ]; then
		echo "Opened output image loop device $out_loopdev."
	fi
	if ! sfdisk -d "$LOOPDEV" |sfdisk "$out_loopdev"; then
		echo "Error copying partition table from $LOOPDEV to $outdev."
		exit 1
	fi

	copy_part "${out_loopdev}${SOLARBOOT_PART##$LOOPDEV}" "$FSTYPE_SOLARBOOT" "$SRC_MOUNT/boot"
	copy_part "${out_loopdev}${SOLARNODE_PART##$LOOPDEV}" "$FSTYPE_SOLARNODE" "$SRC_MOUNT"

	if [ -n "$VERBOSE" ]; then
		echo "Closing output image loop device $out_loopdev."
	fi
	losetup -d "$out_loopdev"

	echo "Customized image complete: $out_img"
}

copy_src_img
setup_src_loopdev
setup_chroot
execute_chroot
clean_chroot
copy_img
close_src_loopdev
clean_src_img
