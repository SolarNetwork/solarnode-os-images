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

Extra setup script IoT Link SolarNodeOS.

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

# remove any default nftables.conf
if [ -e /etc/nftables.conf ]; then
	echo -n "Removing /etc/nftables.conf... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif rm -f /etc/nftables.conf; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi

# add non-free-firmware and comment out deb-src and backports in /etc/apt/sources.list
if [ -e /etc/apt/sources.list ]; then
	if ! grep -q non-free-firmware /etc/apt/sources.list; then
		echo -n "Adding non-free-firmware to /etc/apt/sources.list... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif sed -i \
			-e 's/debian\(.*\) main$/debian\1 main non-free-firmware/' \
			-e 's/^deb-src/#deb-src/' \
			-e 's/^deb \(.*backports\)/#deb \1/' /etc/apt/sources.list; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
fi

# install custom kernel if available, from custom-kernel directory
# expect to find an Image file along with linux*.deb packages to install
if [ -e /tmp/overlay/custom-kernel/Image ]; then
	pkg="$(ls -1 /tmp/overlay/custom-kernel/linux-image-*.deb)"
	if [ -n "$pkg" ]; then
		# remove existing kernel
		for n in $(dpkg-query -Wf '${Package}\n' linux-image-* linux-headers-*); do
			echo -n "Removing kernel package $n... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				if dpkg -P --force-all $n >/dev/null; then
					echo "OK"
				else
					echo "ERROR"
				fi
			fi
		done
		if [ -e /boot/Image -a -z "$DRY_RUN" ]; then
			rm -f /boot/Image*
		fi
		vers="$(strings /tmp/overlay/custom-kernel/Image |grep 'Linux version' |head -1 |sed -e 's/.* version \([a-zA-Z0-9._-]*\).*/\1/')"
		echo -n "Installing custom kernel $vers... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			if dpkg -i /tmp/overlay/custom-kernel/*.deb >/dev/null; then
				cp -a /tmp/overlay/custom-kernel/Image "/boot/Image-$vers"
				chown root:root "/boot/Image-$vers"
				chmod 644 "/boot/Image-$vers"
				ln -sf "Image-$vers" /boot/Image
				echo "OK"
			else
				echo "ERROR"
			fi
		fi
	else
		echo "ERROR: Linux header package not found in /tmp/overlay/custom-kernel/"
	fi
fi