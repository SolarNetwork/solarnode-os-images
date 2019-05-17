#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
APP_USER="solar"
APP_USER_PASS="solar"
PI_USER="pi"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
VERBOSE=""

ERR_LOG="/var/tmp/setup-pi.err"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Arguments:
 -n                     - dry run; do not make any actual changes
 -R <root dev label>    - the root device label; defaults to SOLARNODE
 -r <root dev>          - the root device; defaults to /dev/mmcblk0p2
 -U <user pass>         - the app user password; defaults to solar
 -u <username>          - the app username to use; defaults to solar
 -V <pi user>           - the pi username to delete; defaults to pi
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":nR:r:U:u:V:v" opt; do
	case $opt in		
		n) DRY_RUN='TRUE';;
		R) ROOT_DEV_LABEL="${OPTARG}";;
		r) ROOT_DEV="${OPTARG}";;
		U) APP_USER_PASS="${OPTARG}";;
		u) APP_USER="${OPTARG}";;
		V) PI_USER="${OPTARG}";;
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
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			e2label "$ROOT_DEV" "$ROOT_DEV_LABEL" 2>>$ERR_LOG && echo "OK" || echo "ERROR"
		fi
	fi
}

setup_user () {
	if grep -q "^$APP_USER" /etc/passwd; then
		echo "User $APP_USER already exists."
	else
		echo -n "Creating user $APP_USER... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			useradd -m -U -G dialout,sudo -s /bin/bash "$APP_USER" 2>>$ERR_LOG && echo "OK" || echo "ERROR"
			echo "$APP_USER:$APP_USER_PASS" |chpasswd 2>>$ERR_LOG
		fi
	fi
	
	# delete any 'pi' user if found
	if id "$PI_USER" >/dev/null 2>&1; then
		echo -n "Deleting user $PI_USER..."
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			deluser --remove-home "$PI_USER" >/dev/null 2>>$ERR_LOG && echo "OK" || { 
				echo "ERROR"
				echo "You might need to log out, then back in as the $APP_USER user to continue."
				exit 1; }
		fi
	else
		echo "User $PI_USER already removed."
	fi
}

setup_root_dev
setup_user
check_err
