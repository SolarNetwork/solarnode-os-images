#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

DO_APP_MAIN=""
DRY_RUN=""
PKG_DIR=""
PKG_DOWNLOAD_LIST=""
PKG_DOWNLOAD_USER=""
PKG_DOWNLOAD_NETRC=""
S3_REPO_ACCESS_SECRET=""
S3_REPO_ACCESS_TOKEN=""
S3_REPO_NAME="private-s3"
S3_REPO_REGION="us-east-1"
S3_REPO_SIGN_KEY="conf/private-repo.gpg"
S3_REPO_URL=""
SKIP_REMOVE_OLD_PKGS=""
SNF_PKG_REPO="https://debian.repo.solarnetwork.org.nz"
PKG_DIST="stretch"
UPDATE_PKG_CACHE=""

OLD_HOME="/home/solar"
OLD_CONF="$OLD_HOME/conf"

NEW_HOME="/var/lib/solarnode"
NEW_CONF="/etc/solarnode"

do_help () {
	cat 1>&2 <<EOF
Usage: $0 <arguments> [pkg1,...]

Setup script to migrate an existing SolarNode deploying to one using Debian packages. Pass a list
of Debian packages to install after all configuration is complete.

NOTE: use absolute paths in -d, -r, and -S arguments to avoid errors. Make sure the 
order of packages in -r is the correct order in which things can be installed (i.e. early
packages don't depend on later packages).

Arguments:
 -d <pkg dir>           - path to a directory of *.deb files to install after core packages installed
 -E <s3 token>          - S3 repository access token
 -e <s3 secret>         - S3 repository access secret
 -F <s3 name>           - S3 repository configuration name; defaults to private-s3
 -f <s3 region>         - S3 repository region; defaults to us-east-1
 -G <s3 sign key>       - path to S3 repository signing public GPG key file; defaults to 
                          conf/private-repo.gpg
 -g <s3 url>            - S3 repository URL, for example s3://my-bucket/
 -m                     - migrate the app/main directory
 -n                     - dry run; do not make any actual changes
 -N <dist>              - SNF package repository distribution; defaults to "stretch"
 -P                     - update package cache
 -p <apt repo url>      - the SNF package repository to use; defaults to
                          https://debian.repo.solarnetwork.org.nz;
                          the staging repo can be used instead, which is
                          https://debian.repo.stage.solarnetwork.org.nz;
                          or the staging repo can be accessed directly for development as
                          http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com
 -q                     - do not remove old packages
 -r <url file>          - a file with a list of URLs, one per line, to download into the -d 
                          directory
 -S <netrc file>        - a netrc file to use for authentication with -r
 -s <download username> - a username to use for authentication with -r
EOF
}

while getopts ":d:E:e:F:f:G:g:mnN:Pp:qr:S:s:" opt; do
	case $opt in
		d) PKG_DIR="${OPTARG}";;
		E) S3_REPO_ACCESS_TOKEN="${OPTARG}";;
		e) S3_REPO_ACCESS_SECRET="${OPTARG}";;
		F) S3_REPO_NAME="${OPTARG}";;
		f) S3_REPO_REGION="${OPTARG}";;
		G) S3_REPO_SIGN_KEY="${OPTARG}";;
		g) S3_REPO_URL="${OPTARG}";;
		m) DO_APP_MAIN="1";;
		n) DRY_RUN="1";;
		N) PKG_DIST="${OPTARG}";;
		P) UPDATE_PKG_CACHE='TRUE';;
		p) SNF_PKG_REPO="${OPTARG}";;
		q) SKIP_REMOVE_OLD_PKGS="1" ;;
		r) PKG_DOWNLOAD_LIST="${OPTARG}";;
		S) PKG_DOWNLOAD_NETRC="${OPTARG}";;
		s) PKG_DOWNLOAD_USER="${OPTARG}";;
		*)
			echo "Unknown argument ${OPTARG}"
			do_help
			exit 1
	esac
done

shift $(($OPTIND - 1))

export DEBIAN_FRONTEND=noninteractive

# install package file
pkg_install_file () {	
	echo "Installing package $1..."
	if [ -z "$DRY_RUN" ]; then
		apt-get -qy install --no-install-recommends \
			-o Dpkg::Options::="--force-confdef" \
			-o Dpkg::Options::="--force-confnew" \
			$1
	fi
}

# install package if not already installed
pkg_install () {	
	if dpkg -s $1 >/dev/null 2>/dev/null; then
		echo "Package $1 already installed."
	else
		pkg_install_file "$1"
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

setup_apt () {
	pkg_install apt-transport-https
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
		fi
	fi
}

refresh_pkg_cache () {
	if [ -n "$updated" -o -n "$UPDATE_PKG_CACHE" ]; then
		echo -n "Updating package cache... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			if apt-get -q update >/dev/null 2>&1; then
				echo "OK"
			else
				echo "ERROR: apt-get update failed."
				exit 1
			fi
		fi
	fi
}

setup_apt_s3 () {
	if [ -n "$S3_REPO_ACCESS_SECRET" -a -n "$S3_REPO_ACCESS_TOKEN" -a -n "$S3_REPO_SIGN_KEY" -a -n "$S3_REPO_URL" ]; then
		if [ ! -e "$S3_REPO_SIGN_KEY" ]; then
			echo "ERROR: S3 package repository signing key file [$S3_REPO_SIGN_KEY] not found."
			exit 1
		fi
		
		pkg_install apt-transport-s3
		
		# import repository GPG signing key
		local user="$(gpg "$S3_REPO_SIGN_KEY" 2>/dev/null |grep '^uid' |sed -e 's/uid *//')"
		if apt-key list 2>/dev/null |grep -q "$user" >/dev/null; then
			echo 'S3 package repository GPG key for [$user] already imported.'
		else
			echo -n "Importing S3 package repository GPG key for [$user]... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				cat "$S3_REPO_SIGN_KEY" |apt-key add -
			fi
		fi
		
		# configure S3 repo
		if [ -e "/etc/apt/sources.list.d/${S3_REPO_NAME}.list" ]; then
			echo "S3 package repository [$S3_REPO_NAME] already configured."
		else
			echo -n "Configuring S3 package repository $S3_REPO_NAME... "
			updated=1
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				echo "deb $S3_REPO_URL $PKG_DIST main" > "/etc/apt/sources.list.d/${S3_REPO_NAME}.list"
				
				local cred_file="/etc/apt/s3auth.conf"
				cat /dev/null >"$cred_file"
				chmod 600 "$cred_file"
				echo "AccessKeyId = $S3_REPO_ACCESS_TOKEN" >>"$cred_file"
				echo "SecretAccessKey = $S3_REPO_ACCESS_SECRET" >>"$cred_file"
				echo "Region = $S3_REPO_REGION" >>"$cred_file"
				echo "Token = ''" >>"$cred_file"
				echo "OK"
			fi
		fi
	fi
}

# move_solar_resource src dest
# move src to dest, making sure solar group has write access to dest parent directory;
# if the destination ends with /, then move the contents of src to dest
move_solar_resource () {
	local src="$1"
	local dest="$2"
	local dest_dir="${dest%/*}"
	local move_contents=""
	local move_dest="$dest_dir"
	if [ "${src##*/}" = "" ]; then
		src="${src%/}"
		dest_dir="$dest"
		move_dest="$dest/${src##*/}"
	fi
	if [ "${dest##*/}" = "" ]; then
		move_contents=1
	fi
	if [ -e "$src" ]; then
		if [ ! -d "$dest_dir" ]; then
			echo -n "Creating directory $dest_dir... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				mkdir -p "$dest_dir"
				chgrp solar "$dest_dir"
				chmod 770 "$dest_dir"
				echo "OK"
			fi
		fi
		if [ -n "$move_contents" ]; then
			echo -n "Moving $src/* -> $dest... "
		else
			echo -n "Moving $src -> $dest_dir... "
		fi
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif [ -n "$move_contents" ]; then
			if [ -n "$(ls -1 $src)" ]; then
				mv -n "$src"/* "$dest"
			fi
			echo "OK"
		else
			mv -n "$src" "$dest_dir" && echo "OK"
		fi
	fi
}

migrate_app_main () {
	# migrate app/main JARs, but ONLY if another jar of same bundle ID doesn't
	# already exist in destination
	if [ -d "$OLD_HOME/app/main" -a -d "$NEW_HOME/app/main" ]; then
		ls -1 "$NEW_HOME/app/main/" |cut -d'-' -f 1 >/tmp/app-main-new.list
		local f=
		local bid=
		for f in $(ls -1 "$OLD_HOME/app/main"); do
			bid=${f%-*}
			if grep -q "^$bid"'$' /tmp/app-main-new.list >/dev/null; then
				echo "Plugin $bid exists already in $NEW_HOME/app/main, not moving."
			else
				echo -n "Moving plugin $f -> $NEW_HOME/app/main... "
				if [ -n "$DRY_RUN" ];then
					echo "DRY RUN"
				else
					mv -n "$OLD_HOME/app/main/$f" "$NEW_HOME/app/main"
					echo "OK"
				fi
			fi
		done
	fi
}

backup_old_home () {
	local dest="/var/tmp/migrate-solarpkg-solar-home-backup.tgz"
	if [ -d "$OLD_HOME" ]; then
		if [ -e "$dest" ]; then
			echo "NOT backing up $OLD_HOME because backup exists already at $dest."
		else
			echo -n "Backing up $OLD_HOME to $dest... "
			if [ -n "$DRY_RUN" ]; then
				echo "DRY RUN"
			else
				if tar czf "$dest" -C "$OLD_HOME" .; then
					echo "OK"
				else
					echo "ERROR: $?"
					exit 1
				fi
			fi
		fi
	fi
}

migrate_identity () {
	# migrate identity.json
	move_solar_resource "$OLD_CONF/identity.json" "$NEW_CONF/identity.json"

	# migrate node.jks
	move_solar_resource "$OLD_CONF/tls/node.jks" "$NEW_CONF/tls/node.jks"
}

migrate_settings () {
	# migrate auto-settings.csv
	move_solar_resource "$OLD_CONF/auto-settings.csv" "$NEW_CONF/auto-settings.csv"

	# migrate auto-settings.csv
	move_solar_resource "$OLD_CONF/services" "$NEW_CONF/services/"
}

migrate_data () {
	# migrate database
	move_solar_resource "$OLD_HOME/var/db-bak/" "$NEW_HOME/var"

	# migrate backup settings
	move_solar_resource "$OLD_HOME/var/settings-bak/" "$NEW_HOME/var"

	# migrate backups
	move_solar_resource "$OLD_HOME/var/backups/" "$NEW_HOME/var"
}

remove_old_software () {
	pkg_remove mbpoll
}

setup_software () {
	pkg_install whiptail
	pkg_install sn-solarssh
	pkg_install sn-iptables
	pkg_install sn-osstat
	pkg_install sn-rxtx
	pkg_install sn-solarpkg
	pkg_install sn-solarssh
	pkg_install sn-system
	pkg_install yasdishell
	pkg_install solarnode-base
	pkg_install solarnode-app-core
}

download_custom_packages () {
	if [ -n "$PKG_DOWNLOAD_LIST" ]; then
		if [ ! -e "$PKG_DOWNLOAD_LIST" ]; then
			echo "ERROR: package download list $PKG_DOWNLOAD_LIST not found."
			exit 1
		elif [ -z "$PKG_DIR" ]; then
			echo "ERROR: package directory must be specified to download packages to (-d)."
			exit 1
		elif [ ! -d "$PKG_DIR" ]; then
			echo "ERROR: package directory $PKG_DIR not found."
			exit 1
		fi
		echo -n "Downloading packages from $PKG_DOWNLOAD_LIST to $PKG_DIR..."
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			cd "$PKG_DIR"
			if [ -e "$PKG_DOWNLOAD_NETRC" ]; then
				xargs -t -n 1 curl -s --netrc-file "$PKG_DOWNLOAD_NETRC" -O < "$PKG_DOWNLOAD_LIST" || exit 1
			elif [ -n "$PKG_DOWNLOAD_USER" ]; then
				echo
				echo "Enter package download password if prompted."
				xargs -t -n 1 curl -s -u "$PKG_DOWNLOAD_USER" -O < "$PKG_DOWNLOAD_LIST" || exit 1
			else
				xargs -t -n 1 curl -s -O < "$PKG_DOWNLOAD_LIST" || exit 1
			fi
			cd "$OLDPWD"
			local f=
			for f in $(ls -1tr "$PKG_DIR"/*.deb 2>/dev/null); do
				if ! dpkg -c "$f" >/dev/null; then
					echo "ERROR with downloaded package $f."
					exit 1
				fi
			done
		fi
	fi
}

setup_custom_packages () {
	local f=
	if [ -n "$PKG_DIR" -a -d "$PKG_DIR" ]; then
		for f in $(ls -1tr "$PKG_DIR"/*.deb 2>/dev/null); do
			if ! dpkg -c "$f" >/dev/null; then
				echo "ERROR with downloaded package $f."
				exit 1
			else
				pkg_install_file "$f"
			fi
		done
	fi
}

add_software () {
	local pkg=
	for pkg in "$@"; do
		pkg_install "$pkg"
	done
}

cleanup () {
	# remove old scripts
	echo "Deleting scripts from /usr/share/solarnode that live in /usr/share/solarnode/bin now..."
	if [ -n "$DRY_RUN" ]; then
		find "/usr/share/solarnode" -maxdepth 1 -type f -name '*.sh' -print
	else
		find "/usr/share/solarnode" -maxdepth 1 -type f -name '*.sh' -print -delete
	fi

	# remove old runtime files
	if [ -e "/run/solar/config.ini" ]; then
		echo -n "Deleting /run/solar/config.ini runtime configuration... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -f "/run/solar/config.ini"
			echo "OK"
		fi
	fi

	# remove old runtime db
	if [ -d "/run/solar/db" ]; then
		echo -n "Deleting /run/solar/db runtime data... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "/run/solar/db"
			echo "OK"
		fi
	fi
	
	# remove old app dir
	if [ -d "$OLD_HOME/app" -a -d "$NEW_HOME/app" ]; then
		echo -n "Deleting $OLD_HOME/app that lives in $NEW_HOME/app now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_HOME/app"
			echo "OK"
		fi
	fi

	# remove old lib dir
	if [ -d "$OLD_HOME/lib" ]; then
		echo -n "Deleting $OLD_HOME/lib that lives in /usr/lib now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_HOME/lib"
			echo "OK"
		fi
	fi

	# remove old var dir
	if [ -d "$OLD_HOME/var" -a -d $NEW_HOME/var ]; then
		echo -n "Deleting $OLD_HOME/var that lives in $NEW_HOME/var now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_HOME/var"
			echo "OK"
		fi
	fi
	
	# remove old work dir
	if [ -d "$OLD_HOME/work" ]; then
		echo -n "Deleting $OLD_HOME/work that lives in $NEW_HOME/var/work now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_HOME/work"
			echo "OK"
		fi
	fi
	
	# remove old conf dir
	if [ -d "$OLD_CONF" -a -d "$NEW_CONF" ]; then
		echo -n "Deleting $OLD_CONF that lives in $NEW_CONF now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_CONF"
			echo "OK"
		fi
	fi
	
	# remove old config link
	if [ -L "$OLD_HOME/config" -a -L "$NEW_HOME/config" ]; then
		echo -n "Deleting $OLD_HOME/config link that lives in $NEW_HOME now... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -f "$OLD_HOME/config"
			echo "OK"
		fi
	fi
	
	# remove $HOME/bin dir, replace with link to /var/lib/solarnode/bin
	if [ -d "$OLD_HOME/bin" -a ! -L "$OLD_HOME/bin" -a -d "$NEW_HOME/bin" ]; then
		echo -n "Linking $OLD_HOME/bin -> $NEW_HOME/bin... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		else
			rm -rf "$OLD_HOME/bin"
			ln -s "$NEW_HOME/bin" "$OLD_HOME/bin"
			echo "OK"
		fi
	fi
}

if [ -n "$DRY_RUN" ];then
	systemctl stop solarnode.service >/dev/null 2>&1
fi

backup_old_home
download_custom_packages
if [ -z "$SKIP_REMOVE_OLD_PKGS" ]; then
	remove_old_software
fi
setup_apt
setup_apt_s3
refresh_pkg_cache
migrate_identity
migrate_settings
migrate_data
setup_software
setup_custom_packages
if [ -n "$DO_APP_MAIN" ]; then
	migrate_app_main
else
	echo "NOT migrating $OLD_HOME/app/main to $NEW_HOME/app/main (no -m argument)."
fi
add_software "$@"
cleanup
