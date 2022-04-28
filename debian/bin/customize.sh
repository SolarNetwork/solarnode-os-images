#!/usr/bin/env bash
#
# Customize an existing OS image using systemd-nspawn (from systemd-container package).
#
# For other architecture support (e.g. arm) make sure binfmt-support and qemu-user-static
# packages are installed, e.g.
#
#  apt install systemd-container qemu binfmt-support qemu-user-static
#
# This script relies on tools available in the bc, coreutils, and rsync packages, e.g.
#
#  apt install bc rsync

declare -A FS_OPTS
FS_OPTS[btrfs]="-q -m dup"
FS_OPTS[ext4]="-q -m 2 -O ^64bit,^metadata_csum"
FS_OPTS[vfat]=""
declare -A MNT_OPTS
MNT_OPTS[btrfs]="defaults,noatime,nodiratime,commit=60,compress-force=zstd"
MNT_OPTS[ext4]="defaults,commit=60"
MNT_OPTS[vfat]="defaults"
declare -A DEST_MNT_OPTS
DEST_MNT_OPTS[btrfs]="defaults,noatime,nodiratime,commit=60,compress=zstd"
DEST_MNT_OPTS[ext4]="defaults,noatime,commit=60"
DEST_MNT_OPTS[vfat]="defaults"

SRC_BOOT_LABEL="SOLARBOOT"
SRC_BOOT_PARTNUM=""
SRC_ROOT_LABEL="SOLARNODE"
SRC_ROOT_PARTNUM=""
DEST_ROOT_FSTYPE=""
BOOT_DEV_LABEL="${BOOT_DEV_LABEL:-SOLARBOOT}"
BOOT_DEV_MOUNT="${BOOT_DEV_MOUNT:-/boot}"
ROOT_DEV_LABEL="${ROOT_DEV_LABEL:-SOLARNODE}"

CLEAN_IMAGE=""
COMPRESS_DEST_IMAGE=""
COMPRESS_DEST_OPTS="-8 -T 0"
DEST_PATH=""
EXPAND_SOLARNODE_FS=""
INTERACTIVE_MODE=""
KEEP_SSH=""
NO_BOOT_PARTITION=""
SCRIPT_ARGS=""
SHRINK_SOLARNODE_FS=""
SRC_IMG=""
VERBOSE=""

ERR=""

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments> src script [bind-mounts]

 -a <args>        - extra argumnets to pass to the script
 -B               - disable separate boot partition (single root partition)
 -c               - clean out log files, temp files, SSH host keys from final
                    image
 -E <size MB>     - shrink the output SOLARNODE partition by this amount, in MB
 -e <size MB>     - expand the input SOLARNODE partition by this amount, in MB
 -i               - interactive mode; run without script
 -N <boot part #> - the source boot partition number, instead of using label
 -n <root part #> - the source root partition number, instead of using label
 -P <boot label>  - the source boot partition label; defaults to SOLARBOOT
 -p <root label>  - the source root partition label; defaults to SOLARNODE
 -M <boot mount>  - the boot partition mount directory; defaults to /boot
 -o <out name>    - the output name for the final image
 -r <fstype>      - use specific root filesystem type in the destination image
 -S               - if -c set, keep SSH host keys
 -v               - increase verbosity of tasks
 -Z <options>     - xz options to use on final image; defaults to '-8 -T 0'
 -z               - compress final image with xz

The 'src' image can be either a raw image or an xz-compressed one; the filename
must end in '.xz' to be treated as such.

The `bind-mounts` argument must adhere to the systemd-nspawn --bind-ro syntax,
that is something like 'src:mount'. Multiple mounts should be separarted by
commas. This mounts will then be available to the customization script.

Example that mounts /home/me as /var/tmp/me in the chroot:

  ./customize.sh solarnodeos-20200820.img my-cust.sh /home/me:/var/tmp/me

To expand the root filesystem by 500 MB:

  ./customize.sh -e 500 solarnodeos-20200820.img my-cust.sh

To interactively customize the image ('script' is not run, but copied into the
image as 'customize.sh'):

  ./customize.sh -i solarnodeos-20200820.img my-cust.sh

EOF
}

while getopts ":a:BcE:e:io:M:N:n:P:p:r:SvZ:z" opt; do
	case $opt in
		a) SCRIPT_ARGS="${OPTARG}";;
		B) NO_BOOT_PARTITION="TRUE";;
		c) CLEAN_IMAGE="TRUE";;
		E) SHRINK_SOLARNODE_FS="${OPTARG}";;
		e) EXPAND_SOLARNODE_FS="${OPTARG}";;
		i) INTERACTIVE_MODE="TRUE";;
		o) DEST_PATH="${OPTARG}";;
		M) BOOT_DEV_MOUNT="${OPTARG}";;
		N) SRC_BOOT_PARTNUM="${OPTARG}";;
		n) SRC_ROOT_PARTNUM="${OPTARG}";;
		P) SRC_BOOT_LABEL="${OPTARG}";;
		p) SRC_ROOT_LABEL="${OPTARG}";;
		r) DEST_ROOT_FSTYPE="${OPTARG}";;
		S) KEEP_SSH="TRUE";;
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

if ! command -v bc >/dev/null; then
	echo 'Error: bc is not available. Perhaps `apt install bc`?'
	exit 1
fi

if ! command -v sfdisk >/dev/null; then
	echo 'Error: sfdisk is not available. Perhaps `apt install util-linux`?'
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
	if [ "${IMG##*.}" = "xz" ]; then
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

	if [ -z "$NO_BOOT_PARTITION" ]; then
		if [ -n "$SRC_BOOT_PARTNUM" ]; then
			SOLARBOOT_PART=$(lsblk -npo kname $LOOPDEV |tail +$((1+$SRC_BOOT_PARTNUM)) |head -n 1)
		else
			SOLARBOOT_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i $SRC_BOOT_LABEL |cut -d' ' -f 1)
		fi
		if [ -z "$SOLARBOOT_PART" ]; then
			echo "Error: $SRC_BOOT_LABEL partition not discovered"
			exit 1
		elif [ -n "$VERBOSE" ]; then
			echo "Discovered source $SRC_BOOT_LABEL partition ${SOLARBOOT_PART}."
		fi
	fi
	
	if [ -n "$SRC_ROOT_PARTNUM" ]; then
		SOLARNODE_PART=$(lsblk -npo kname $LOOPDEV |tail +$((1+$SRC_ROOT_PARTNUM)) |head -n 1)
	else
		SOLARNODE_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i $SRC_ROOT_LABEL |cut -d' ' -f 1)
	fi
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

	if [ -z "$NO_BOOT_PARTITION" ]; then
		if [ ! -d "$SRC_MOUNT$BOOT_DEV_MOUNT" ]; then
			if ! mkdir -p "$SRC_MOUNT$BOOT_DEV_MOUNT"; then
				echo "Error: unable to create $SRC_MOUNT$BOOT_DEV_MOUNT directory to mount $SOLARBOOT_PART."
				exit 1
			fi
		fi
		if ! mount "$SOLARBOOT_PART" "$SRC_MOUNT$BOOT_DEV_MOUNT"; then
			echo "Error: unable to mount $SOLARBOOT_PART on $SRC_MOUNT$BOOT_DEV_MOUNT."
			exit 1
		elif [ -n "$VERBOSE" ]; then
			echo "Mounted source $SRC_BOOT_LABEL filesystem on $SRC_MOUNT$BOOT_DEV_MOUNT."
		fi

		FSTYPE_SOLARBOOT=$(findmnt -f -n -o FSTYPE "$SOLARBOOT_PART")
		if [ -z "$FSTYPE_SOLARBOOT" ]; then
			echo "Error: $SRC_BOOT_LABEL filesystem type not discovered."
		elif [ -n "$VERBOSE" ]; then
			echo "Discovered source $SRC_BOOT_LABEL filesystem type $FSTYPE_SOLARBOOT."
		fi
	fi
}

close_src_loopdev () {
	if [ -z "$NO_BOOT_PARTITION" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Unmounting source $SRC_BOOT_LABEL filesystem $SRC_MOUNT$BOOT_DEV_MOUNT."
		fi
		umount "$SRC_MOUNT$BOOT_DEV_MOUNT"
		if [ -n "$VERBOSE" ]; then
			echo "Unmounting source $SRC_ROOT_LABEL filesystem $SRC_MOUNT."
		fi
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
	# be sure to work with UUID= and PARTUUID= and LABEL= forms; also, work with /boot and /boot/firmware
	if [ -z "$NO_BOOT_PARTITION" ]; then
		if grep -q 'UUID=[^ ]* */boot' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
			echo -n "Changing /boot mount in $SRC_MOUNT/etc/fstab to use label $BOOT_DEV_LABEL... "
			sed -i 's/^.*UUID=[^ ]* *\/boot/LABEL='"$BOOT_DEV_LABEL"' \/boot/' $SRC_MOUNT/etc/fstab \
				&& echo "OK" || echo "ERROR"
		elif grep -q 'LABEL=[^ ]* */boot' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
			if ! grep -q 'LABEL='"$BOOT_DEV_LABEL" $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
				echo -n "Changing /boot mount in $SRC_MOUNT/etc/fstab to use label $BOOT_DEV_LABEL... "
				sed -i 's/^.*LABEL=[^ ]* *\/boot/LABEL='"$BOOT_DEV_LABEL"' \/boot/' $SRC_MOUNT/etc/fstab \
					&& echo "OK" || echo "ERROR"
			fi
		fi
	fi
	if grep -q 'UUID=[^ ]* */ ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Changing / mount in $SRC_MOUNT/etc/fstab to use label $ROOT_DEV_LABEL... "
		sed -i 's/^.*UUID=[^ 	]*[ 	]*\/ /LABEL='"$ROOT_DEV_LABEL"' \/ /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	elif grep -q 'LABEL=[^ ]* */ ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		if ! grep -q 'LABEL='"$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
			echo -n "Changing / mount in $SRC_MOUNT/etc/fstab to use label $ROOT_DEV_LABEL... "
			sed -i 's/^.*LABEL=[^ 	]*[ 	]*\/ /LABEL='"$ROOT_DEV_LABEL"' \/ /' $SRC_MOUNT/etc/fstab \
				&& echo "OK" || echo "ERROR"
		fi
	fi
	if ! grep -q '^tmpfs /run ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Adding /run mount in $SRC_MOUNT/etc/fstab with explicit size... "
		echo 'tmpfs /run tmpfs rw,nosuid,noexec,relatime,size=50%,mode=755 0 0' >>$SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	
	# make sure our root mount fstype matches final output fstype
	local fsopts=""
	local fstype="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"

	if [ "$fstype" != "${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}" ]; then
		echo -n "Changing / fstype in $SRC_MOUNT/etc/fstab from $fstype to ${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}... "
		sed -i 's/LABEL='"$ROOT_DEV_LABEL"'[ 	][ 	]*\/[ 	][ 	]*[^ 	][^ 	]*/LABEL='"$ROOT_DEV_LABEL"' \/ '"${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}"' /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	
	if [ -z "$NO_BOOT_PARTITION" ]; then
		# make sure boot mount options match desired + errors=remount-ro
		fsopts="$(grep "LABEL=$BOOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $4}')"
		fstype="$(grep "LABEL=$BOOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"
		if [ "$fsopts" != "${DEST_MNT_OPTS[$fstype]}" ]; then
			echo -n "Changing /boot fs options in $SRC_MOUNT/etc/fstab from [$fsopts] to [${DEST_MNT_OPTS[$fstype]}]... "
			sed -i 's/\(LABEL='"$BOOT_DEV_LABEL"'[ 	][ 	]*[^ 	]*[ 	][ 	]*[^ 	]*\)[ 	][ 	]*[^ 	]*[ 	]/\1 '"${DEST_MNT_OPTS[$fstype]}"',errors=remount-ro /' $SRC_MOUNT/etc/fstab \
				&& echo "OK" || echo "ERROR"
		fi
	fi
		
	# make sure root mount options match desired
	fsopts="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $4}')"
	fstype="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"
	if [ "$fsopts" != "${DEST_MNT_OPTS[$fstype]}" ]; then
		echo -n "Changing / fs options in $SRC_MOUNT/etc/fstab from [$fsopts] to [${DEST_MNT_OPTS[$fstype]}]... "
		sed -i 's/\(LABEL='"$ROOT_DEV_LABEL"'[ 	][ 	]*[^ 	]*[ 	][ 	]*[^ 	]*\)[ 	][ 	]*[^ 	]*[ 	]/\1 '"${DEST_MNT_OPTS[$fstype]}"' /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
}

setup_chroot () {
	disable_ld_preload
	setup_mounts
	if [ -L "$SRC_MOUNT/etc/resolv.conf" -o -e "$SRC_MOUNT/etc/resolv.conf" ]; then
		if ! mv "$SRC_MOUNT/etc/resolv.conf" "$SRC_MOUNT/etc/resolv.conf.sn-cust-bak"; then
			echo "Error: unable to rename $SRC_MOUNT/etc/resolv.conf." 
			exit 1
		fi
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

clean_chroot_fluff () {
	if [ -n "$VERBOSE" ]; then
		echo "Finding archive logs to delete..."
		find "$SRC_MOUNT/var/log" -type f \( -name '*.gz' -o -name '*.1' \) -print
	fi
	find "$SRC_MOUNT/var/log" -type f \( -name '*.gz' -o -name '*.1' \) -delete

	if [ -n "$VERBOSE" ]; then
		echo "Finding archive logs to truncate..."
		find "$SRC_MOUNT/var/log" -type f -size +0c -print
	fi
	find "$SRC_MOUNT/var/log" -type f -size +0c -exec sh -c '> {}' \;

	if [ -n "$VERBOSE" ]; then
		echo "Finding apt cache files to delete..."
		find "$SRC_MOUNT/var/cache/apt" -type f -name '*.bin' -print
	fi
	find "$SRC_MOUNT/var/cache/apt" -type f -name '*.bin' -delete

	if [ -e "$SRC_MOUNT/var/tmp" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Deleting temporary files from /var/tmp..."
			find "$SRC_MOUNT/var/tmp" -type f -print
		fi
		find "$SRC_MOUNT/var/tmp" -type f -delete
	fi

	if [ -n "$VERBOSE" ]; then
		echo "Finding  localized man files to delete..."
		find "$SRC_MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) -print
	fi
	find "$SRC_MOUNT/usr/share/man" -maxdepth 1 -type d \( -name '??' -o -name '??_*' -o -name '??.*' \) \
		-exec rm -rf {} \;

	if [ -s "$SRC_MOUNT/etc/machine-id" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Truncating /etc/machine-id"
		fi
		sh -c ">$SRC_MOUNT/etc/machine-id"
	fi

	if [ -e "$SRC_MOUNT/var/lib/dbus/machine-id" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Deleting /var/lib/dbus/machine-id"
		fi
		rm -f "$SRC_MOUNT/var/lib/dbus/machine-id"
	fi

	if [ -n "$KEEP_SSH" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Preserving SSH host keys."
		fi
	else
		if [ -n "$VERBOSE" ]; then
			echo "Deleting SSH host keys..."
			find "$SRC_MOUNT/etc/ssh" -type f -name 'ssh_host_*' -print
		fi
		find "$SRC_MOUNT/etc/ssh" -type f -name 'ssh_host_*' -delete
	fi
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
	if [ -n "$CLEAN_IMAGE" ]; then
		clean_chroot_fluff
	fi
}

execute_chroot () {
	local binds="$1"
	if [ -n "$binds" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Binding container dir $binds"
		fi
		binds="--bind=$binds"
	fi
	if [ -n "$INTERACTIVE_MODE" ]; then
		if ! systemd-nspawn -M solarnode-cust -D "$SRC_MOUNT" \
			--chdir=${SCRIPT_DIR##${SRC_MOUNT}} \
			${binds}; then
			ERR="Error running setup script in container."
			echo "!!!"
			echo "!!! Error with interactive setup in container!"
			echo "!!!"
		fi
	elif ! systemd-nspawn -M solarnode-cust -D "$SRC_MOUNT" \
			--chdir=${SCRIPT_DIR##${SRC_MOUNT}} \
			${binds} \
			./customize \
				${VERBOSE//TRUE/-v} \
				${SCRIPT_ARGS}; then
		ERR="Error running setup script in container."
		echo "!!!"
		echo "!!! Error running setup script in container!"
		echo "!!!"
	fi
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
	if ! rsync -aHWXhx ${VERBOSE//TRUE/--info=progress2,stats1} "$src"/ "$tmp_mount"/; then
		ERR="Error copying $label from $src to $tmp_mount"
	fi
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

setup_boot_cmdline () {
	local part="$1"
	local fstype="$2"
	local rootpartuuid="$3"
	local subdir="$4"
	local tmp_mount=$(mktemp -d -t sn-XXXXX)
	local tmp_root="$tmp_mount"
	if [ -n "$VERBOSE" ]; then
		echo "Mounting $part on $tmp_mount with options ${MNT_OPTS[$fstype]}."
	fi
	if ! mount -o ${MNT_OPTS[$fstype]} "$part" "$tmp_mount"; then
		echo "Error: failed to mount $part on $tmp_mount."
		exit 1
	fi
	if [ -n "$subdir" ]; then
		tmp_root="$tmp_root/$subdir"
	fi
	if [ -e "$tmp_root/cmdline.txt" ]; then
		if grep ' root=' "$tmp_root/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Changing root to PARTUUID=$rootpartuuid in $tmp_root/cmdline.txt... "
			sed -i 's/root=[^ ]*/root=PARTUUID='"$rootpartuuid"'/' $tmp_root/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
		if [ -n "$DEST_ROOT_FSTYPE" ]; then
			if grep ' rootfstype=' "$tmp_root/cmdline.txt" >/dev/null 2>&1; then
				echo -n "Changing rootfstype to $DEST_ROOT_FSTYPE in $tmp_root/cmdline.txt... "
				sed -i 's/rootfstype=[^ ]*/rootfstype='"$DEST_ROOT_FSTYPE"'/' $tmp_root/cmdline.txt \
					&& echo "OK" || echo "ERROR"
			fi
		fi
		if grep ' init=' "$tmp_root/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Removing init from $tmp_root/cmdline.txt... "
			sed -i 's/ init=[^ ]*//' $tmp_root/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
		if ! grep ' fsck.repair=' "$tmp_root/cmdline.txt" >/dev/null 2>&1; then
			echo -n "Adding fsck.repair=yes to $tmp_root/cmdline.txt... "
			sed -i '1s/$/ fsck.repair/' $tmp_root/cmdline.txt \
				&& echo "OK" || echo "ERROR"
		fi
	elif [ -e "$tmp_root/armbianEnv.txt" ]; then
		if grep 'rootdev=' "$tmp_root/armbianEnv.txt" >/dev/null 2>&1; then
			echo -n "Changing rootdev to PARTUUID=$rootpartuuid in $tmp_root/armbianEnv.txt... "
			sed -i 's/rootdev=[^ ]*/rootdev=PARTUUID='"$rootpartuuid"'/' $tmp_root/armbianEnv.txt \
				&& echo "OK" || echo "ERROR"
		fi
	fi
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

copy_img () {
	local size=$(wc -c <"$SRC_IMG")
	local size_mb=$(echo "$size / 1024 / 1024" |bc)
	local size_sector=""
	local size_sector_in=""
	if [ -n "$SHRINK_SOLARNODE_FS" ]; then
		size_mb=$(echo "$size_mb - $SHRINK_SOLARNODE_FS" |bc)
		if [ -n "$VERBOSE" ]; then
			echo "Shrinking output image by $SHRINK_SOLARNODE_FS MB."
		fi
		local part_num=$(sfdisk -ql "$LOOPDEV" -o Device |tail +2 |awk '{print NR,$0}' \
			|grep "${LOOPDEV}${SOLARNODE_PART##$LOOPDEV}" |cut -d' ' -f1)
		size_sector_in=$(sfdisk -ql "$LOOPDEV" -o Sectors |tail +$((1 + $part_num)) |head -1)
		size_sector=$(echo "$size_sector_in - $SHRINK_SOLARNODE_FS * 1024 * 1024 / 512" |bc)
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
	if [ -n "$size_sector" ]; then
		if ! sfdisk -q -d "$LOOPDEV" |sed -e "s/size=.*$size_sector_in/size=$size_sector/" |sfdisk -q "$out_loopdev"; then
			echo "Error copying partition table from $LOOPDEV to $outdev, shrunk from $size_sector_in to $size_sector sectors."
			exit 1
		fi
	elif ! sfdisk -q -d "$LOOPDEV" |sfdisk -q "$out_loopdev"; then
		echo "Error copying partition table from $LOOPDEV to $outdev."
		exit 1
	fi

	copy_bootloader "$out_loopdev"
	if [ -z "$NO_BOOT_PARTITION" ]; then
		copy_part "${out_loopdev}${SOLARBOOT_PART##$LOOPDEV}" "$FSTYPE_SOLARBOOT" "SOLARBOOT" "$SRC_MOUNT$BOOT_DEV_MOUNT"
	fi
	if [ -z "$ERR" ]; then
		copy_part "${out_loopdev}${SOLARNODE_PART##$LOOPDEV}" "${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}" "SOLARNODE" "$SRC_MOUNT"
	
		if [ -z "$NO_BOOT_PARTITION" ]; then
			setup_boot_cmdline "$out_loopdev${SOLARBOOT_PART##$LOOPDEV}" "$FSTYPE_SOLARBOOT" "$LAST_PARTUUID"
		else
			setup_boot_cmdline "$out_loopdev${SOLARNODE_PART##$LOOPDEV}" "$FSTYPE_SOLARNODE" "$LAST_PARTUUID" "boot"
		fi
	fi
	
	if [ -n "$VERBOSE" ]; then
		echo "Closing output image loop device $out_loopdev."
	fi
	losetup -d "$out_loopdev"

	close_src_loopdev
	
	if [ -z "$ERR" ]; then
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
	else
		echo "!!!"
		echo "!!! $ERR"
		echo "!!!"
	fi
}

copy_src_img
setup_src_loopdev
setup_chroot
execute_chroot "$BIND_MOUNTS"
clean_chroot
if [ -z "$ERR" ]; then
	copy_img
else
	close_src_loopdev
fi
clean_src_img
if [ -z "$ERR" -a -n "$DEST_PATH" ]; then
	echo "Customized image saved to $DEST_PATH"
fi
