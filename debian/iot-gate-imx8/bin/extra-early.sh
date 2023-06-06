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

# Fix bugs in package scripts, see
# https://github.com/Azure/iot-identity-service/issues/531

for f in aziot-edge aziot-identity-service; do
	if grep -q 'daemon-reload$' /var/lib/dpkg/info/$f.postrm 2>/dev/null; then
		echo -n "Fixing Azure package remove script /var/lib/dpkg/info/$f.postrm... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif sed -i -e 's/daemon-reload$/daemon-reload 2>\/dev\/null || true/' /var/lib/dpkg/info/$f.postrm; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
done
