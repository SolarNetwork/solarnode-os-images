#!/usr/bin/env sh

# NOTE FOR HEADLESS INSTALL: create a /boot/ssh file, and Raspbian will 
# start up the SSH server. Then you can SSh as pi:raspberry.

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

APP_USER="solar"
APP_USER_PASS="solar"
DRY_RUN=""
HOSTNAME="solarnode"
PKG_KEEP="conf/packages-keep.txt"
PKG_ADD="conf/packages-add.txt"
SOURCES_LIST="conf/sources.list"
PI_USER="pi"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
SNF_PKG_REPO="https://debian.repo.solarnetwork.org.nz"
PKG_DIST="stretch"
UPDATE_PKG_CACHE=""
VERBOSE=""

LOG="/var/tmp/setup-pi.log"
ERR_LOG="/var/tmp/setup-pi.err"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Setup script for a minimal SolarNode OS based on the OrangePi Debian image.

Start with a clean OrangePi image, e.g. OrangePi_zero_debian_stretch_server_linux5.3.5_v1.0.img
and boot a Pi with the image. Once booted, copy this bin directory and the sibling conf
directory to the Pi, e.g.

  $ rsync -av bin conf root@OrangePi:/var/tmp/
  
Then on the Pi, execute this as the root user:

  $ ssh root@OrangePi
  $ cd /var/tmp
  $ bin/setup-orangepi.sh
  
For Debian 10 development, execute this variation:

  $ bin/setup-pi.sh -p http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com \
    -q buster -k conf/packages-deb10-keep.txt -K conf/packages-deb10-add.txt  

Arguments:
 -h <hostname>          - the hostname to use; defaults to solarnode
 -K <package list file> - path to list of packages to add; defaults to conf/packages-add.txt
 -k <package list file> - path to list of packages to keep; defaults to conf/packages-keep.txt
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
 -U <user pass>         - the app user password; defaults to solar
 -u <username>          - the app username to use; defaults to solar
 -V <pi user>           - the pi username to delete; defaults to orangepi
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":h:K:k:nPp:q:R:r:U:u:V:v" opt; do
	case $opt in
		h) HOSTNAME="${OPTARG}";;
		K) PKG_ADD="${OPTARG}";;
		k) PKG_KEEP="${OPTARG}";;
		n) DRY_RUN='TRUE';;
		P) UPDATE_PKG_CACHE='TRUE';;
		p) SNF_PKG_REPO="${OPTARG}";;
		q) PKG_DIST="${OPTARG}";;
		R) ROOT_DEV_LABEL="${OPTARG}";;
		r) ROOT_DEV="${OPTARG}";;
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

# install package if not already installed
pkg_install () {	
	if dpkg -s $1 >/dev/null 2>/dev/null; then
		echo "Package $1 already installed."
	else
		echo "Installing package $1..."
		if [ -z "$DRY_RUN" ]; then
			if ! apt-get -qy install --no-install-recommends $1; then
				echo "Error installing package $1"
				exit 1
			fi
		fi
	fi
}

# remove package if installed
pkg_remove () {	
	if dpkg -s $1 >/dev/null 2>/dev/null; then
		echo "Removing package $1..."
		if [ -z "$DRY_RUN" ]; then
			apt-get -qy remove --purge $1
		fi
	else
		echo "Package $1 already removed."
	fi
}

# remove package if installed
pkg_autoremove () {	
		if [ -z "$DRY_RUN" ]; then
			apt-get -qy autoremove --purge $1
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

setup_hostname () {
	if hostnamectl status --static |grep -q "$HOSTNAME"; then
		echo "Hostname already set to $HOSTNAME."
	else
		echo -n "Setting hostname to $HOSTNAME... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			hostnamectl set-hostname "$HOSTNAME" && echo "OK"
		fi
	fi
}

setup_dns () {
	if grep -q "$HOSTNAME" /etc/hosts; then
		echo "/etc/hosts contains $HOSTNAME already."
	else
		echo -n "Setting up $HOSTNAME /etc/hosts entry..."
		sed "s/^127.0.1.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts >/tmp/hosts.new
		if diff -q /etc/hosts /tmp/hosts.new >/dev/null; then
			# didn't change anything, try 127.0.1.0
			sed "s/^127.0.0.1[[:space:]]*localhost/127.0.0.1 $HOSTNAME localhost/" /etc/hosts >/tmp/hosts.new
		fi
		if diff -q /etc/hosts /tmp/hosts.new >/dev/null; then
			# no change
			rm -f /tmp/hosts.new
		else
			if [ -n "$DRY_RUN" ]; then
				echo 'DRY RUN'
			else
				chmod 644 /tmp/hosts.new
				mv -f /tmp/hosts.new /etc/hosts
				echo 'nameserver 1.1.1.1' >>/etc/resolv.conf
				echo 'OK'
			fi
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
			killall -u pi
			deluser --remove-home "$PI_USER" >/dev/null 2>>$ERR_LOG && echo "OK" || { 
				echo "ERROR"
				echo "You might need to log out, then back in as the $APP_USER user to continue."
				exit 1; }
		fi
	else
		echo "User $PI_USER already removed."
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
	if [ -e "$SOURCES_LIST" ]; then
		if ! diff "$SOURCES_LIST" /etc/apt/sources.list >/dev/null; then
			updated=1
			echo -n "Replacing /etc/apt/sources.list..."
			if [ -n "$DRY_RUN" ]; then
				echo 'DRY RUN'
			else
				cp -f conf/sources.list /etc/apt/sources.list
				echo 'OK'
			fi
		else
			echo "/etc/apt/sources.list already configured."
		fi
	fi
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

setup_tmux () {
	pkg_install locales
	pkg_install tmux
	if [ -z "$TMUX" ]; then
		if [ -z "$DRY_RUN" ]; then
			echo 
			echo 'Please ensure a UTF-8 locale is configured as the default, e.g. en_NZ.UTF-8...'
			sleep 2
			dpkg-reconfigure locales
		fi
		echo 'Please run this script from within a tmux session.'
		exit 1
	fi
}

setup_software () {
	pkg_install localepurge
	pkg_remove rsyslog
	pkg_install busybox-syslogd
	
	# remove all packages NOT in manifest or not to add later
	if [ -n "$PKG_KEEP" -a -e "$PKG_KEEP" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if ! { grep -q "^$line$" "$PKG_KEEP" || grep -q "^$line$" "$PKG_ADD"; }; then
				pkg_remove "$line"
			fi
		done < /tmp/pkgs.txt
	fi
	
	# add all packages in manifest
	if [ -n "$PKG_ADD" -a -e "$PKG_ADD" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if ! grep -q "^$line$" /tmp/pkgs.txt; then
				pkg_install "$line"
			fi
		done < "$PKG_ADD"
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

setup_disable_root () {
	echo -n "Disabling root password... "
	if [ -n "$DRY_RUN" ]; then
		echo 'DRY RUN'
	else
		passwd -d root
		echo 'OK'
	fi
}

setup_remove_dev_files () {
	if [ -d /usr/local/include -a -n `ls -A /usr/local/include` ]; then
		echo -n "Removing files from /usr/local/include... "
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			rm -rf /usr/local/include/*
			echo 'OK'
		fi
	fi
}

setup_root_dev 
setup_hostname
setup_dns
setup_user
setup_apt
setup_tmux
setup_software
setup_time
setup_expandfs
setup_swap
setup_busybox_links
setup_disable_root
setup_remove_dev_files
check_err
