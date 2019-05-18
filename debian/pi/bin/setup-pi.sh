#!/usr/bin/env sh

# NOTE FOR HEADLESS INSTALL: create a /boot/ssh file, and Raspbian will 
# start up the SSH server. Then you can SSh as pi:raspberry.

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DRY_RUN=""
APP_USER="solar"
APP_USER_PASS="solar"
HOSTNAME="solarnode"
PKG_KEEP="packages.txt"
PI_USER="pi"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
VERBOSE=""

LOG="/var/tmp/setup-pi.log"
ERR_LOG="/var/tmp/setup-pi.err"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Arguments:
 -h <hostname>          - the hostname to use; defaults to solarnode
 -k <package list file> - path to list of packages to keep; defaults to packages.txt
 -n                     - dry run; do not make any actual changes
 -R <root dev label>    - the root device label; defaults to SOLARNODE
 -r <root dev>          - the root device; defaults to /dev/mmcblk0p2
 -U <user pass>         - the app user password; defaults to solar
 -u <username>          - the app username to use; defaults to solar
 -V <pi user>           - the pi username to delete; defaults to pi
 -v                     - verbose mode; print out more verbose messages
EOF
}

while getopts ":h:k:nR:r:U:u:V:v" opt; do
	case $opt in
		h) HOSTNAME="${OPTARG}";;
		k) PKG_KEEP="${OPTARG}";;
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
			apt-get -qy install --no-install-recommends $1
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
		echo "Setting hostname to $HOSTNAME..."
		sudo hostnamectl set-hostname "$HOSTNAME"
	fi
}

setup_dns () {
	if grep -q "$HOSTNAME" /etc/hosts; then
		echo "/etc/hosts contains $HOSTNAME already."
	else
		echo "Setting up $HOSTNAME /etc/hosts entry..."
		sed "s/^127.0.0.1[[:space:]]*localhost/127.0.0.1 $HOSTNAME localhost/" /etc/hosts >/tmp/hosts.new
		if diff -q /etc/hosts /tmp/hosts.new >/dev/null; then
			# didn't change anything, try 127.0.1.0
			sed "s/^127.0.1.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts >/tmp/hosts.new
		fi
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

setup_software () {
	pkg_install localepurge
	pkg_remove rsyslog
	pkg_install busybox-syslogd
	pkg_install oracle-java8-jdk
	
	# remove all development packages
	dpkg-query --showformat='${Package}\n' --show |egrep -- '(^g\+\+|^gcc$|^gcc-4|^gcc-5|-dev$)' >/tmp/pkgs.txt
	while IFS= read -r line; do
		pkg_remove "$line"
	done < /tmp/pkgs.txt
	
	# remove all packages NOT in manifest
	if [ -n "$PKG_KEEP" -a -e "$PKG_KEEP" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if grep -q "^$line$" "$PKG_KEEP"; then
				true
			else
				pkg_remove "$line"
			fi
		done < /tmp/pkgs.txt
	fi
}

setup_time () {
	timedatectl set-ntp true
}

setup_root_dev 
setup_hostname
setup_dns
setup_user
setup_software
setup_time
check_err
