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

# mark packages as manually installed so autoremove does not remove
for f in iproute2 iw linux-base; do	
	if apt-mark showauto $f |grep -q "^$f$" 2>/dev/null; then
		echo -n "Marking $f package as maually installed... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif apt-mark manual $f >/dev/null; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
done

# hold packages to prevent accidental removal
for f in cl-deploy cl-uboot; do	
	if ! apt-mark showhold $f |grep -q "^$f$" 2>/dev/null; then
		echo -n "Setting hold on $f package... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif apt-mark hold $f >/dev/null; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
done

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

# Fix bug in bt-start removal scripts
if grep -q 'disable bt-start.service$' /var/lib/dpkg/info/bt-start.postrm 2>/dev/null; then
	echo -n "Fixing bt-start package remove script /var/lib/dpkg/info/bt-start.postrm... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif sed -i -e 's/disable bt-start.service$/disable bt-start.service 2>\/dev\/null || true/' /var/lib/dpkg/info/bt-start.postrm; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi

# remove backports
if grep -q 'backports' /etc/apt/sources.list; then
	echo -n "Removing backports apt source... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif sed -i -e '/backports/d' /etc/apt/sources.list; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi

# remove node repo
if [ -e /etc/apt/sources.list.d/nodesource.list ]; then
	echo -n "Removing nodesource apt source... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif rm -f /etc/apt/sources.list.d/nodesource.list; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi
