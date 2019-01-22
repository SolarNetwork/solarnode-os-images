#!/usr/bin/env sh

DRYRUN=0
VERBOSE=0
KEEP_SSH=0

while getopts ":knv" opt; do
	case $opt in
		k) KEEP_SSH=1 ;; 
		n) DRYRUN=1 ;;
		v) VERBOSE=1 ;;
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
	find "$MOUNT/var/log" -type f \( -name '*.gz' -o -name '*.1' \) -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/var/log" -type f \( -name '*.gz' -o -name '*.1' \) -delete
fi

if [ $VERBOSE = 1 ]; then
	echo "Finding archive logs to truncate..."
	find "$MOUNT/var/log" -type f -size +0c -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/var/log" -type f -size +0c -exec sh -c '> {}' \;
fi

if [ $VERBOSE = 1 ]; then
	echo "Finding apt cache files to delete..."
	find "$MOUNT/var/cache/apt" -type f -name '*.bin' -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/var/cache/apt" -type f -name '*.bin' -delete
fi

if [ -e "$MOUNT/var/tmp" ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Deleting temporary files from /var/tmp..."
		find "$MOUNT/var/tmp" -type f -print
	fi
	if [ ! $DRYRUN = 1 ]; then
		find "$MOUNT/var/tmp" -type f -delete
	fi
fi

if [ $VERBOSE = 1 ]; then
	echo "Finding  localized man files to delete..."
	find "$MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) -print
fi
if [ ! $DRYRUN = 1 ]; then
	find "$MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) \
		-exec rm -rf {} \;
fi

if [ $KEEP_SSH = 1 ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Preserving SSH host keys."
	fi
else
	if [ $VERBOSE = 1 ]; then
		echo "Deleting SSH host keys..."
		find "$MOUNT/etc/ssh" -type f -name 'ssh_host_*' -print
	fi
	if [ ! $DRYRUN = 1 ]; then
		find "$MOUNT/etc/ssh" -type f -name 'ssh_host_*' -delete
	fi
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

if [ -e "$MOUNT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Deleting WiFi configuration..."
	fi
	if [ ! $DRYRUN = 1 ]; then
		rm -rf "$MOUNT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
	fi
fi

if [ -n "$(find $MOUNT/var/local -maxdepth 1 -name 'solarnode-expandfs.saved*' -print -quit)" ]; then
	if [ $VERBOSE = 1 ]; then
		echo "Deleting expandfs save files..."
	fi
	if [ ! $DRYRUN = 1 ]; then
		find $MOUNT/var/local -maxdepth 1 -name 'solarnode-expandfs.saved*' -print -delete
	fi
fi

umount "$MOUNT"
losetup -d $LOOPDEV

if [ $VERBOSE = 1 ]; then
	echo "Optimizing image $IMGNAME..."
fi
if [ ! $DRYRUN = 1 ]; then
	virt-sparsify --format raw "$IMGNAME" "$IMGNAME.vs" && mv -f "$IMGNAME.vs" "$IMGNAME"
fi

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
