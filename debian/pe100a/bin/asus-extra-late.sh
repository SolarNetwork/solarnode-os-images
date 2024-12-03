#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
VERBOSE=""

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

remove_asus_failover
remove_edgex
