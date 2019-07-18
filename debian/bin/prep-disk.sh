#!/usr/bin/env sh

DRYRUN=
VERBOSE=0
DISK="/dev/sde"
OUTFILE=""
OUTBLKS="243712"
PART="2"
SIZE="925696K"
FAT_PART="1"
FAT_SIZE=""
FAT_MOUNT=
PART_SHIFT=""


while getopts ":b:d:F:f:g:kno:p:s:v" opt; do
	case $opt in
		b) OUTBLKS="$OPTARG" ;;
		d) DISK="$OPTARG" ;;
		F) FAT_PART="$OPTARG" ;;
		f) FAT_SIZE="$OPTARG" ;;
		g) PART_SHIFT="$OPTARG" ;;
		n) DRYRUN=1 ;;
		o) OUTFILE="$OPTARG" ;;
		p) PART="$OPTARG" ;;
		s) SIZE="$OPTARG" ;;
		v) VERBOSE=1 ;;
	esac
done

shift $(($OPTIND - 1))

if [ ! -e "$DISK" ]; then
	echo "Disk $DISK not available."
	exit 1
fi

if [ ! -e "$DISK$PART" ]; then
	echo "Partition $DISK$PART not available."
	exit 1
fi

if [ -n "$FAT_SIZE" ];then
	if [ ! -e "$DISK$FAT_PART" ]; then
		echo "FAT partition $DISK$FAT_PART not available."
		exit 1
	fi
	tmp_dir=$(mktemp -d -t fat-XXXXX)
	echo "Mounting $DISK$FAT_PART -> $tmp_dir"
	if [ -z $DRYRUN ]; then
		sudo mount $DISK$FAT_PART $tmp_dir || exit 1
	fi

	tmp_data=$(mktemp -t fat-data-XXXXX.tgz)
	echo "Saving $DISK$FAT_PART data -> $tmp_data"
	if [ -z $DRYRUN ]; then
		sudo tar czf $tmp_data -C $tmp_dir . || exit 1
	fi
	
	echo "Resizing $DISK$FAT_PART partition to $FAT_SIZE..."
	if [ -z $DRYRUN ]; then
		sudo umount $tmp_dir || exit 1
		echo "- $FAT_SIZE" |sudo sfdisk $DISK -N$FAT_PART --no-reread --no-tell-kernel --force
		sudo partx -u $DISK
	fi

	echo "Restoring $DISK$FAT_PART data <- $tmp_data"
	if [ -z $DRYRUN ]; then
		sudo mkfs.fat -F 32 -n boot $DISK$FAT_PART || exit 1
		sudo mount $DISK$FAT_PART $tmp_dir || exit 1
		sudo tar xf $tmp_data -C $tmp_dir || exit 1
		sudo umount $tmp_dir
	fi
fi

echo "Resizing filesystem on $DISK$PART to $SIZE..."
if [ -z "$DRYRUN" ]; then
	sudo resize2fs -fp "$DISK$PART" "$SIZE"
	sudo sync
fi

echo "Resizing $DISK$PART partition to $SIZE..."
if [ -z $DRYRUN ]; then
	echo "- $SIZE" |sudo sfdisk $DISK -N$PART --no-reread --no-tell-kernel --force
	sudo partx -u $DISK
fi

if [ -n "$PART_SHIFT" ];then
	echo "Shifting $DISK$PART partition $PART_SHIFT..."
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

