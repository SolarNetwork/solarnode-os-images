#!/usr/bin/env sh

# Prepare a disk to minimize the partition sizes to fit on small media like SD cards.
#
# The default values are designed to make a 1GB Raspbian Debian 9 "stretch" image:
#
#   prep-disk-sh -d /dev/sde
#
# To make a 1GB Raspbian Debian 10 "buster" image, we have to shrink the /boot
# partition which comes as 256M and then shrink/shift the / partition. The following
# shrinks the /boot partition to 128M and / to 822M via an intermediate 840M:
#
#   prep-disk.sh -d /dev/sde -f 128M -g '-132M' -S 840M -s 822M -b 244224
#
# Some more examples, for ever smaller /boot partitions:
# 
#   prep-disk.sh -d /dev/sde -f 96M -g '-164M' -s 854M -b 244224
#   prep-disk.sh -d /dev/sde -f 64M -g '-196M' -s 886M -b 244224
#
# A loopback device can be used if you specify the -P argument like '-P p'
# so the partition names correctly resolve like "p0" and "p1".

DRYRUN=
VERBOSE=0
DISK="/dev/sde"
OUTFILE=""
OUTBLKS="243712"
PART="2"
SIZE="925696K"
SIZE0=""
FAT_PART="1"
FAT_SIZE=""
FAT_MOUNT=
PART_SHIFT=""
PART_PREFIX=""


while getopts ":b:d:F:f:g:kno:P:p:s:v" opt; do
	case $opt in
		b) OUTBLKS="$OPTARG" ;;
		d) DISK="$OPTARG" ;;
		F) FAT_PART="$OPTARG" ;;
		f) FAT_SIZE="$OPTARG" ;;
		g) PART_SHIFT="$OPTARG" ;;
		n) DRYRUN=1 ;;
		o) OUTFILE="$OPTARG" ;;
		P) PART_PREFIX="$OPTARG" ;;
		p) PART="$OPTARG" ;;
		S) SIZE0="$OPTARG" ;;
		s) SIZE="$OPTARG" ;;
		v) VERBOSE=1 ;;
	esac
done

shift $(($OPTIND - 1))

if [ ! -e "$DISK" ]; then
	echo "Disk $DISK not available."
	exit 1
fi

partDev=$DISK$PART_PREFIX$PART
fatPartDev=$DISK$PART_PREFIX$FAT_PART

if [ ! -e "$partDev" ]; then
	echo "Partition $partDev not available."
	exit 1
fi

if [ -n "$FAT_SIZE" ];then
	if [ ! -e "$fatPartDev" ]; then
		echo "FAT partition $fatPartDev not available."
		exit 1
	fi
	tmp_dir=$(mktemp -d -t fat-XXXXX)
	echo "Mounting $fatPartDev -> $tmp_dir"
	if [ -z $DRYRUN ]; then
		sudo mount $fatPartDev $tmp_dir || exit 1
	fi

	tmp_data=$(mktemp -t fat-data-XXXXX.tgz)
	echo "Saving $fatPartDev data -> $tmp_data"
	if [ -z $DRYRUN ]; then
		sudo tar czf $tmp_data -C $tmp_dir . || exit 1
	fi
	
	echo "Resizing $fatPartDev partition to $FAT_SIZE..."
	if [ -z $DRYRUN ]; then
		sudo umount $tmp_dir || exit 1
		echo "- $FAT_SIZE" |sudo sfdisk $DISK -N$FAT_PART --no-reread --no-tell-kernel --force
		sudo partx -u $DISK
	fi

	echo "Restoring $fatPartDev data <- $tmp_data"
	if [ -z $DRYRUN ]; then
		sudo mkfs.fat -F 32 -n boot $fatPartDev || exit 1
		sudo mount $fatPartDev $tmp_dir || exit 1
		sudo tar xf $tmp_data -C $tmp_dir || exit 1
		sudo umount $tmp_dir
	fi
fi

if [ -n "$SIZE0" ]; then
	echo "Resizing filesystem on $partDev to $SIZE0..."
	if [ -z "$DRYRUN" ]; then
		sudo resize2fs -fp "$partDev" "$SIZE0" || exit 1
		sudo sync
	fi
fi

echo "Resizing filesystem on $partDev to $SIZE..."
if [ -z "$DRYRUN" ]; then
	sudo resize2fs -fp "$partDev" "$SIZE" || exit 1
	sudo sync
fi

echo "Resizing $partDev partition to $SIZE..."
if [ -z $DRYRUN ]; then
	echo "- $SIZE" |sudo sfdisk $DISK -N$PART --no-reread --no-tell-kernel --force
	sudo partx -u $DISK
fi

if [ -n "$PART_SHIFT" ];then
	echo "Shifting $partDev partition $PART_SHIFT..."
	if [ -z $DRYRUN ]; then
		echo "$PART_SHIFT," |sudo sfdisk --move-data $DISK -N$PART --no-reread --no-tell-kernel --force
		sudo partx -u $DISK
	fi
fi

if [ -n "$OUTFILE" ]; then
	echo "Copying $OUTBLKS 4k blocks of $DISK to $OUTFILE..."
	if [ -z "$DRYRUN" ]; then
		sudo dcfldd if=$DISK conv=sync,noerror bs=4k statusinterval=256 count=$OUTBLKS \
			of=$OUTFILE
	fi
fi

