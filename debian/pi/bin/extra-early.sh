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

Extra setup script Raspberry Pi SolarNodeOS.

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

# Remove existing nftables conf
if [ -e /etc/nftables.conf ]; then
	echo -n "Removing /etc/nftables.conf configuration... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif rm -f /etc/nftables.conf; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi

# Fix bug in rpi-keyboard-config removal script
if grep -q 'subsystem-match=hidraw$' /var/lib/dpkg/info/rpi-keyboard-config.prerm 2>/dev/null; then
	echo -n "Fixing rpi-keyboard-config package remove script /var/lib/dpkg/info/rpi-keyboard-config.prerm... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif sed -i -e 's/udevadm \([^;]*\)$/udevadm \1 || true/' /var/lib/dpkg/info/rpi-keyboard-config.prerm; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi
