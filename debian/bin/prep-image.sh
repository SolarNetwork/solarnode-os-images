#!/usr/bin/env sh

DRYRUN=0
VERBOSE=0

while getopts ":nv" opt; do
	case $opt in
		n)
			DRYRUN=1
			;;

		v)
			VERBOSE=1
			;;
	esac
done

shift $(($OPTIND - 1))

IMGNAME=$1

if [ -z "$IMGNAME" ]; then
	echo "Provide name of image file as argument."
	exit 1
fi

if [ ! -e "$IMGNAME" ]; then
	echo "Image file $IMGNAME not found."
	exit 2
fi

if [ ! `id -u` = 0 ]; then
	echo "You must be root to run this script."
	exit 3
fi

LOOPDEV=`losetup -P -f --show $IMGNAME`
if [ -z "$LOOPDEV" ]; then
	echo "Error: loop device not discovered for image $IMGNAME"
	exit 4
fi

LOOPPART=`ls -1r ${LOOPDEV}p* |head -1`
if [ -z "$LOOPPART" ]; then
	echo "Error: loop partition not discovered for device $LOOPDEV"
	exit 4
elif [ $VERBOSE = 1 ]; then
	echo "Loop device: $LOOPPART"
fi

MOUNT=/mnt/SOLARNODE
mount "$LOOPPART" "$MOUNT"
if [ $VERBOSE = 1 ]; then
	echo "Mounted $LOOPPART on $MOUNT"
fi

if [ $VERBOSE = 1 ]; then
	echo "Finding archive logs to delete..."
	find "$MOUNT/var/log" -type f -name '*.gz' -o -name '*.1' -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/var/log" -type f -name '*.gz' -o -name '*.1' -delete
fi

if [ $VERBOSE = 1 ]; then
	echo "Finding archive logs to truncate..."
	find "$MOUNT/var/log" -type f -size +0c -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/var/log" -type f -size +0c -exec sh -c '> {}' \;
fi

if [ $VERBOSE = 1 ]; then
	echo "Deleting SSH host keys..."
	find "$MOUNT/etc/ssh" -type f -name 'ssh_host_*' -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/etc/ssh" -type f -name 'ssh_host_*' -delete
fi

if [ -e "$MOUNT/home/solar/var" ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Deleting SolarNode var dir..."
	fi
	if [ ! $DRYRUN = 1 ]; then
		rm -rf "$MOUNT/home/solar/var"
	fi
fi

if [ -e "$MOUNT/home/solar/work" ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Deleting SolarNode work dir..."
	fi
	if [ ! $DRYRUN = 1 ]; then
		rm -rf "$MOUNT/home/solar/work"
	fi
fi

if [ $VERBOSE = 1 ]; then
	echo "Filling empty space with zeros..."
	echo "sfill -f -l -l -z $MOUNT"
fi
if [ ! $DRYRUN = 1 ]; then
	sfill -f -l -l -z "$MOUNT"
fi

umount "$MOUNT"
losetup -d $LOOPDEV

if [ $VERBOSE = 1 ]; then
	echo "Checksumming image as $IMGNAME.sha256..."
fi
if [ ! $DRYRUN = 1 ]; then
	sha256sum "$IMGNAME" >"$IMGNAME.sha256"
fi

if [ $VERBOSE = 1 ]; then
	echo "Compressing image as $IMGNAME.xz..."
fi
if [ ! $DRYRUN = 1 ]; then
	xz -cv -9 "$IMGNAME" >"$IMGNAME.xz"
fi

if [ $VERBOSE = 1 ]; then
	echo "Checksumming compressed image as $IMGNAME.xz.sha256..."
fi
if [ ! $DRYRUN = 1 ]; then
	sha256sum "$IMGNAME.xz" >"$IMGNAME.xz.sha256"
fi

if [ $VERBOSE ]; then
	echo "Done."
fi
