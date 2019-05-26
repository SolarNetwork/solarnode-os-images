#!/usr/bin/env sh

DRYRUN=
VERBOSE=0
DISK="/dev/sde"
OUTFILE=""
OUTBLKS="243712"
PART="2"
SIZE="925696K"

while getopts ":b:d:kno:p:s:v" opt; do
	case $opt in
		b) OUTBLKS="$OPTARG" ;;
		d) DISK="$OPTARG" ;;
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

if [ -n "$OUTFILE" ]; then
	echo "Copying $OUTBLKS 4k blocks of $DISK to $OUTFILE..."
	if [ -z "$DRYRUN" ]; then
		sudo dcfldd if=$DISK conv=sync,noerror bs=4k statusinterval=256 count=$OUTBLKS \
			of=$OUTFILE
	fi
fi

