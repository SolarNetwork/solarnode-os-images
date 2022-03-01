Main() {
	echo "HOWDY! $RELEASE,$LINUXFAMILY,$BOARD"
	case $RELEASE in
		buster)
			if [ -e /tmp/overlay/sn-$BOARD/bin/setup-sn.sh ]; then
				echo "SolarNode setup script discovered at /tmp/overlay/sn-$BOARD/bin/setup-sn.sh"
				export LANG=C LC_ALL="C"
				export DEBIAN_FRONTEND=noninteractive
				/tmp/overlay/sn-$BOARD/bin/setup-sn.sh -a $BOARD \
					-L /dev/null -l /dev/null \
					-i /tmp/overlay/sn-$BOARD \
					-p https://debian.repo.solarnetwork.org.nz
					#-p http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com
				rm -f /root/.not_logged_in_yet
			fi
			;;
		bullseye)
			if [ -e /tmp/overlay/sn-$BOARD/bin/setup-sn.sh ]; then
				echo "SolarNode setup script discovered at /tmp/overlay/sn-$BOARD/bin/setup-sn.sh"
				export LANG=C LC_ALL="C"
				export DEBIAN_FRONTEND=noninteractive
				/tmp/overlay/sn-$BOARD/bin/setup-sn.sh -a $BOARD \
					-L /dev/null -l /dev/null \
					-i /tmp/overlay/sn-$BOARD \
					-M 11 -q bullseye -w -Q \
					-K conf/packages-deb11-add.txt -k conf/packages-deb11-keep.txt \
					-p http://snf-debian-repo-stage.s3-website-us-west-2.amazonaws.com
					#-p https://debian.repo.solarnetwork.org.nz
				rm -f /root/.not_logged_in_yet
			fi
			;;
	esac
} # Main
