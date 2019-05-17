#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
APP_USER="solar"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
VERBOSE=""

ERR_LOG="/var/tmp/setup-pi.err"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 [-nv]

Arguments:
 -n                     - dry run; do not make any actual changes
 -R <root dev label>    - the root device label; defaults to SOLARNODE
 -r <root dev>          - the root device; defaults to /dev/mmcblk0p2
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":nR:r:v" opt; do
	case $opt in		
		n) DRY_RUN='TRUE';;
		R) ROOT_DEV_LABEL="${OPTARG}";;
		r) ROOT_DEV="${OPTARG}";;
		v) VERBOSE='TRUE';;
		?)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done
shift $(($OPTIND - 1))

# clear error log
cat /dev/null >$ERR_LOG

check_err () {
	if [ -s "$ERR_LOG" ]; then
		echo ""
		echo "Errors or warnings have been generated in $ERR_LOG."
	fi
}

setup_root_dev () {
	local curr=$(e2label "$ROOT_DEV" 2>>$ERR_LOG)
	if [ "$curr" = "$ROOT_DEV_LABEL" ]; then
		echo "Root device $ROOT_DEV already has label $ROOT_DEV_LABEL."
	else
		echo -n "Setting root device $ROOT_DEV label to $ROOT_DEV_LABEL... "
		if [ -z "$DRY_RUN" ]; then
			e2label "$ROOT_DEV" "$ROOT_DEV_LABEL" 2>>$ERR_LOG && echo "OK" || echo "ERROR"
		else
			echo "DRY RUN"
		fi
	fi
}

setup_root_dev
check_err