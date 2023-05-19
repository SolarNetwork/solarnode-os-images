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

if [ -e /etc/profile.d/resize.sh ]; then
	echo -n "Removing base profile script /etc/profile.d/resize.sh... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	else
		rm -f /etc/profile.d/resize.sh
		echo "OK"
	fi
fi
