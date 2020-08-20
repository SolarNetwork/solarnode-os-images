#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

BOARD="nanopiair"
APP_USER="solar"
APP_USER_PASS="solar"
BOOT_DEV="/dev/mmcblk0p1"
BOOT_DEV_LABEL="SOLARBOOT"
DRY_RUN=""
HOSTNAME="solarnode"
INPUT_DIR="/tmp/overlay"
PKG_KEEP="conf/packages-keep.txt"
PKG_ADD="conf/packages-add.txt"
PKG_ADD_EARLY="conf/packages-add-early.txt"
PKG_DEL_LATE="conf/packages-del-late.txt"
PI_USER="pi"
RELEASE_NAME="SolarNodeOS 10"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
SKIP_FS_EXPAND=""
SKIP_SOFTWARE=""
SNF_PKG_REPO="https://debian.repo.solarnetwork.org.nz"
PKG_DIST="buster"
UPDATE_PKG_CACHE=""
VERBOSE=""

LOG="/var/tmp/setup-pi.log"
ERR_LOG="/var/tmp/setup-pi.err"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Setup script for a minimal SolarNode OS based on Armbian.

Arguments:
 -a <board>             - the Armbian board being set up; defaults to nanopiair
 -B <boot dev label>    - the boot device label; defaults to SOLARBOOT
 -b <boot dev>          - the boot device; defaults to /dev/mmcblk0p1
 -d <package list file> - path to list of packages to delete late in script;
                          defaults to conf/packages-del-late.txt
 -e <package list file> - path to list of packages to add early in script;
                          defaults to conf/packages-add-early.txt
 -E                     - skip setting the file system expansion marker
 -h <hostname>          - the hostname to use; defaults to solarnode
 -i <input dir>         - path to input configuration directory; defaults to /tmp/overlay
 -K <package list file> - path to list of packages to add; defaults to conf/packages-add.txt
 -k <package list file> - path to list of packages to keep; defaults to conf/packages-keep.txt
 -N <name>              - release name; defaults to 'SolarNodeOS 10'
 -n                     - dry run; do not make any actual changes
 -P                     - update package cache
 -p <apt repo url>      - the SNF package repository to use; defaults to
                          https://debian.repo.solarnetwork.org.nz;
                          the staging repo can be used instead, which is
                          https://debian.repo.stage.solarnetwork.org.nz;
                          or the staging repo can be accessed directly for development as
                          http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com
 -q <pkg dist>          - the package distribution to use; defaults to 'stretch'
 -R <root dev label>    - the root device label; defaults to SOLARNODE
 -r <root dev>          - the root device; defaults to /dev/mmcblk0p2
 -S                     - skip software install
 -U <user pass>         - the app user password; defaults to solar
 -u <username>          - the app username to use; defaults to solar
 -V <pi user>           - the pi username to delete; defaults to pi
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":a:B:b:e:Eh:i:K:k:N:nPp:q:R:r:SU:u:V:v" opt; do
	case $opt in
		a) BOARD="${OPTARG}";;
		B) BOOT_DEV_LABEL="${OPTARG}";;
		b) BOOT_DEV="${OPTARG}";;
		d) PKG_DEL_LATE="${OPTARG}";;
		e) PKG_ADD_EARLY="${OPTARG}";;
		E) SKIP_FS_EXPAND='TRUE';;
		h) HOSTNAME="${OPTARG}";;
		i) INPUT_DIR="${OPTARG}";;
		K) PKG_ADD="${OPTARG}";;
		k) PKG_KEEP="${OPTARG}";;
		N) RELEASE_NAME="${OPTARG}";;
		n) DRY_RUN='TRUE';;
		P) UPDATE_PKG_CACHE='TRUE';;
		p) SNF_PKG_REPO="${OPTARG}";;
		q) PKG_DIST="${OPTARG}";;
		R) ROOT_DEV_LABEL="${OPTARG}";;
		r) ROOT_DEV="${OPTARG}";;
		S) SKIP_SOFTWARE='TRUE';;
		U) APP_USER_PASS="${OPTARG}";;
		u) APP_USER="${OPTARG}";;
		V) PI_USER="${OPTARG}";;
		v) VERBOSE='TRUE';;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done
shift $(($OPTIND - 1))

# clear error log
cat /dev/null >$ERR_LOG
cat /dev/null >$LOG

check_err () {
	if [ -s "$ERR_LOG" ]; then
		echo ""
		echo "Errors or warnings have been generated in $ERR_LOG."
	fi
}

pkgs_install () {
	echo -n "Installing package(s) $@... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	else
		if ! apt-get -qy install --no-install-recommends $@; then
			echo "Error installing package $1"
			exit 1
		fi
		echo "OK"
	fi
}

# install package if not already installed
pkg_install () {
	if dpkg -s $1 >/dev/null 2>/dev/null; then
		echo "Package $1 already installed."
	else
		pkgs_install $1
	fi
}

pkgs_remove () {
	echo -n "Removing package(s) $@... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	else
		DEBIAN_FRONTEND=noninteractive apt-get -qy remove --purge $@
		echo "OK"
	fi
}

# remove package if installed
pkg_remove () {
	if dpkg -s $1 >/dev/null 2>/dev/null; then
		pkgs_remove $1
	else
		echo "Package $1 already removed."
	fi
}

# remove package if installed
pkg_autoremove () {
		if [ -z "$DRY_RUN" ]; then
			DEBIAN_FRONTEND=noninteractive apt-get -qy autoremove --purge $1
		fi
}

setup_hostname () {
	if grep -q "$HOSTNAME" /etc/hosts; then
		echo "Hostname already set to $HOSTNAME."
	else
		echo -n "Setting hostname to $HOSTNAME... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			echo "$HOSTNAME" >/etc/hostname && echo "OK"
		fi
	fi
}

setup_dns () {
	if grep -q "$HOSTNAME" /etc/hosts; then
		echo "/etc/hosts contains $HOSTNAME already."
	else
		echo "Setting up $HOSTNAME /etc/hosts entry..."
		sed "s/$BOARD/$HOSTNAME/" /etc/hosts >/tmp/hosts.new
		if diff -q /etc/hosts /tmp/hosts.new >/dev/null; then
			# no change
			rm -f /tmp/hosts.new
		else
			chmod 644 /tmp/hosts.new
			sudo mv -f /tmp/hosts.new /etc/hosts
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
			#echo "You need to log out, then back in as the $APP_USER user to continue."
			#exit 0
		fi
	fi

	# delete any 'pi' user if found
	if id "$PI_USER" >/dev/null 2>&1; then
		echo -n "Deleting user $PI_USER..."
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			killall -u pi
			deluser "$PI_USER" >/dev/null 2>>$ERR_LOG && echo "OK" || {
				echo "ERROR"
				echo "You might need to log out, then back in as the $APP_USER user to continue."
				exit 1; }
			if [ -d /home/"$PI_USER" ]; then
				rm -rf /home/"$PI_USER"
			fi
		fi
	else
		echo "User $PI_USER already removed."
	fi
	
	# lock root account if not already
	local root_ps_status=$(passwd -S root |cut -d' ' -f 2)
	case $root_ps_status in
		L*)
			echo 'The root account is already locked.'
			;;
			
		*)
			echo -n "Locking root account... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				passwd -l root >/dev/null && echo "OK" || echo "ERROR"
			fi
			;;
	esac
	
	# remove any "auto login" overrides
	if [ -d /etc/systemd/system/getty@.service.d ]; then
		echo -n 'Removing console auto-login configuration... '
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf /etc/systemd/system/getty\@.service.d && echo "OK" || echo "ERROR"
		fi
	fi
	if [ -d /etc/systemd/system/serial-getty@.service.d ]; then
		echo -n 'Removing serial console auto-login configuration... '
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf /etc/systemd/system/serial-getty\@.service.d && echo "OK" || echo "ERROR"
		fi
	fi
}

setup_apt () {
	if apt-key list 2>/dev/null |grep -q "packaging@solarnetwork.org.nz" >/dev/null; then
		echo 'SNF package repository GPG key already imported.'
	else
		echo -n 'Importing SNF package repository GPG key... '
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			curl -s "$SNF_PKG_REPO/KEY.gpg" |apt-key add -
		fi
	fi

	local updated=""
	if [ -e /etc/apt/sources.list.d/solarnetwork.list ]; then
		echo 'SNF package repository already configured.'
	else
		echo -n "Configuring SNF package repository $SNF_PKG_REPO... "
		updated=1
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			echo "deb $SNF_PKG_REPO $PKG_DIST main" >/etc/apt/sources.list.d/solarnetwork.list
			echo "OK"
			case $SNF_PKG_REPO in https*)
				pkg_install apt-transport-https
			esac
		fi
	fi

	if grep '^deb.*-backports' /etc/apt/sources.list >/dev/null 2>/dev/null; then
		echo -n 'Disabling backports repository... '
		updated=1
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			sed -i 's/^\(deb.*-backports.*\)/#\1/' /etc/apt/sources.list
			echo "OK"
		fi
	fi

	if [ -n "$updated" -o -n "$UPDATE_PKG_CACHE" ]; then
		echo -n "Updating package cache... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			apt-get -q update >>$LOG 2>>$ERR_LOG
			echo "OK"
		fi
	fi
}

setup_software_early () {
	# add all packages in manifest
	if [ -n "$PKG_ADD_EARLY" -a -e "$INPUT_DIR/$PKG_ADD_EARLY" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if ! grep -q "^$line$" /tmp/pkgs.txt; then
				pkg_install "$line"
			fi
		done < "$INPUT_DIR/$PKG_ADD_EARLY"
	fi
}

setup_software () {
	pkg_install localepurge
	pkg_remove rsyslog
	pkg_install busybox-syslogd

	# remove all packages NOT in manifest or not to add later
	if [ -n "$PKG_KEEP" -a -e "$INPUT_DIR/$PKG_KEEP" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		local to_remove=""
		while IFS= read -r line; do
			if ! { grep -q "^$line$" "$INPUT_DIR/$PKG_KEEP" || grep -q "^$line$" "$INPUT_DIR/$PKG_ADD"; }; then
				to_remove="$to_remove $line"
			fi
		done < /tmp/pkgs.txt
		if [ -n "$to_remove" ]; then
			pkgs_remove $to_remove
		fi
	fi

	# add all packages in manifest
	if [ -n "$PKG_ADD" -a -e "$INPUT_DIR/$PKG_ADD" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		local to_add=""
		while IFS= read -r line; do
			if ! grep -q "^$line$" /tmp/pkgs.txt; then
				to_add="$to_add $line"
			fi
		done < "$INPUT_DIR/$PKG_ADD"
		if [ -n "$to_add" ]; then
			pkgs_install $to_add
		fi
	fi

	pkg_autoremove
	apt-get clean
}

setup_software_late () {
	# delete all packages in manifest
	if [ -n "$PKG_DEL_LATE" -a -e "$INPUT_DIR/$PKG_DEL_LATE" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if ! grep -q "^$line$" /tmp/pkgs.txt; then
				pkg_remove "$line"
			fi
		done < "$INPUT_DIR/$PKG_DEL_LATE"
	fi

	pkg_autoremove
	apt-get clean
}

setup_time () {
	timedatectl set-ntp true
}

setup_expandfs () {
	# the sn-expandfs service will look for this file on boot, and expand the root fs
	if [ -e /boot/sn-expandfs ]; then
		echo 'Boot time filesystem expand marker /boot/sn-expandfs already available.'
	else
		echo -n 'Creating boot time filesystem expand marker /boot/sn-expandfs... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			if touch /boot/sn-expandfs; then
				echo 'OK'
			else
				echo 'ERROR'
			fi
		fi
	fi
}

setup_swap () {
	if [ -e /var/swap ]; then
		echo -n 'Removing swap file /var/swap... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			swapoff -a
			rm -f /var/swap
			echo 'OK'
		fi
	fi
}

setup_busybox_links () {
	echo -n 'Installing busybox app links... '
	if [ -n "$DRY_RUN" ]; then
		echo 'DRY RUN'
	else
		busybox --install -s
		echo 'OK'
	fi
}

setup_motd () {
	echo -n 'Removing Armbian MOTD configuration... '
	if [ -n "$DRY_RUN" ]; then
		echo 'DRY RUN'
	else
		find /etc/update-motd.d -name '*armbian*' -delete 2>/dev/null
		echo 'OK'
	fi
}

setup_issue () {
	if ! grep "$RELEASE_NAME" /etc/issue >/dev/null 2>&1; then
		echo -n 'Setting /etc/issue release name... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			sed -i '1s/.*\\/'"$RELEASE_NAME"' \\/' /etc/issue
			echo 'OK'
		fi
	fi
	if ! grep "$RELEASE_NAME" /etc/issue.net >/dev/null 2>&1; then
		echo -n 'Setting /etc/issue.net release name... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			echo -n "$RELEASE_NAME" >/etc/issue.net
			echo 'OK'
		fi
	fi
}

setup_software_early
setup_hostname
setup_dns
setup_user
setup_apt
if [ -z "$SKIP_SOFTWARE" ]; then
	setup_software
fi
setup_time
if [ -z "$SKIP_FS_EXPAND" ]; then
	setup_expandfs
fi
setup_swap
if [ -z "$SKIP_SOFTWARE" ]; then
	setup_busybox_links
fi
setup_motd
setup_issue
if [ -z "$SKIP_SOFTWARE" ]; then
	setup_software_late
fi
check_err
