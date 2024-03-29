#!/usr/bin/env bash

BOARD="${BOARD:-nanopiair}"
BOOT_DEV_LABEL="${BOOT_DEV_LABEL:-SOLARBOOT}"
ROOT_DEV_LABEL="${ROOT_DEV_LABEL:-SOLARNODE}"

BUILD_HOME="armbian"
COMPRESS_DEST_IMAGE=""
COMPRESS_DEST_OPTS="-8 -T 0"
DEBIAN_VERSION="10"
IMAGE_SIZE="952"
SKIP_BUILD=""
SKIP_DATE_CHECK=""
SKIP_CUST_IMAGE=""

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Setup script for a minimal SolarNode OS based on Armbian.

Arguments:
 -B                     - skip Armbian build
 -D                     - skip image date check
 -I                     - skip custom image creation (use the customize.sh script later)
 -h <armbian build dir> - path to the Armbian build directory; defaults to armbian-build
 -M <debian version>    - defaults to 10; supported values are: 10, 11
 -s <mb>                - size of disk image, in MB; defaults to 952
 -Z <options>           - xz options to use on final image; defaults to '-8 -T 0'
 -z                     - compress final image with xz
EOF
}

while getopts ":BDIh:M:s:Z:z" opt; do
	case $opt in
		B) SKIP_BUILD='TRUE';;
		D) SKIP_DATE_CHECK='TRUE';;
		I) SKIP_CUST_IMAGE='TRUE';;
		h) BUILD_HOME="${OPTARG}";;
		M) DEBIAN_VERSION="${OPTARG}";;
		s) IMAGE_SIZE="${OPTARG}";;
		Z) COMPRESS_DEST_OPTS="${OPTARG}";;
		z) COMPRESS_DEST_IMAGE="TRUE";;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done
shift $(($OPTIND - 1))

if [ ! `id -u` = 0 ]; then
	echo "You must be root to run this script."
	exit 1
fi

if [ ! -e "${BUILD_HOME}/compile.sh" ]; then
	echo "Invalid build home '$BUILD_HOME', compile.sh not found."
	exit 1
fi

DEBIAN_NAME=""
OUTPUT_RELEASE=""

case "$DEBIAN_VERSION" in
	10)
		DEBIAN_NAME="buster"
		OUTPUT_RELEASE="deb10"
		;;
		
	11)
		DEBIAN_NAME="bullseye"
		OUTPUT_RELEASE="deb11"
		;;
		
	*)
			echo "Unknown Debian version ${OPTARG}"
			do_help
			exit 1
esac


setup_dev_btrfs () {
	local dev="$1"
	local label="$2"
	local curr=$(btrfs filesystem label "$dev")
	local fs_target=$(findmnt -f -n -o TARGET "$dev")
	if [ "$curr" = "$label" ]; then
		echo "Device $dev already has label $label."
	else
		echo -n "Setting device $dev label to $label... "
		btrfs filesystem label "$fs_target" "$label" && echo "OK" || echo "ERROR"
	fi
}

setup_dev_ext () {
	local dev="$1"
	local label="$2"
	local curr=$(e2label "$dev")
	if [ "$curr" = "$label" ]; then
		echo "Device $dev already has label $label."
	else
		echo -n "Setting device $dev label to $label... "
		e2label "$dev" "$label" && echo "OK" || echo "ERROR"
	fi
}

setup_boot_dev () {
	local dev="$1"
	local mnt="$2"
	local fs_type=$(findmnt -f -n -o FSTYPE "$dev")
	case $fs_type in
		ext*) setup_dev_ext "$dev" "$BOOT_DEV_LABEL";;
	esac
	if grep '^rootdev=UUID=' $mnt/armbianEnv.txt >/dev/null 2>&1; then
		echo -n "Changing rootdev from UUID to LABEL=SOLARNODE in $mnt/armbianEnv.txt... "
		sed -i 's/^rootdev=UUID=.*/rootdev=LABEL='"$ROOT_DEV_LABEL"'/' $mnt/armbianEnv.txt \
			&& echo "OK" || echo "ERROR"
	fi
}

setup_root_dev () {
	local dev="$1"
	local mnt="$2"
	local fs_type=$(findmnt -f -n -o FSTYPE "$dev")
	case $fs_type in
		btrfs) setup_dev_btrfs "$dev" "$ROOT_DEV_LABEL" ;;
		ext*)  setup_dev_ext   "$dev" "$ROOT_DEV_LABEL" ;;
	esac
	if grep '^UUID=[^ ]* /boot ' $mnt/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing /boot mount in $mnt/etc/fstab to use label $BOOT_DEV_LABEL... "
		sed -i 's/^UUID=[^ ]* \/boot /LABEL='"$BOOT_DEV_LABEL"' \/boot /' $mnt/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if grep '^UUID=[^ ]* / ' $mnt/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing / mount in $mnt/etc/fstab to use label $ROOT_DEV_LABEL... "
		sed -i 's/^UUID=[^ ]* \/ /LABEL='"$ROOT_DEV_LABEL"' \/ /' $mnt/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if grep 'compress=lzo' $mnt/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing compression in $mnt/etc/fstab from lzo to zstd... "
		sed -i 's/compress=lzo/compress=zstd/' $mnt/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if ! grep '^tmpfs /run ' $mnt/etc/fstab >/dev/null 2>&1; then
		echo -n "Adding /run mount in $mnt/etc/fstab with explicit size... "
		echo 'tmpfs /run tmpfs rw,nosuid,noexec,relatime,size=50%,mode=755 0 0' >>$mnt/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
}

finish_output () {
	local out_img="$1"
	out_path=$(dirname $(readlink -f "$out_img"))
	out_name=$(basename "${out_img%%.*}")
	# cd into out_path so checksums don't contain paths
	pushd "$out_path" >/dev/null
	echo "Checksumming image as ${out_path}/${out_name}.img.sha256..."
	sha256sum $(basename $out_img) >"${out_name}.img.sha256"
	
	if [ -n "$COMPRESS_DEST_IMAGE" ]; then
		echo "Compressing image as ${out_path}/${out_name}.img.xz..."
		xz -cv ${COMPRESS_DEST_OPTS} "${out_name}.img" >"${out_name}.img.xz"

		echo "Checksumming compressed image as ${out_name}.img.xz.sha256..."
		sha256sum "${out_name}.img.xz" >"${out_name}.img.xz.sha256"
	fi
	popd >/dev/null
}

DATE="$(date '+%Y%m%d')"
if [ -z "$SKIP_BUILD" ]; then
	DATE_MARKER=$(mktemp -t armbian-build-XXXXX)
	touch "$DATE_MARKER"
	pushd "${BUILD_HOME}" >/dev/null
	./compile.sh KERNEL_ONLY=no KERNEL_CONFIGURE=no \
		BUILD_MINIMAL=yes \
		INSTALL_HEADERS=no \
		COMPRESS_OUTPUTIMAGE=sha,img \
		FIXED_IMAGE_SIZE=$IMAGE_SIZE \
		ROOTFS_TYPE=btrfs BTRFS_COMPRESSION=zstd \
		WIREGUARD=no \
		AUFS=no \
		CLEAN_LEVEL=debs \
		BUILD_KSRC=no \
		EXTERNAL=no EXTERNAL_NEW=no \
		BRANCH=current \
		RELEASE=$DEBIAN_NAME \
		BOARD=$BOARD
	popd >/dev/null
fi

IMGNAME=$(ls -1t "${BUILD_HOME}"/output/images/Armbian_*.img |head -1)
if [ ! "$IMGNAME" ]; then
	echo "No image found in ${BUILD_HOME}/output/images."
	exit 1
fi
if [ -z "$SKIP_DATE_CHECK" -a ! "$IMGNAME" -nt "$DATE_MARKER" ]; then
	echo "No image found in ${BUILD_HOME}/output/images newer than build start."
	exit 1
fi
echo "OS image: $IMGNAME"

if [ -z "$SKIP_CUST_IMAGE" ]; then
	# have to copy image to internal disk (not Vagrant shared disk) for losetup to work
	TMPIMG=$(mktemp -t sn-XXXXX)
	cp -a "$IMGNAME" "$TMPIMG"

	LOOPDEV=`losetup --partscan --find --show $TMPIMG`
	if [ -z "$LOOPDEV" ]; then
		echo "Error: loop device not discovered for image $TMPIMG"
		exit 4
	else
		echo "Image loop device created as $LOOPDEV"
	fi

	LOOPPART_BOOT=$(ls -1 ${LOOPDEV}p* 2>/dev/null |head -1)
	if [ -z "$LOOPPART_BOOT" ]; then
		echo "Error: boot partition not discovered for device $LOOPDEV"
		exit 4
	else
		echo "Boot partition: $LOOPPART_BOOT"
	fi

	LOOPPART_ROOT=$(ls -1r ${LOOPDEV}p* 2>/dev/null |head -1)
	if [ -z "$LOOPPART_ROOT" ]; then
		echo "Error: root partition not discovered for device $LOOPDEV"
		exit 4
	else
		echo "Root partition: $LOOPPART_ROOT"
	fi

	MOUNT_BOOT=$(mktemp -d -t sn-XXXXX)
	MOUNT_ROOT=$(mktemp -d -t sn-XXXXX)
	mount "$LOOPPART_BOOT" "$MOUNT_BOOT"
	mount "$LOOPPART_ROOT" "$MOUNT_ROOT"
	echo "Mounted $LOOPPART_BOOT on $MOUNT_BOOT"
	echo "Mounted $LOOPPART_ROOT on $MOUNT_ROOT"

	setup_boot_dev "$LOOPPART_BOOT" "$MOUNT_BOOT"
	setup_root_dev "$LOOPPART_ROOT" "$MOUNT_ROOT"

	umount "$MOUNT_BOOT"
	umount "$MOUNT_ROOT"
	rmdir "$MOUNT_BOOT"
	rmdir "$MOUNT_ROOT"
	losetup -d $LOOPDEV

	OUTIMG="${BUILD_HOME}/output/images/solarnodeos-$OUTPUT_RELEASE-$BOARD-1GB-$DATE.img"
	mv "$TMPIMG" "$OUTIMG"
	echo "Image saved to $OUTIMG"
	finish_output "$OUTIMG"
fi