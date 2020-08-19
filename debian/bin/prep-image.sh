#!/usr/bin/env sh

# Tidy up a SolarNode OS image file in preparation for releasing the image
# to the general public. A tpyical invocation looks like:
#
#   prep-image.sh -v -j ../conf/image-info-template.json -s 20190719 \
#     solarnodeos-deb10-pi-1GB.img
#
# The output is a xz-compressed copy of the source image file, SHA-256
# digests of the source and output files, and a JSON metadata file
# suitable for using with SolarNode Image Maker.

DRYRUN=0
VERBOSE=0
KEEP_SSH=0
SKIP_OPTIMIZE=0
SOLAR_HOMES="/home/solar /var/lib/solarnode"
SOLAR_HOME_DIRS="/var /work"
JSON_TEMPLATE="../conf/image-info-template.json"
JSON_ID_SUFFIX="$(date '+%Y%m%d')"

while getopts ":j:knOs:v" opt; do
	case $opt in
		j) JSON_TEMPLATE="$OPTARG";;
		k) KEEP_SSH=1 ;; 
		n) DRYRUN=1 ;;
		O) SKIP_OPTIMIZE=1;;
		s) JSON_ID_SUFFIX="$OPTARG";;
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

setup_json () {
	local tmpl="$1"
	local name="$2"
	local outname="$3"
	local usha="$(cat "$outname.img.sha256" |cut -d' ' -f1)"
	local ulen="$(stat -L --printf="%s" "$name")"
	local sha="$(cat "$outname.img.xz.sha256" |cut -d' ' -f1)"
	local len="$(stat -L --printf="%s" "$outname.img.xz")"
	sed -e 's/"id":""/"id":"'"$outname"'"/' \
		-e 's/"sha256":""/"sha256":"'"$sha"'"/' \
		-e 's/"uncompressedSha256":""/"uncompressedSha256":"'"$usha"'"/' \
		-e 's/"contentLength":0/"contentLength":'"$len"'/' \
		-e 's/"uncompressedContentLength":0/"uncompressedContentLength":'"$ulen"'/' \
		"$tmpl" > "${outname}.json"
	echo "Saved JSON info to ${outname}.json"
}

optimize_image () {
	if [ ! `id -u` = 0 ]; then
		echo "You must be root to run this script without -O."
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

	MOUNT=$(mktemp -d -t sn-XXXXX)
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

	if [ $VERBOSE = 1 ]; then
		echo "Finding debconf cache files to delete..."
		find "$MOUNT/var/cache/debconf" -type f -name '*-old' -print
	fi
	if [ ! $DRYRUN = 1 ]; then
		find "$MOUNT/var/cache/debconf" -type f -name '*-old' -delete
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
		echo "Deleting misclaneous files..."
		find "$MOUNT" -type f -name .DS_Store -o -name '*.swp' -print
	fi
	if [ ! $DRYRUN = 1 ]; then
		find "$MOUNT" -type f -name .DS_Store -o -name '*.swp' -delete
	fi

	if [ $VERBOSE = 1 ]; then
		echo "Finding  localized man files to delete..."
		find "$MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) -print
	fi
	if [ ! $DRYRUN = 1 ]; then
		find "$MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) \
			-exec rm -rf {} \;
	fi

	if [ $VERBOSE = 1 -a -s "$MOUNT/etc/machine-id" ]; then
		echo "Truncating /etc/machine-id"
	fi
	if [ $DRYRUN != 1 -a -s "$MOUNT/etc/machine-id" ]; then
		sh -c ">$MOUNT/etc/machine-id"
	fi

	if [ $VERBOSE = 1 -a -e "$MOUNT/var/lib/dbus/machine-id" ]; then
		echo "Deleting /var/lib/dbus/machine-id"
	fi
	if [ $DRYRUN != 1 -a -e "$MOUNT/var/lib/dbus/machine-id" ]; then
		rm -f "$MOUNT/var/lib/dbus/machine-id"
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

	for h in $SOLAR_HOMES; do
		for d in $SOLAR_HOME_DIRS; do
			if [ -d "$MOUNT$h$d" ]; then
				if [ $VERBOSE = 1 ]; then
					echo "Deleting SolarNode home $d dir..."
				fi
				if [ ! $DRYRUN = 1 ]; then
					rm -rf "$MOUNT$h$d"/*
				fi
			fi
		done
	done

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
	rmdir "$MOUNT"
	losetup -d $LOOPDEV

	if [ $VERBOSE = 1 ]; then
		echo "Optimizing image $IMGNAME..."
	fi
	if [ ! $DRYRUN = 1 ]; then
		virt-sparsify --format raw "$IMGNAME" "$IMGNAME.vs" && mv -f "$IMGNAME.vs" "$IMGNAME"
	fi
}

if [ $SKIP_OPTIMIZE = 0 ]; then
	optimize_image
fi

OUTNAME=${IMGNAME%%.*}
if [ -e "$JSON_TEMPLATE" ]; then
	OUTNAME="${OUTNAME}-${JSON_ID_SUFFIX}"
fi

if [ $VERBOSE = 1 ]; then
	echo "Checksumming image as $OUTNAME.img.sha256..."
fi
if [ ! $DRYRUN = 1 ]; then
	sha256sum "$IMGNAME" >"$OUTNAME.img.sha256"
fi

if [ $VERBOSE = 1 ]; then
	echo "Compressing image as $OUTNAME.img.xz..."
fi
if [ ! $DRYRUN = 1 ]; then
	xz -cv -9 "$IMGNAME" >"$OUTNAME.img.xz"
fi

if [ $VERBOSE = 1 ]; then
	echo "Checksumming compressed image as $OUTNAME.img.xz.sha256..."
fi
if [ ! $DRYRUN = 1 ]; then
	sha256sum "$OUTNAME.img.xz" >"$OUTNAME.img.xz.sha256"
fi

if [ -e "$JSON_TEMPLATE" ]; then
	setup_json "$JSON_TEMPLATE" "$IMGNAME" "$OUTNAME"
fi

if [ $VERBOSE ]; then
	echo "Done."
fi
