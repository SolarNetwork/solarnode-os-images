#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
VERBOSE=""
SCRIPT_DIR="$(dirname "$0")"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Extra setup script IoT Gate SolarNodeOS.

Arguments:
 -n                     - dry run; do not make any actual changes
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":nv" opt; do
	case $opt in
		n) DRY_RUN='TRUE';;
		v) VERBOSE='TRUE';;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done
shift $(($OPTIND - 1))

remove_asus_failover () {
	local unit="/lib/systemd/system/asus_failover.service"
	
	if [ -e "$unit" ]; then
		echo -n "Removing asus_failover service... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf /etc/fo
			rm -f /etc/systemd/system/multi-user.target.wants/asus_failover.service
			rm -f "$unit"
			echo "OK"
		fi
	fi
}

remove_edgex () {
	local unit="/lib/systemd/system/EdgeX.service"
	if [ -e "$unit" ]; then
		echo -n "Removing EdgeX service... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -f /usr/bin/docker-compose
			rm -rf /etc/EdgeX
			rm -f /etc/systemd/system/multi-user.target.wants/EdgeX.service
			rm -f "$unit"
			echo "OK"
		fi
	fi
}

remove_X11 () {
	echo -n "Removing X11... "
	if [ -n "$DRY_RUN" ]; then
		find / -name '*weston*' -o -name '*wayland*' -o -name '*glmark2*'
		echo "DRY RUN"
	else
		find / \( -name '*weston*' -o -name '*wayland*' -o -name '*glmark2*' \) \
			-prune -exec rm -rf {} \; 2>/dev/null || true
		echo "OK"
	fi
}

remove_nonpackaged () {
	echo -n "Removing miscellaneous non-packaged files... "
	if [ -n "$DRY_RUN" ]; then
		for d in /lib/systemd; do
			bash "$SCRIPT_DIR/find-nonpackage-files.sh" "$d"
		done
		echo "DRY RUN"
	else
		for d in /lib/systemd; do
			bash "$SCRIPT_DIR/find-nonpackage-files.sh" "$d" |xargs rm -rf
		done
		rm -f /sbin/resize-helper
		rm -f /etc/udev/rules.d/automount.rules
		rm -f /etc/udev/scripts/mount_fs.sh
		echo "OK"
	fi
}

remove_asus_failover
remove_edgex
remove_X11
remove_nonpackaged

systemctl daemon-reload 2>/dev/null || true
