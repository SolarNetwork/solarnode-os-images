#!/usr/bin/env bash
#
# Customize an existing OS image using systemd-nspawn (from systemd-container package).
#
# For other architecture support (e.g. arm) make sure binfmt-support and qemu-user-static
# packages are installed, e.g.
#
#  apt install systemd-container qemu binfmt-support qemu-user-static
#
# This script relies on tools available in the coreutils package.

declare -A FS_OPTS
FS_OPTS[btrfs]="-q -m dup"
FS_OPTS[ext4]="-q -m 2 -O ^64bit,^metadata_csum"
FS_OPTS[vfat]=""
declare -A MNT_OPTS
MNT_OPTS[btrfs]="defaults,noatime,nodiratime,commit=600,compress-force=zstd"
MNT_OPTS[ext4]="defaults,commit=600"
MNT_OPTS[vfat]="defaults"
declare -A DEST_MNT_OPTS
DEST_MNT_OPTS[btrfs]="defaults,noatime,nodiratime,compress=zstd"
DEST_MNT_OPTS[ext4]="defaults,noatim"
DEST_MNT_OPTS[vfat]="defaults"

SRC_BOOT_LABEL="SOLARBOOT"
SRC_ROOT_LABEL="SOLARNODE"
DEST_ROOT_FSTYPE=""
BOOT_DEV_LABEL="${BOOT_DEV_LABEL:-SOLARBOOT}"
ROOT_DEV_LABEL="${ROOT_DEV_LABEL:-SOLARNODE}"
COMPRESS_DEST_IMAGE=""
COMPRESS_DEST_OPTS="-8 -T 0"
EXPAND_SOLARNODE_FS=""
SHRINK_SOLARNODE_FS=""
DEST_PATH=""
SCRIPT_ARGS=""
SRC_IMG=""
VERBOSE=""

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments> src script [bind-mounts]

 -a <args>       - extra argumnets to pass to the script
 -E <size MB>    - shrink the SOLARNODE partition by this amount, in MB
 -e <size MB>    - expand the SOLARNODE partition by this amount, in MB
 -P <boot label> - the source image boot partition label; defaults to SOLARBOOT
 -p <root label> - the source image root partition label; defaults to SOLARNODE
 -o <out name>   - the output name for the final image
 -r <fstype>     - force a specific root filesystem type in the destination image
 -v              - increase verbosity of tasks
 -Z <options>    - xz options to use on final image; defaults to '-8 -T 0'
 -z              - compress final image with xz

The bind-mounts argument must adhere to the systemd-nspawn --bind-ro syntax,
that is something like 'src:mount'. Multiple mounts should be separarted by
commas. This mounts will then be available to the customization script.

Example that mounts /home/me as /var/tmp/me in the chroot:

  ./customize.sh solarnodeos-20200820.img my-cust.sh /home/me:/var/tmp/me

To expand the root filesystem by 500 MB:

  ./customize.sh -e 500 solarnodeos-20200820.img my-cust.sh

EOF
}

while getopts ":a:E:e:o:P:p:r:vZ:z" opt; do
	case $opt in
		a) SCRIPT_ARGS="${OPTARG}";;
		E) SHRINK_SOLARNODE_FS="${OPTARG}";;
		e) EXPAND_SOLARNODE_FS="${OPTARG}";;
		o) DEST_PATH="${OPTARG}";;
		P) SRC_BOOT_LABEL="${OPTARG}";;
		p) SRC_ROOT_LABEL="${OPTARG}";;
		r) DEST_ROOT_FSTYPE="${OPTARG}";;
		v) VERBOSE="TRUE";;
		Z) COMPRESS_DEST_OPTS="${OPTARG}";;
		z) COMPRESS_DEST_IMAGE="TRUE";;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done

shift $(($OPTIND - 1))

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

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

BIND_MOUNTS="$3"

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
	if [ -n "$EXPAND_SOLARNODE_FS" ]; then
		if ! truncate -s +${EXPAND_SOLARNODE_FS}M "$SRC_IMG"; then
			echo "Error: unable to expand $SRC_IMG by ${EXPAND_SOLARNODE_FS}MB."
		elif [ -n "$VERBOSE" ]; then
			echo "Expanded $SRC_IMG by ${EXPAND_SOLARNODE_FS}MB."
		fi
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

	SOLARBOOT_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i $SRC_BOOT_LABEL |cut -d' ' -f 1)
	if [ -z "$SOLARBOOT_PART" ]; then
		echo "Error: $SRC_BOOT_LABEL partition not discovered"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source $SRC_BOOT_LABEL partition ${SOLARBOOT_PART}."
	fi

	SOLARNODE_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i $SRC_ROOT_LABEL |cut -d' ' -f 1)
	if [ -z "$SOLARNODE_PART" ]; then
		echo "Error: $SRC_ROOT_LABEL partition not discovered"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source $SRC_ROOT_LABEL partition ${SOLARNODE_PART}."
	fi

	if [ -n "$EXPAND_SOLARNODE_FS" ]; then
		local part_num=$(sfdisk -ql "$LOOPDEV" -o Device |tail +2 |awk '{print NR,$0}' |grep "$SOLARNODE_PART" |cut -d' ' -f1)
		if [ -n "$VERBOSE" ]; then
			echo "Expanding partition $part_num on ${LOOPDEV} by $EXPAND_SOLARNODE_FS MB."
		fi
		echo ",+${EXPAND_SOLARNODE_FS}M" |sfdisk ${LOOPDEV} -N${part_num} --no-reread -q
		partx -u ${LOOPDEV}
	fi

	if ! mount "$SOLARNODE_PART" "$SRC_MOUNT"; then
		echo "Error: unable to mount $SOLARNODE_PART on $SRC_MOUNT"
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Mounted source $SRC_ROOT_LABEL filesystem on $SRC_MOUNT."
	fi

	FSTYPE_SOLARNODE=$(findmnt -f -n -o FSTYPE "$SOLARNODE_PART")
	if [ -z "$FSTYPE_SOLARNODE" ]; then
		echo "Error: $SRC_ROOT_LABEL filesystem type not discovered."
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source $SRC_ROOT_LABEL filesystem type $FSTYPE_SOLARNODE."
	fi

	if [ -n "$EXPAND_SOLARNODE_FS" ]; then
		case $FSTYPE_SOLARNODE in
			btrfs) btrfs filesystem resize max "$SRC_MOUNT";;
			ext4) resize2fs "$SOLARNODE_PART";;
			*) echo "Filesystem expansion for type $FSTYPE_SOLARNODE not supported.";;
		esac
	fi

	if ! mount "$SOLARBOOT_PART" "$SRC_MOUNT/boot"; then
		echo "Error: unable to mount $SOLARBOOT_PART on $SRC_MOUNT/boot."
		exit 1
	elif [ -n "$VERBOSE" ]; then
		echo "Mounted source $SRC_BOOT_LABEL filesystem on $SRC_MOUNT/boot."
	fi

	FSTYPE_SOLARBOOT=$(findmnt -f -n -o FSTYPE "$SOLARBOOT_PART")
	if [ -z "$FSTYPE_SOLARBOOT" ]; then
		echo "Error: $SRC_BOOT_LABEL filesystem type not discovered."
	elif [ -n "$VERBOSE" ]; then
		echo "Discovered source $SRC_BOOT_LABEL filesystem type $FSTYPE_SOLARBOOT."
	fi
}

close_src_loopdev () {
	if [ -n "$VERBOSE" ]; then
		echo "Unmounting source $SRC_BOOT_LABEL filesystem $SRC_MOUNT/boot."
	fi
	umount "$SRC_MOUNT/boot"
	if [ -n "$VERBOSE" ]; then
		echo "Unmounting source $SRC_ROOT_LABEL filesystem $SRC_MOUNT."
	fi
	umount "$SRC_MOUNT"
	if [ -n "$VERBOSE" ]; then
		echo "Closing source image loop device $LOOPDEV."
	fi
	losetup -d "$LOOPDEV"
	rmdir "$SRC_MOUNT"
}

disable_ld_preload () {
	if [ -e "$SRC_MOUNT/etc/ld.so.preload" ]; then
		echo -n "Disabling preload shared libs from $SRC_MOUNT/etc/ld.so.preload... "
		sed -i 's/^/#/' "$SRC_MOUNT/etc/ld.so.preload"
		echo 'OK'
	fi
}

enable_ld_preload () {
	if [ -e "$SRC_MOUNT/etc/ld.so.preload" ]; then
		echo -n "Enabling preload shared libs in $SRC_MOUNT/etc/ld.so.preload... "
		sed -i 's/^#//' "$SRC_MOUNT/etc/ld.so.preload"
		echo 'OK'
	fi
}

setup_mounts () {
	# be sure to work with both UUID= and PARTUUID= forms
	if grep 'UUID=[^ ]* */boot ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing /boot mount in $SRC_MOUNT/etc/fstab to use label $BOOT_DEV_LABEL... "
		sed -i 's/^.*UUID=[^ ]* *\/boot /LABEL='"$BOOT_DEV_LABEL"' \/boot /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if grep 'UUID=[^ ]* */ ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing / mount in $SRC_MOUNT/etc/fstab to use label $ROOT_DEV_LABEL... "
		sed -i 's/^.*UUID=[^ ]* *\/ /LABEL='"$ROOT_DEV_LABEL"' \/ /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if [ -n "$DEST_ROOT_FSTYPE" ]; then
		# make sure fstab has changed file system options
		echo -n "Changing / mount in $SRC_MOUNT/etc/fstab to $DEST_ROOT_FSTYPE... "
		sed -i 's/\/ *'"$FSTYPE_SOLARNODE"' *.*\([0-9] *[0-9]\)/\/ '"$DEST_ROOT_FSTYPE ${DEST_MNT_OPTS[$DEST_ROOT_FSTYPE]}"' \1/' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if grep 'compress=lzo' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing compression in $SRC_MOUNT/etc/fstab from lzo to zstd... "
		sed -i 's/compress=lzo/compress=zstd/' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	if ! grep '^tmpfs /run ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Adding /run mount in $SRC_MOUNT/etc/fstab with explicit size... "
		echo 'tmpfs /run tmpfs rw,nosuid,noexec,relatime,size=50%,mode=755 0 0' >>$SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
}

setup_chroot () {
	disable_ld_preload
	setup_mounts
	if [ -L "$SRC_MOUNT/etc/resolv.conf" -o -e "$SRC_MOUNT/etc/resolv.conf" ]; then
		mv "$SRC_MOUNT/etc/resolv.conf" "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak"
	else
		echo "Error: unable to rename $SRC_MOUNT/etc/resolv.conf." 
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
	if [ -L "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Restoring original $SRC_MOUNT/etc/resolv.conf"
		fi
		rm -f "$SRC_MOUNT/etc/resolv.conf"
		mv "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak" "$SRC_MOUNT/etc/resolv.conf"
	fi
	if [ -d "$SCRIPT_DIR" ]; then
		rm -rf ${VERBOSE//TRUE/-v} "$SCRIPT_DIR"
	fi
	enable_ld_preload
}

execute_chroot () {
	local binds="$1"
	if [ -n "$binds" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Binding container dir $binds"
		fi
		binds="--bind=$binds"
	fi
	systemd-nspawn -M solarnode-cust -D "$SRC_MOUNT" \
		--chdir=${SCRIPT_DIR##${SRC_MOUNT}} \
		${binds} \
		./customize \
			${VERBOSE//TRUE/-v} \
			${SCRIPT_ARGS}
}

copy_bootloader () {
	local dev="$1"
	# note: following assumes MBR, with first 440 bytes the boot loader
	local start_len="440"
	local bl_offset="1"
	local bl_len=$(echo "$(sfdisk -ql $dev -o Start |tail +2 |head -1) - $bl_offset" |bc)
	if ! dd status=none if=$SRC_IMG of=$dev bs=$start_len count=1; then
		echo "Error: problem copying MBR bootloader from $SRC_IMG to $dev."
	elif [ -n "$VERBOSE" ]; then
		echo "Copied $start_len bootloader bytes from $SRC_IMG to $dev."
	fi
	if ! dd status=none if=$SRC_IMG of=$dev bs=512 skip=$bl_offset seek=$bl_offset count=$bl_len; then
		echo "Error: problem copying bootloader from $SRC_IMG to $dev."
	elif [ -n "$VERBOSE" ]; then
		echo "Copied ${bl_len} sectors starting from $bl_offset for bootloader from $SRC_IMG to $dev."
	fi
}

LAST_PARTUUID=""

copy_part () {
	local part="$1"
	local fstype="$2"
	local label="$3"
	local src="$4"

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
	LAST_PARTUUID=$(blkid -o export "$part" |grep PARTUUID |cut -d= -f2)
	if [ -n "$VERBOSE" ]; then
		echo "$part PARTUUID = $LAST_PARTUUID"
		echo "Labling $part as $label"
	fi
	case $fstype in
		btrfs) btrfs filesystem label "$tmp_mount" "$label";;
		ext*)  e2label "$part" "$label";;
		vfat)  fatlabel "$part" "$label";;
	esac
	if [ -n "$VERBOSE" ]; then
		echo "Copying files from $src to $tmp_mount..."
	fi
	rsync -aHWXhx ${VERBOSE//TRUE/--info=progress2,stats1} "$src"/ "$tmp_mount"/
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

setup_boot_cmdline () {
	local part="$1"
	local fstype="$2"
	local rootpartuuid="$3"
	local tmp_mount=$(mktemp -d -t sn-XXXXX)
	if [ -n "$VERBOSE" ]; then
		echo "Mounting $part on $tmp_mount with options ${MNT_OPTS[$fstype]}."
	fi
	if ! mount -o ${MNT_OPTS[$fstype]} "$part" "$tmp_mount"; then
		echo "Error: failed to mount $part on $tmp_mount."
		exit 1
	fi
	if [ -e "$tmp_mount/cmdline.txt" ]; then
		if grep ' root=' "$tmp_mount/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Changing root to PARTUUID=$rootpartuuid in $tmp_mount/cmdline.txt... "
			sed -i 's/root=[^ ]*/root=PARTUUID='"$rootpartuuid"'/' $tmp_mount/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
		if [ -n "$DEST_ROOT_FSTYPE" ]; then
			if grep ' rootfstype=' "$tmp_mount/cmdline.txt" >/dev/null 2>&1; then
				echo -n "Changing rootfstype to $DEST_ROOT_FSTYPE in $tmp_mount/cmdline.txt... "
				sed -i 's/rootfstype=[^ ]*/rootfstype='"$DEST_ROOT_FSTYPE"'/' $tmp_mount/cmdline.txt \
					&& echo "OK" || echo "ERROR"
			fi
		fi
		if grep ' init=' "$tmp_mount/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Removing init from $tmp_mount/cmdline.txt... "
			sed -i 's/ init=[^ ]*//' $tmp_mount/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
		if ! grep ' fsck.repair=' "$tmp_mount/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Adding fsck.repair=yes to $tmp_mount/cmdline.txt... "
			echo ' fsck.repair=yes' >> $tmp_mount/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
	fi
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

copy_img () {
	local size=$(wc -c <"$SRC_IMG")
	local size_mb=$(echo "$size / 1024 / 1024" |bc)
	if [ -n "$SHRINK_SOLARNODE_FS" ]; then
		size_mb=$(echo "$size_mb - $SHRINK_SOLARNODE_FS" |bc)
		if [ -n "$VERBOSE" ]; then
			echo "Shrinking output image by $SHRINK_SOLARNODE_FS MB."
		fi
	fi
	local out_img=$(mktemp -t img-XXXXX)
	if [ -n "$VERBOSE" ]; then
		echo "Creating ${size_mb}MB output image $out_img."
	fi
	if ! dd if=/dev/zero of="$out_img" bs=1M count=$size_mb status=none; then
		echo "Error creating ${size_mb}MB output image $out_img."
		exit 1
	fi
	chmod 644 "$out_img"

	local out_loopdev=$(losetup -P -f --show $out_img)
	if [ -n "$VERBOSE" ]; then
		echo "Opened output image loop device $out_loopdev."
	fi
	if ! sfdisk -q -d "$LOOPDEV" |sfdisk -q "$out_loopdev"; then
		echo "Error copying partition table from $LOOPDEV to $outdev."
		exit 1
	fi

	copy_bootloader "$out_loopdev"
	copy_part "${out_loopdev}${SOLARBOOT_PART##$LOOPDEV}" "$FSTYPE_SOLARBOOT" "SOLARBOOT" "$SRC_MOUNT/boot"
	copy_part "${out_loopdev}${SOLARNODE_PART##$LOOPDEV}" "${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}" "SOLARNODE" "$SRC_MOUNT"

	setup_boot_cmdline "$out_loopdev${SOLARBOOT_PART##$LOOPDEV}" "$FSTYPE_SOLARBOOT" "$LAST_PARTUUID"

	if [ -n "$VERBOSE" ]; then
		echo "Closing output image loop device $out_loopdev."
	fi
	losetup -d "$out_loopdev"

	if [ -n "$VERBOSE" ]; then
	       echo "Customized image complete: $out_img"
	fi
	if [ -n "$DEST_PATH" ]; then
		mv "$out_img" "$DEST_PATH"
		out_img="$DEST_PATH"
	fi

	out_path=$(dirname $(readlink -f "$out_img"))
	out_name=$(basename "${out_img%%.*}")
	# cd into out_path so checksums don't contain paths
	pushd "$out_path"
	if [ -n "$VERBOSE" ]; then
		echo "Checksumming image as ${out_path}/${out_name}.img.sha256..."
	fi
	sha256sum $(basename $out_img) >"${out_name}.img.sha256"
	
	if [ -n "$COMPRESS_DEST_IMAGE" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Compressing image as ${out_path}/${out_name}.img.xz..."
		fi
		xz -cv ${COMPRESS_DEST_OPTS} "$out_img" >"${out_name}.img.xz"

		if [ -n "$VERBOSE" ]; then
			echo "Checksumming compressed image as ${out_name}.img.xz.sha256..."
		fi
		sha256sum "${out_name}.img.xz" >"${out_name}.img.xz.sha256"
	fi
	popd
}

copy_src_img
setup_src_loopdev
setup_chroot
execute_chroot "$BIND_MOUNTS"
clean_chroot
copy_img
close_src_loopdev
clean_src_img
if [ -n "$DEST_PATH" ]; then
	echo "Customized image saved to $DEST_PATH"
fi
