#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

APP_USER="solar"
APP_USER_PASS="solar"
APT_PROXY=""
BOARD="raspberrypi"
BOOT_DEV_LABEL="SOLARBOOT"
BOOT_MOUNT="/boot"
DELETE_OLD_KERNELS=""
DRY_RUN=""
EXTRA_SCRIPT_EARLY=""
EXTRA_SCRIPT_LATE=""
HOSTNAME="solarnode"
INPUT_DIR="/tmp/overlay"
PKG_KEEP="conf/setup-packages-keep.txt"
PKG_ADD="conf/setup-packages-add.txt"
PKG_ADD_EARLY="conf/setup-packages-add-early.txt"
PKG_ADD_LATE=""
PKG_DEL_EARLY=""
PKG_DEL_LATE="conf/setup-packages-del-late.txt"
OLD_USER="pi"
RELEASE_NAME="SolarNodeOS"
RELEASE_VERSION="10"
ROOT_DEV="/dev/mmcblk0p2"
ROOT_DEV_LABEL="SOLARNODE"
SKIP_BOOT_CMDLINE=""
SKIP_FS_EXPAND=""
SKIP_SOFTWARE=""
SNF_PKG_REPO="https://debian.repo.solarnetwork.org.nz"
PKG_DIST="buster"
UPDATE_PKG_CACHE=""
UPDATE_PKG_CACHE_START=""
UPGRADE_PKGS=""
VERBOSE=""
WITHOUT_SYSLOG=""
WITHOUT_LOCALEPURGE=""
ZONE=""

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments>

Setup script for a minimal SolarNode OS based on an upstream OS.

Arguments:
 -A <package list file> - path to list of packages to add late in script
 -a <board>             - the board being set up; defaults to raspberrypi
 -B <boot dev label>    - the boot device label; defaults to SOLARBOOT
 -b <boot mount>        - the boot mount path; defaults to /boot
 -c                     - delete outdated kernel packages
 -D <package list file> - path to list of packages to delete early in script
 -d <package list file> - path to list of packages to delete late in script;
                          defaults to conf/setup-packages-del-late.txt
 -e <package list file> - path to list of packages to add early in script;
                          defaults to conf/setup-packages-add-early.txt
 -E                     - skip setting the file system expansion marker
 -G                     - skip modifying /boot/cmdline.txt
 -h <hostname>          - the hostname to use; defaults to solarnode
 -i <input dir>         - path to input configuration directory; defaults
                          to /tmp/overlay
 -K <package list file> - path to list of packages to add;
                          defaults to conf/setup-packages-add.txt
 -k <package list file> - path to list of packages to keep;
                          defaults to conf/setup-packages-keep.txt
 -L <err log path>      - path to error log; defaults to $INPUT_DIR/setup-sn.err
 -l <log path>          - path to error log; defaults to $INPUT_DIR/setup-sn.log
 -M <version>           - version to append to release name; defaults to '10'
 -m                     - upgrade all packages to latest available; pass twice to do a 
                          'dist-upgrade' rather than a plain 'upgrade'
 -N <name>              - release name; defaults to 'SolarNodeOS'
 -n                     - dry run; do not make any actual changes
 -o <proxy>             - host:port of Apt HTTP proxy to use
 -P                     - update package cache
 -p <apt repo url>      - the SNF package repository to use; defaults to
                          https://debian.repo.solarnetwork.org.nz;
                          the staging repo can be used instead, which is
                          https://debian.repo.stage.solarnetwork.org.nz;
                          or the staging repo can be accessed directly for development as
                          http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com
 -Q                     - update apt repositories at start
 -q <pkg dist>          - the package distribution to use; defaults to 'stretch'
 -R <root dev label>    - the root device label; defaults to SOLARNODE
 -r <root dev>          - the root device; defaults to /dev/mmcblk0p2
 -S                     - skip software install
 -U <user pass>         - the app user password; defaults to solar
 -u <username>          - the app username to use; defaults to solar
 -V <old user>          - the old username to delete; defaults to pi
 -v                     - verbose mode; print out more verbose messages
 -W                     - without syslog
 -w                     - wihtout localepurge
 -X <script path>       - execute extra script (early); will be passed -n and -v arguments
 -x <script path>       - execute extra script (late); will be passed -n and -v arguments
 -Z <time zone>         - the time zone to change to image system to
EOF
}

while getopts ":A:a:B:b:cD:d:Ee:Gh:i:K:k:L:l:M:mN:no:Pp:Qq:R:r:SU:u:V:vWwX:x:Z:" opt; do
	case $opt in
		A) PKG_ADD_LATE="${OPTARG}";;
		a) BOARD="${OPTARG}";;
		B) BOOT_DEV_LABEL="${OPTARG}";;
		b) BOOT_MOUNT="${OPTARG}";;
		c) DELETE_OLD_KERNELS='TRUE';;
		D) PKG_DEL_EARLY="${OPTARG}";;
		d) PKG_DEL_LATE="${OPTARG}";;
		e) PKG_ADD_EARLY="${OPTARG}";;
		E) SKIP_FS_EXPAND='TRUE';;
		G) SKIP_BOOT_CMDLINE='TRUE';;
		h) HOSTNAME="${OPTARG}";;
		i) INPUT_DIR="${OPTARG}";;
		K) PKG_ADD="${OPTARG}";;
		k) PKG_KEEP="${OPTARG}";;
		L) ERR_LOG="${OPTARG}";;
		l) LOG="${OPTARG}";;
		M) RELEASE_VERSION="${OPTARG}";;
		m)	if [ -n "$UPGRADE_PKGS" ]; then
				UPGRADE_PKGS='DIST'
			else
				UPGRADE_PKGS='TRUE'
			fi
			;;
		N) RELEASE_NAME="${OPTARG}";;
		n) DRY_RUN='TRUE';;
		o) APT_PROXY="${OPTARG}";;
		P) UPDATE_PKG_CACHE='TRUE';;
		p) SNF_PKG_REPO="${OPTARG}";;
		Q) UPDATE_PKG_CACHE_START='TRUE';;
		q) PKG_DIST="${OPTARG}";;
		R) ROOT_DEV_LABEL="${OPTARG}";;
		r) ROOT_DEV="${OPTARG}";;
		S) SKIP_SOFTWARE='TRUE';;
		U) APP_USER_PASS="${OPTARG}";;
		u) APP_USER="${OPTARG}";;
		V) OLD_USER="${OPTARG}";;
		v) VERBOSE='TRUE';;
		W) WITHOUT_SYSLOG='TRUE';;
		w) WITHOUT_LOCALEPURGE='TRUE';;
		X) EXTRA_SCRIPT_EARLY="${OPTARG}";;
		x) EXTRA_SCRIPT_LATE="${OPTARG}";;
		Z) ZONE="${OPTARG}";;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done
shift $(($OPTIND - 1))

RELEASE_FULLNAME="$RELEASE_NAME $RELEASE_VERSION"

if [ -z "$LOG" ]; then
	LOG="$INPUT_DIR/setup-sn.log"
fi
if [ -z "$ERR_LOG" ]; then
	ERR_LOG="$INPUT_DIR/setup-sn.err"
fi

# clear error log
cat /dev/null >$ERR_LOG
cat /dev/null >$LOG

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

apt_proxy=""
if [ -n "$APT_PROXY" ]; then
	apt_proxy="-o Acquire::http::Proxy=http://${APT_PROXY}"
fi

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
		if ! apt-get --reinstall install -qy \
				-o Dpkg::Options::="--force-confdef" \
				-o Dpkg::Options::="--force-confnew" \
				${apt_proxy} \
				--no-install-recommends \
				"$@" >>$LOG 2>>$ERR_LOG; then
			echo "Error installing package(s) $@"
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
		if apt-get -qy remove --purge $@ >>$LOG 2>>$ERR_LOG; then
			echo "OK"
		else
			echo "Error removing packages!"
			exit 1
		fi
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
		echo -n "Removing auto-installed packages no longer needed... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			apt-get -qy autoremove --purge $1 >>$LOG 2>>$ERR_LOG && echo "OK"
		fi
	fi
}

# upgrade  all packages
pkg_upgrade () {
	local cmd='upgrade'
	if [ "$1" = 'DIST' ]; then
		cmd='dist-upgrade'
	fi
	echo -n "Upgrading all packages with '$cmd'... "
	if [ -n "$DRY_RUN" ]; then
		echo 'DRY RUN'
	else
		if ! apt-get -qy $cmd \
			${apt_proxy} \
			--no-install-recommends \
			>>$LOG 2>>$ERR_LOG; then
			echo 'ERROR'
			exit 1
		else
			echo 'OK'
		fi
	fi
}

# update-initramfs failing in Debian 12 when MODULES=most not configured
setup_initramfs () {
	if [ -d /etc/initramfs-tools/conf.d ]; then
		local sn_conf="/etc/initramfs-tools/conf.d/solarnode.conf"
		if [ ! -e "$sn_conf" ]; then
			if grep -q "MODULES=dep" /etc/initramfs-tools/initramfs.conf; then
				echo "Adding MODULES=most initramfs configuration to $sn_conf..."
				echo 'MODULES=most' >"$sn_conf"
			fi
		fi
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
	elif grep -q "$BOARD" /etc/hosts; then
		echo -n "Replacing $BOARD with $HOSTNAME in /etc/hosts... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			sed -i "s/$BOARD/$HOSTNAME/" /etc/hosts 2>>$ERR_LOG && echo "OK" || echo "ERROR"
		fi
	elif grep -q '127.0.1.1' /etc/hosts; then
		echo -n "Replacing 127.0.1.1 with $HOSTNAME in /etc/hosts... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			sed -i '/127.0.1.1/c 127.0.1.1\t'"$HOSTNAME" /etc/hosts 2>>$ERR_LOG && echo "OK" || echo "ERROR"
		fi
	else
		echo -n "Adding $HOSTNAME to /etc/hosts... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			echo '127.0.1.1\t'"$HOSTNAME" >>/etc/hosts 2>>$ERR_LOG && echo "OK" || echo "ERROR"
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
	if id "$OLD_USER" >/dev/null 2>&1; then
		echo -n "Deleting user $OLD_USER..."
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			killall -u $OLD_USER
			deluser "$OLD_USER" >/dev/null 2>>$ERR_LOG && echo "OK" || {
				echo "ERROR"
				echo "You might need to log out, then back in as the $APP_USER user to continue."
				exit 1; }
			if [ -d /home/"$OLD_USER" ]; then
				rm -rf /home/"$OLD_USER"
			fi
		fi
	else
		echo "User $OLD_USER already removed."
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
				passwd -l root >/dev/null 2>>$ERR_LOG && echo "OK" || echo "ERROR"
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

remove_apt_repos () {
	for n in "$@"; do
		if [ -e /etc/apt/sources.list.d/$n.list ]; then
			echo -n "Removing package repository [$n]... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				rm /etc/apt/sources.list.d/$n.list
				echo "OK"
			fi
		fi
	done
}

pkg_set_arch () {
	for f in $(dpkg --print-foreign-architectures); do
		echo -n "Disabling foreign architecture $f... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			dpkg --remove-architecture $f 2>>$ERR_LOG
			echo "OK"
		fi
	done
}

setup_apt () {
	local ver=0
	pkg_set_arch
	if [ -e /etc/debian_version ]; then
		ver="$(cat /etc/debian_version |sed 's/\..*$//')"
	fi
	if [ $ver -gt 10 ]; then
		if [ -e /etc/apt/keyrings/solarnetwork.gpg ]; then
			echo 'SNF package repository GPG key already saved.'
		else
			echo -n 'Saving SNF package repository GPG key... '
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				pkg_install curl >/dev/null
				pkg_install gnupg >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -s "$SNF_PKG_REPO/KEY.gpg" |gpg --dearmor 2>/dev/null \
					|tee /etc/apt/keyrings/solarnetwork.gpg >/dev/null
				echo "OK"
			fi
		fi
	else
		if apt-key list 2>/dev/null |grep -q "packaging@solarnetwork.org.nz" >/dev/null; then
			echo 'SNF package repository GPG key already imported.'
		else
			echo -n 'Importing SNF package repository GPG key... '
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				pkg_install curl >/dev/null
				pkg_install gnupg >/dev/null
				curl -s "$SNF_PKG_REPO/KEY.gpg" |apt-key add -
			fi
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
		elif [ $ver -gt 10 ]; then
			echo "deb [signed-by=/etc/apt/keyrings/solarnetwork.gpg] $SNF_PKG_REPO $PKG_DIST main" >/etc/apt/sources.list.d/solarnetwork.list
		else
			echo "deb $SNF_PKG_REPO $PKG_DIST main" >/etc/apt/sources.list.d/solarnetwork.list
		fi
		echo "OK"
		case $SNF_PKG_REPO in https*)
			pkg_install apt-transport-https
		esac
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

	# Remove some extra repos possible present in distros like Armbian
	remove_apt_repos box86 nala

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

setup_systemd () {
	# cap /var/log/journal to 10M
	if grep -q '^SystemMaxUse=10M' /etc/systemd/journald.conf >/dev/null; then
		true
	else
		echo -n 'Configuring SystemMaxUse in /etc/systemd/journald.conf; will be active on reboot... '
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			if grep -q 'SystemMaxUse' /etc/systemd/journald.conf; then
				# update
				sed -i -e '/SystemMaxUse/c SystemMaxUse=10M' /etc/systemd/journald.conf || true
			else
				# add in
				echo 'SystemMaxUse=10M' >>/etc/systemd/journald.conf
			fi
			echo 'OK'
		fi
	fi
	if [ -d /var/log/journal ]; then
		echo -n 'Removing persistent journald storage /var/log/journal... '
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			if rm -rf /var/log/journal >/dev/null 2>>$ERR_LOG; then
				echo 'OK'
			else
				echo 'ERROR'
			fi
		fi
	fi
}

setup_zone () {
	if [ -n "$ZONE" ]; then
		if [ -e /etc/timezone ]; then
			local curr_zone="$(cat /etc/timezone)"
			if [ "$ZONE" != "$curr_zone" ]; then
				echo -n "Changing system time zone from $curr_zone to $ZONE... "
				if [ -n "$DRY_RUN" ]; then
					echo "DRY RUN"
				else
					echo "$ZONE" >/etc/timezone
					echo "OK"
				fi
			fi
		fi
		if [ -n "$DRY_RUN" ]; then
			ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
		fi
	fi
}

setup_software_early () {
	# delete all packages in delete-early manifest
	if [ -n "$PKG_DEL_EARLY" -a -e "$INPUT_DIR/$PKG_DEL_EARLY" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if grep -q "^$line$" /tmp/pkgs.txt; then
				pkg_remove "$line"
			fi
		done < "$INPUT_DIR/$PKG_DEL_EARLY"
	elif [ -n "$PKG_DEL_EARLY" ]; then
		echo "-D option provided but [$INPUT_DIR/$PKG_DEL_EARLY] file not available."
		exit 1
	fi

	if [ -n "$UPDATE_PKG_CACHE_START" ]; then
		echo -n "Updating package cache... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			apt-get -q update >>$LOG 2>>$ERR_LOG
			echo "OK"
		fi
	fi
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

upgrade_software () {
	if [ -n "$UPGRADE_PKGS" ]; then
		pkg_upgrade $UPGRADE_PKGS
		if [ -z "$DRY_RUN" ]; then
			apt-get clean
		fi
	fi
}

backup_resolvconf () {
	if [ -f /etc/resolv.conf ]; then
		echo -n "Backing up /etc/resolv.conf... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			cp -a /etc/resolv.conf /etc/resolv.conf.sn-setup-bak
			echo "OK"
		fi
	fi
}

tmprestore_resolvconf () {
	if [ -f /etc/resolv.conf.sn-setup-bak ]; then
		echo -n "Temporarily restoring /etc/resolv.conf... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			mv /etc/resolv.conf /etc/resolv.conf.sn-setup-tmp-bak
			cp -a /etc/resolv.conf.sn-setup-bak /etc/resolv.conf
			echo "OK"
		fi
	fi
}

restore_resolvconf () {
	local src=""
	if [ -e /etc/resolv.conf.sn-setup-tmp-bak -o -L /etc/resolv.conf.sn-setup-tmp-bak ]; then
		src="/etc/resolv.conf.sn-setup-tmp-bak"
	elif [ -e /etc/resolv.conf.sn-setup-bak -o -L /etc/resolv.conf.sn-setup-bak ]; then
		src="/etc/resolv.conf.sn-setup-bak" 
	fi
	if [ -n "$src" ]; then
		echo -n "Restoring $src to /etc/resolv.conf... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -f /etc/resolv.conf
			mv "$src" /etc/resolv.conf
			rm -f /etc/resolv.conf.sn-setup-bak
			echo "OK"
		fi
	fi
	# if a package (like sn-system) created a symlink for /etc/resolv.conf
	# then remove sn-cust-bak if exists
	if [ -L /etc/resolv.conf -a \( -e /etc/resolv.conf.sn-cust-bak -o -L /etc/resolv.conf.sn-cust-bak \) ]; then
		echo -n "Removing /etc/resolv.conf.sn-cust-bak to preserve /etc/resolv.conf... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -f /etc/resolv.conf.sn-cust-bak
			echo "OK"
		fi
	fi
}

setup_software () {
	[ -z "$WITHOUT_LOCALEPURGE" ] && pkg_install localepurge
	pkg_remove rsyslog
	[ -z "$WITHOUT_SYSLOG" ] && pkg_install busybox-syslogd

	# remove all packages NOT in manifest or not to add later and NOT starting with linux- (kernel)
	if [ -n "$PKG_KEEP" -a -e "$INPUT_DIR/$PKG_KEEP" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		local to_remove=""
		while IFS= read -r line; do
			if ! { grep -q "^$line$" "$INPUT_DIR/$PKG_KEEP" || grep -q "^$line$" "$INPUT_DIR/$PKG_ADD"; }; then
				case $line in
					linux-*)
						# skip this
						;;
					*)
						to_remove="$to_remove $line"
						;;
				esac
			fi
		done < /tmp/pkgs.txt
		if [ -n "$to_remove" ]; then
			pkgs_remove $to_remove
		fi
	elif [ -n "$PKG_KEEP" -a ! -e "$INPUT_DIR/$PKG_KEEP" ]; then
		echo "Warning: $INPUT_DIR/$PKG_KEEP file not found!"
	fi

	# upgrade now, before install SN packages which overwrite /etc/resolv.conf
	upgrade_software

	# add all packages in manifest
	if [ -n "$PKG_ADD" -a -e "$INPUT_DIR/$PKG_ADD" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		local to_add=""
		while IFS= read -r line; do
			to_add="$to_add $line"
		done < "$INPUT_DIR/$PKG_ADD"
		if [ -n "$to_add" ]; then
			pkgs_install $to_add
		fi
	elif [ -n "$PKG_ADD" -a ! -e "$INPUT_DIR/$PKG_ADD" ]; then
		echo "Warning: $INPUT_DIR/$PKG_ADD file not found!"
	fi

	apt-get clean
}

setup_software_late () {
	# delete all packages in manifest
	if [ -n "$PKG_DEL_LATE" -a -e "$INPUT_DIR/$PKG_DEL_LATE" ]; then
		dpkg-query --showformat='${Package}\n' --show >/tmp/pkgs.txt
		while IFS= read -r line; do
			if grep -q "^$line$" /tmp/pkgs.txt; then
				pkg_remove "$line"
			fi
		done < "$INPUT_DIR/$PKG_DEL_LATE"
	fi

	pkg_autoremove
	
	if [ -n "$PKG_ADD_LATE" -a -e "$INPUT_DIR/$PKG_ADD_LATE" ]; then
		local to_add=""
		while IFS= read -r line; do
			to_add="$to_add $line"
		done < "$INPUT_DIR/$PKG_ADD_LATE"
		if [ -n "$to_add" ]; then
			pkgs_install $to_add
		fi
	fi
	
	if [ -z "$DRY_RUN" ]; then
		apt-get clean
	fi
}

setup_time () {
	echo -n 'Enabling NTP... '
	if [ -n "$DRY_RUN" ]; then
		echo 'DRY RUN'
	else
		timedatectl set-ntp true >>$LOG 2>>$ERR_LOG
		echo 'OK'
	fi
}

setup_expandfs () {
	# the sn-expandfs service will look for this file on boot, and expand the root fs
	if [ -e $BOOT_MOUNT/sn-expandfs ]; then
		echo "Boot time filesystem expand marker $BOOT_MOUNT/sn-expandfs already available."
	else
		echo -n "Creating boot time filesystem expand marker $BOOT_MOUNT/sn-expandfs... "
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			if touch $BOOT_MOUNT/sn-expandfs; then
				echo 'OK'
			else
				echo 'ERROR'
			fi
		fi
	fi
	
	if [ -L /etc/systemd/system/basic.target.wants/armbian-resize-filesystem.service ]; then
		echo -n 'Disabling Armbian filesystem expand service... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			if rm /etc/systemd/system/basic.target.wants/armbian-resize-filesystem.service; then
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
	if ! grep "$RELEASE_FULLNAME" /etc/issue >/dev/null 2>&1; then
		echo -n 'Setting /etc/issue release name... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			sed -n -i '1h;2,$H;${g;s/[^\\]*\\/'"$RELEASE_FULLNAME"' \\/;p}' /etc/issue
			echo 'OK'
		fi
	fi
	if ! grep "$RELEASE_FULLNAME" /etc/issue.net >/dev/null 2>&1; then
		echo -n 'Setting /etc/issue.net release name... '
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			echo -n "$RELEASE_FULLNAME" >/etc/issue.net
			echo 'OK'
		fi
	fi
}

append_boot_cmdline () {
	if [ -e $BOOT_MOUNT/cmdline.txt ]; then
		if grep -q "$1" $BOOT_MOUNT/cmdline.txt; then
			echo "$1 configured in $BOOT_MOUNT/cmdline.txt already."
		else
			echo -n "Adding $1 to $BOOT_MOUNT/cmdline.txt... "
			if [ -n "$DRY_RUN" ]; then
				echo 'DRY RUN'
			else
				sed -i '1s/$/ '"$1"'/' $BOOT_MOUNT/cmdline.txt && echo "OK" || echo "ERROR"
			fi
		fi
	fi
}
	

setup_boot_cmdline () {
	if [ -z "$SKIP_BOOT_CMDLINE" ]; then
		append_boot_cmdline 'logo.nologo'
		append_boot_cmdline 'quiet'
		
		# remove upstream init if provided
		if grep -q 'init=' $BOOT_MOUNT/cmdline.txt; then
			echo -n "Removing init= from $BOOT_MOUNT/cmdline.txt... "
			if [ -n "$DRY_RUN" ]; then
				echo 'DRY RUN'
			else
				sed -i 's/init=[^ ][^ ]*[ 	]//' $BOOT_MOUNT/cmdline.txt && echo "OK" || echo "ERROR"
			fi
		fi
	fi
}

setup_ssh () {
	if ! systemctl is-active ssh >/dev/null 2>&1; then
		echo -n "Enabling ssh... "
		if [ -n "$DRY_RUN" ]; then
			echo 'DRY RUN'
		else
			systemctl enable ssh >/dev/null && echo 'OK' || echo 'ERROR'
		fi
	fi
}

extra_script () {
	local s="$1"
	if [ -n "$s" -a -e "$INPUT_DIR/$s" ]; then
		local argn=""
		local argv=""
		if [ -n "$DRY_RUN" ]; then
			argn="-n"
		fi
		if [ -n "$VERBOSE" ]; then
			argv="-v"
		fi
		sh "$INPUT_DIR/$s" $argn $argv
	elif [ -n "$s" ]; then
		echo "Error: extra script [$INPUT_DIR/$s] not available."
		exit 1
	fi
}

delete_old_kernels () {
	# extract all kernel package version numbers, e.g. linux-image-1.2.3 -> 1.2.3, omit 
	dpkg-query -Wf '${Package}\n' linux-image-\* |awk 'BEGIN {FS="-"} $3~/^[[:digit:]]/ {print $3}' \
		|sort |uniq |head -1 >/tmp/old-kernel-versions.txt
	dpkg-query -Wf '${Package}\n' linux-image-* >/tmp/all-kernel-versions.txt
	local to_remove=""
	local ver=""
	while IFS= read -r line; do
		ver="$(echo $line |awk 'BEGIN {FS="-"} $3~/^[[:digit:]]/ {print $3}')"
		if [ -n "$ver" ]; then
			if grep -q "^$ver$" /tmp/old-kernel-versions.txt; then
				to_remove="$to_remove $line"
			fi
		fi
	done </tmp/all-kernel-versions.txt
	if [ -n "$to_remove" ]; then
		pkgs_remove $to_remove
	fi
	rm -f /tmp/old-kernel-versions.txt
	rm -f /tmp/all-kernel-versions.txt
}

backup_resolvconf
extra_script "$EXTRA_SCRIPT_EARLY"
setup_initramfs
setup_software_early
setup_hostname
setup_dns
setup_user
setup_systemd
setup_zone
setup_apt
if [ -z "$SKIP_SOFTWARE" ]; then
	setup_software
	tmprestore_resolvconf
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
setup_boot_cmdline
setup_issue
if [ -z "$SKIP_SOFTWARE" ]; then
	setup_software_late
fi
if [ -n "$DELETE_OLD_KERNELS" ]; then
	delete_old_kernels
fi
setup_ssh
extra_script "$EXTRA_SCRIPT_LATE"
restore_resolvconf
check_err
