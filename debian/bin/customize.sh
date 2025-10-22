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
DEST_MNT_OPTS[btrfs]="defaults,noatime,nodiratime,commit=60,compress=zstd,errors=remount-ro"
DEST_MNT_OPTS[ext4]="defaults,noatime,commit=60,errors=remount-ro"
DEST_MNT_OPTS[vfat]="defaults,errors=remount-ro"

SRC_BOOT_LABEL="SOLARBOOT"
SRC_BOOT_PARTNUM=""
SRC_ROOT_LABEL="SOLARNODE"
SRC_ROOT_PARTNUM=""
SRC_DATA_LABEL="SOLARDATA"
SRC_DATA_PARTNUM=""
DEST_ROOT_FSTYPE=""
ROOT_DEV_LABEL="${ROOT_DEV_LABEL:-SOLARNODE}"
BOOT_DEV_LABEL="${BOOT_DEV_LABEL:-SOLARBOOT}"
BOOT_DEV_MOUNT="${BOOT_DEV_MOUNT:-/boot}"
BOOT_MOUNT_UUID=""
DATA_DEV_LABEL="${DATA_DEV_LABEL:-SOLARDATA}"
DATA_DEV_MOUNT="${DATA_DEV_MOUNT:-/mnt/data}"

RO_DEST_FSOPTS=""

CLEAN_IMAGE=""
COMPRESS_DEST_IMAGE=""
COMPRESS_DEST_OPTS="-8 -T 0 -M 90%"
COMPRESS_KEEP_RAW_IMAGE=""
DEST_PATH=""
DEST_DATA_FSTYPE=""
EXPAND_SOLARNODE_FS=""
INTERACTIVE_MODE=""
KEEP_SSH=""
NO_BOOT_PARTITION=""
DATA_PARTITION_SIZE=""
SCRIPT_ARGS=""
SHRINK_SOLARNODE_FS=""
SRC_IMG=""
TMP_DIR="${TMPDIR:-/tmp}"
VERBOSE=""

ERR=""

show_version () {
	echo 'v101'
}

do_help () {
	cat 1>&2 <<"EOF"
Usage: customize.sh <arguments> src script [bind-mounts]

 -a <args>        - extra argumnets to pass to the script; can be provided multiple times
                    to concatenate all extra arguments together with space character
 -B               - disable separate boot partition (single root partition)
 -d <size MB>     - include a SOLARDATA partition of this size, in MB
 -C               - add 'ro' option to SOLARBOOT and SOLARNODE filesystem mount options
 -c               - clean out log files, temp files, SSH host keys from final
                    image
 -E <size MB>     - shrink the output SOLARNODE partition by this amount, in MB
 -e <size MB>     - expand the input SOLARNODE partition by this amount, in MB
 -h               - print this help and exit
 -i               - interactive mode; run without script
 -k               - if -z also given, keep the uncompressed image file when done
 -M <boot mount>  - the boot partition mount directory; defaults to /boot
 -N <boot part #> - the source boot partition number, instead of using label
 -n <root part #> - the source root partition number, instead of using label
 -P <boot label>  - the source boot partition label; defaults to SOLARBOOT
 -p <root label>  - the source root partition label; defaults to SOLARNODE
 -Q <data part #> - the source data partition number, instead of using label
 -q <data label>  - the source data partition label; defaults to SOLARDATA
 -o <out name>    - the output name for the final image
 -R <fstype>      - use specific data filesystem type in the destination image
 -r <fstype>      - use specific root filesystem type in the destination image
 -S               - if -c set, keep SSH host keys
 -T <dir>         - temporary directory to use
 -U               - use PARTUUID for boot mount, instead of label
 -V               - show script version and exit
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

while getopts ":a:BcCd:E:e:hiko:M:N:n:P:p:Q:q:r:R:ST:UVvZ:z" opt; do
	case $opt in
		a) 	if [ -n "$SCRIPT_ARGS" ]; then
				SCRIPT_ARGS="${SCRIPT_ARGS} ${OPTARG}"
			else
				SCRIPT_ARGS="${OPTARG}"
			fi
			;;
		B) NO_BOOT_PARTITION="TRUE";;
		C) RO_DEST_FSOPTS=',ro';;
		c) CLEAN_IMAGE="TRUE";;
		d) DATA_PARTITION_SIZE="${OPTARG}";;
		E) SHRINK_SOLARNODE_FS="${OPTARG}";;
		e) EXPAND_SOLARNODE_FS="${OPTARG}";;
		h) do_help && exit 0 ;;
		i) INTERACTIVE_MODE="TRUE";;
		k) COMPRESS_KEEP_RAW_IMAGE="TRUE";;
		o) DEST_PATH="${OPTARG}";;
		M) BOOT_DEV_MOUNT="${OPTARG}";;
		N) SRC_BOOT_PARTNUM="${OPTARG}";;
		n) SRC_ROOT_PARTNUM="${OPTARG}";;
		P) SRC_BOOT_LABEL="${OPTARG}";;
		p) SRC_ROOT_LABEL="${OPTARG}";;
		Q) SRC_DATA_PARTNUM="${OPTARG}";;
		q) SRC_DATA_LABEL="${OPTARG}";;
		R) DEST_DATA_FSTYPE="${OPTARG}";;
		r) DEST_ROOT_FSTYPE="${OPTARG}";;
		S) KEEP_SSH="TRUE";;
		T) TMP_DIR="${OPTARG}";;
		U) BOOT_MOUNT_UUID="TRUE";;
		v) VERBOSE="TRUE";;
		V) 	show_version
			exit 0
			;;
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
FSTYPE_SOLARDATA=""
LOOPDEV=""
SOLARBOOT_PART=""
SOLARNODE_PART=""
SOLARDATA_PART=""
SRC_IMG=$(mktemp -p "$TMP_DIR" img-XXXXX)
SRC_MOUNT=$(mktemp -p "$TMP_DIR" -d sn-XXXXX)
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
	local expand_mb=$((${EXPAND_SOLARNODE_FS:-0} + ${DATA_PARTITION_SIZE:-0}))
	if [ $expand_mb -gt 0 ]; then
		if ! truncate -s +${expand_mb}M "$SRC_IMG"; then
			echo "Error: unable to expand $SRC_IMG by ${expand_mb}MB."
		elif [ -n "$VERBOSE" ]; then
			echo "Expanded $SRC_IMG by ${expand_mb}MB."
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
	
	# see if using MBR vs GPT parition scheme
	PART_SCHEME="$(sfdisk -l $LOOPDEV -o Type |grep -i 'disklabel type' |cut -d' ' -f3)"
	echo "Discovered $PART_SCHEME partition scheme in source image."
	
	local part_count="$(($(lsblk -npo kname $LOOPDEV|wc -l) - 1))"
	if [ -n "$VERBOSE" ]; then
		echo "Discovered $part_count partitions in source image."
	fi

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
		local part_num=$(sfdisk -ql "$LOOPDEV" -o Device |tail -n +2 |awk '{print NR,$0}' |grep "$SOLARNODE_PART" |cut -d' ' -f1)
		
		# if not the last partition, delete all later partitions so we can expand the SOLARNODE one
		if [ $part_num -lt $part_count ]; then
			local i=0;
			for i in $(seq $part_count -1 $((part_num + 1))); do 
				if [ -n "$VERBOSE" ]; then
					echo "Moving source partition $i ${EXPAND_SOLARNODE_FS} MB"
				fi
				echo "+${EXPAND_SOLARNODE_FS}M," |sfdisk --move-data ${LOOPDEV} -N${i} --no-reread -q
			done
		fi
	
		if [ -n "$VERBOSE" ]; then
			echo "Expanding partition $part_num on ${LOOPDEV} by $EXPAND_SOLARNODE_FS MB."
		fi
		echo ",+${EXPAND_SOLARNODE_FS}M" |sfdisk ${LOOPDEV} -N${part_num} --no-reread -q
		partx -u ${LOOPDEV}
	fi

	if [ -n "$DATA_PARTITION_SIZE" ]; then
		if [ -n "$SRC_DATA_PARTNUM" ]; then
			SOLARDATA_PART=$(lsblk -npo kname $LOOPDEV |tail -n +$((1+$SRC_DATA_PARTNUM)) |head -n 1)
		else
			SOLARDATA_PART=$(lsblk -npo kname,label $LOOPDEV |grep -i $SRC_DATA_LABEL |cut -d' ' -f 1)
		fi
		local created_data_part=""
		if [ -z "$SOLARDATA_PART" ]; then
			# create SOLARDATA partition now
			local data_part_start=$(sfdisk -ql $LOOPDEV -o Start,Sectors |tail -1 |awk '{print $1 + $2;}')
			if [ -n "$VERBOSE" ]; then
				echo "Adding SOLARDATA partition starting at $data_part_start"
			fi
			if ! echo "${data_part_start}," | sfdisk -q $LOOPDEV --append; then
				echo "Failed to add new SOLARDATA partition starting at $data_part_start"
				exit 1
			fi
			sfdisk -q $LOOPDEV --reorder
			sleep 1
			partx -u ${LOOPDEV}
			SOLARDATA_PART=$(lsblk -npo kname $LOOPDEV |tail -1)
			if [ -n "$VERBOSE" ]; then
				echo "Created source SOLARDATA partition ${SOLARDATA_PART}."
			fi
			local data_fstype="${DEST_DATA_FSTYPE:-ext4}"
			if [ -n "$VERBOSE" ]; then
				echo "Creating $SOLARDATA_PART $data_fstype filesystem with options ${FS_OPTS[$data_fstype]}."
			fi
			if ! mkfs.$data_fstype ${FS_OPTS[$data_fstype]} "$SOLARDATA_PART"; then
				echo "Error: failed to create $SOLARDATA_PART $data_fstype filesystem."
				exit 1
			fi
			case $data_fstype in
				# btrfs HANDLE AFTER MOUNT BELOW
				ext*)  e2label "$SOLARDATA_PART" "$SRC_DATA_LABEL";;
				vfat)  fatlabel "$SOLARDATA_PART" "$SRC_DATA_LABEL";;
			esac
			created_data_part='TRUE'
		elif [ -n "$VERBOSE" ]; then
			echo "Discovered source $SRC_DATA_LABEL partition ${SOLARDATA_PART}."
		fi
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
	
	if [ -n "$SOLARDATA_PART" ]; then
		if [ ! -d "$SRC_MOUNT$DATA_DEV_MOUNT" ]; then
			if ! mkdir -p "$SRC_MOUNT$DATA_DEV_MOUNT"; then
				echo "Error: unable to create $SRC_MOUNT$DATA_DEV_MOUNT directory to mount $SOLARDATA_PART."
				exit 1
			fi
		fi
		if ! mount "$SOLARDATA_PART" "$SRC_MOUNT$DATA_DEV_MOUNT"; then
			echo "Error: unable to mount $SOLARDATA_PART on $SRC_MOUNT$DATA_DEV_MOUNT."
			exit 1
		elif [ -n "$VERBOSE" ]; then
			echo "Mounted source $SRC_DATA_LABEL filesystem on $SRC_MOUNT$DATA_DEV_MOUNT."
		fi
		if [ -n "$created_data_part" -a "$data_fstype" = 'btrfs' ]; then
			btrfs filesystem label "$SRC_MOUNT$DATA_DEV_MOUNT" "SOLARDATA"
		fi

		FSTYPE_SOLARDATA=$(findmnt -f -n -o FSTYPE "$SOLARDATA_PART")
		if [ -z "$FSTYPE_SOLARDATA" ]; then
			echo "Error: $SRC_DATA_LABEL filesystem type not discovered."
		elif [ -n "$VERBOSE" ]; then
			echo "Discovered source $SRC_DATA_LABEL filesystem type $FSTYPE_SOLARDATA."
		fi
	fi
}

close_src_loopdev () {
	if [ -z "$NO_BOOT_PARTITION" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Unmounting source $SRC_BOOT_LABEL filesystem ${SRC_MOUNT}${BOOT_DEV_MOUNT}."
		fi
		umount "${SRC_MOUNT}${BOOT_DEV_MOUNT}"
	fi
	if [ -n "$SOLARDATA_PART" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Unmounting source $SRC_DATA_LABEL filesystem ${SRC_MOUNT}${DATA_DEV_MOUNT}."
		fi
		umount "${SRC_MOUNT}${DATA_DEV_MOUNT}"
	fi
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
	if [ -n "$SOLARDATA_PART" ]; then
		if grep -q "$DATA_DEV_MOUNT" $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
			if ! grep -q 'LABEL='"$DATA_DEV_LABEL" $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
				echo -n "Changing $DATA_DEV_MOUNT mount in $SRC_MOUNT/etc/fstab to use label $DATA_DEV_LABEL... "
				sed -i 's/^.*LABEL=[^ 	]*[ 	]*\/ /LABEL='"$DATA_DEV_LABEL"' \/ /' $SRC_MOUNT/etc/fstab \
					&& echo "OK" || echo "ERROR"
			fi
		else
			echo -n "Adding $DATA_DEV_MOUNT mount in $SRC_MOUNT/etc/fstab... "
			echo "LABEL=${DATA_DEV_LABEL} ${DATA_DEV_MOUNT} ${FSTYPE_SOLARDATA} ${DEST_MNT_OPTS[$FSTYPE_SOLARDATA]} 0 1" \
				>>$SRC_MOUNT/etc/fstab && echo "OK" || echo "ERROR"
		fi
	fi
	if ! grep -q '^tmpfs\s*/run ' $SRC_MOUNT/etc/fstab >/dev/null 2>&1; then
		echo -n "Adding /run mount in $SRC_MOUNT/etc/fstab with explicit size... "
		echo 'tmpfs /run tmpfs rw,nosuid,noexec,relatime,size=50%,mode=755 0 0' >>$SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	
	# make sure our root mount fstype matches final output fstype
	local fsopts=""
	local fstype="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"

	if [ -n "$fstype" -a "$fstype" != "${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}" ]; then
		echo -n "Changing / fstype in $SRC_MOUNT/etc/fstab from $fstype to ${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}... "
		sed -i 's/LABEL='"$ROOT_DEV_LABEL"'[ 	][ 	]*\/[ 	][ 	]*[^ 	][^ 	]*/LABEL='"$ROOT_DEV_LABEL"' \/ '"${DEST_ROOT_FSTYPE:-${FSTYPE_SOLARNODE}}"' /' $SRC_MOUNT/etc/fstab \
			&& echo "OK" || echo "ERROR"
	fi
	
	if [ -z "$NO_BOOT_PARTITION" ]; then
		# make sure boot mount options match desired + errors=remount-ro
		fsopts="$(grep "LABEL=$BOOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $4}')"
		fstype="$(grep "LABEL=$BOOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"
		if [ -n "$fstype" ]; then
			if [ "$fstype" != "auto" -a "$fsopts" != "${DEST_MNT_OPTS[$fstype]}${RO_DEST_FSOPTS}" ]; then
				echo -n "Changing /boot $fstype options in $SRC_MOUNT/etc/fstab from [$fsopts] to [${DEST_MNT_OPTS[$fstype]}]... "
				sed -i 's/\(LABEL='"$BOOT_DEV_LABEL"'[ 	][ 	]*[^ 	]*[ 	][ 	]*[^ 	]*\)[ 	][ 	]*[^ 	]*[ 	]/\1 '"${DEST_MNT_OPTS[$fstype]}${RO_DEST_FSOPTS}"' /' $SRC_MOUNT/etc/fstab \
					&& echo "OK" || echo "ERROR"
			fi
		fi
	fi
	
	# make sure root mount options match desired
	fsopts="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $4}')"
	fstype="$(grep "LABEL=$ROOT_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"
	if [ -n "$fstype" ]; then
		if [ "$fsopts" != "${DEST_MNT_OPTS[$fstype]}${RO_DEST_FSOPTS}" ]; then
			echo -n "Changing / $fstype options in $SRC_MOUNT/etc/fstab from [$fsopts] to [${DEST_MNT_OPTS[$fstype]}]... "
			sed -i 's/\(LABEL='"$ROOT_DEV_LABEL"'[ 	][ 	]*[^ 	]*[ 	][ 	]*[^ 	]*\)[ 	][ 	]*[^ 	]*[ 	]/\1 '"${DEST_MNT_OPTS[$fstype]}${RO_DEST_FSOPTS}"' /' $SRC_MOUNT/etc/fstab \
				&& echo "OK" || echo "ERROR"
		fi
	fi

	# make sure data mount options match desired
	if [ -n "$SOLARDATA_PART" ]; then
		fsopts="$(grep "LABEL=$DATA_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $4}')"
		fstype="$(grep "LABEL=$DATA_DEV_LABEL" $SRC_MOUNT/etc/fstab 2>&1 |awk '{print $3}')"
		if [ -n "$fstype" ]; then
			if [ "$fsopts" != "${DEST_MNT_OPTS[$fstype]}" ]; then
				echo -n "Changing $DATA_DEV_MOUNT fs options in $SRC_MOUNT/etc/fstab from [$fsopts] to [${DEST_MNT_OPTS[$fstype]}]... "
				sed -i 's/\(LABEL='"$DATA_DEV_LABEL"'[ 	][ 	]*[^ 	]*[ 	][ 	]*[^ 	]*\)[ 	][ 	]*[^ 	]*[ 	]/\1 '"${DEST_MNT_OPTS[$fstype]}"' /' $SRC_MOUNT/etc/fstab \
					&& echo "OK" || echo "ERROR"
			fi
		fi
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
	SCRIPT_DIR=$(mktemp -p "$TMP_DIR" -d sn-XXXXX -p "$SRC_MOUNT/var/tmp")
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
		echo '##############################################################'
		echo '### Launching interactive shell in virtual image.'
		echo '### To mimic build run:'
		echo '###'
		echo "### ./customize ${SCRIPT_ARGS}"
		echo '###'
		echo "### Run 'exit 0' to complete the image, or 'exit 1' to cancel."
		echo '##############################################################'
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

setup_boot_cmdline () {
	local part="$1"
	local fstype="$2"
	local rootpartuuid="$3"
	local subdir="$4"
	local tmp_mount=$(mktemp -p "$TMP_DIR" -d sn-XXXXX)
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

# the copy_part function will save the UUID of the destination partition in $LAST_PARTUUID
LAST_PARTUUID=""

copy_part () {
	local part="$1"
	local fstype="$2"
	local label="$3"
	local src="$4"
	
	# save LAST_PARTUUID as previous value; so we can use in fstab if needed
	local prev_partuuid="$LAST_PARTUUID"

	if [ -n "$VERBOSE" ]; then
		echo "Creating $part $fstype filesystem with options ${FS_OPTS[$fstype]}."
	fi
	if ! mkfs.$fstype ${FS_OPTS[$fstype]} "$part"; then
		echo "Error: failed to create $part $fstype filesystem."
		exit 1
	fi
	local tmp_mount=$(mktemp -p "$TMP_DIR" -d sn-XXXXX)
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
		echo "Labeling $part as $label"
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
	elif [ "$label" = "SOLARNODE" -a -z "$NO_BOOT_PARTITION" -a -n "$BOOT_MOUNT_UUID" ]; then
		# change fstab from LABEL to PARTUUID
		if grep -q 'LABEL=[^ ]* */boot' $tmp_mount/etc/fstab >/dev/null 2>&1; then
			echo -n "Changing /boot mount in $tmp_mount/etc/fstab to use PARTUUID=$prev_partuuid... "
			sed -i 's/^.*LABEL=[^ ]* *\/boot/PARTUUID='"$prev_partuuid"' \/boot/' $tmp_mount/etc/fstab \
				&& echo "OK" || echo "ERROR"
		fi
	fi
	umount "$tmp_mount"
	rmdir "$tmp_mount"
}

copy_img () {
	local size=$(wc -c <"$SRC_IMG")
	local size_mb=$(echo "$size / 1024 / 1024" |bc)
	local part_count=0
	local root_part_num=0
	local shrink_size_sectors=0
	
	local out_img=$(mktemp -p "$TMP_DIR" img-XXXXX)
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
		echo "Error copying partition table from $LOOPDEV to $out_loopdev."
		exit 1
	fi
	
	if [ -n "$SHRINK_SOLARNODE_FS" ]; then
		size_mb=$(echo "$size_mb - $SHRINK_SOLARNODE_FS" |bc)
		part_count="$(($(lsblk -npo kname $LOOPDEV|wc -l) - 1))"
		root_part_num=$(sfdisk -ql "$LOOPDEV" -o Device |tail -n +2 |awk '{print NR,$0}' \
			|grep "${LOOPDEV}${SOLARNODE_PART##$LOOPDEV}" |cut -d' ' -f1)
		shrink_size_sectors=$(echo "$SHRINK_SOLARNODE_FS * 1024 * 1024 / 512" |bc)

		if [ -n "$VERBOSE" ]; then
			echo "Shrinking output SOLARNODE partition by $SHRINK_SOLARNODE_FS MB to $size_mb MB."
		fi
		if ! echo ",-${SHRINK_SOLARNODE_FS}M" |sfdisk -q "$out_loopdev" -N $root_part_num; then
			echo "Error shrinking $out_loopdev parition $root_part_num by $SHRINK_SOLARNODE_FS MB."
			exit 1
		fi
		if [ $root_part_num -lt $part_count ]; then
			# shift partitions
			local i
			for i in $(seq $((root_part_num + 1)) $part_count); do
				local part_start=$(($(sfdisk -ql "$out_loopdev" -o Start |tail -n +$((i + 1)) |head -1) - shrink_size_sectors))
				if [ -n "$VERBOSE" ]; then
					echo "Shifting partition $i back by ${SHRINK_SOLARNODE_FS} MB to start at $part_start"
				fi
				if ! echo "${part_start}," |sfdisk -q "$out_loopdev" -N $i; then
					echo "Error shifting $out_loopdev partition $i back by ${SHRINK_SOLARNODE_FS} MB"
					exit 1
				fi
			done
		fi
		
		if [ "$PART_SCHEME" = "gpt" ]; then
			# move backup table to after last partition, so we can shrink the image size after
			echo -n "Shifting GPT backup table to after last partition..."
			if ! sfdisk -q --relocate gpt-bak-mini $out_loopdev; then
				echo "ERROR"
				exit 1
			else
				echo "OK"
			fi
		fi
		
		partx -u "$out_loopdev"
	fi

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
	if [ -z "$ERR" -a -n "$SOLARDATA_PART" ]; then
		copy_part "${out_loopdev}${SOLARDATA_PART##$LOOPDEV}" "${DEST_DATA_FSTYPE:-${FSTYPE_SOLARDATA}}" "SOLARDATA" "$SRC_MOUNT$DATA_DEV_MOUNT"
	fi
			
	if [ -n "$VERBOSE" ]; then
		echo "Closing output image loop device $out_loopdev."
	fi
	losetup -d "$out_loopdev"
	
	if [ -n "$SHRINK_SOLARNODE_FS" ]; then
		if [ -n "$VERBOSE" ]; then
			echo "Shrinking output image $out_img by $SHRINK_SOLARNODE_FS MB."
		fi
		truncate -s "-${SHRINK_SOLARNODE_FS}M" "$out_img"
	fi
	
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
			
			if [ -z "$COMPRESS_KEEP_RAW_IMAGE" ]; then
				if [ -n "$VERBOSE" ]; then
					echo "Deleting uncompressed image ${out_path}/${out_name}.img..."
				fi
				rm -f "${out_path}/${out_name}.img" "${out_path}/${out_name}.img.sha256" 
			fi
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
