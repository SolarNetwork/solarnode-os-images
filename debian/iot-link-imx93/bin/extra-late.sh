#!/usr/bin/env sh

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

MOBILE_CONF_FILE="/etc/default/sn-mobile-usb-wwan"
AT_INIT_FILE="/usr/local/etc/sn-mobile-usb-wwan-init"
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

if [ -e /etc/profile.d/resize.sh ]; then
	echo -n "Removing base profile script /etc/profile.d/resize.sh... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	else
		rm -f /etc/profile.d/resize.sh
		echo "OK"
	fi
fi

# remove "Default User" lines from /etc/issue*
for f in /etc/issue /etc/issue.net; do
	if grep -q '^Default User' $f 2>/dev/null; then
		echo -n "Removing 'Default User' from $f... "
		if [ -n "$DRY_RUN" ]; then
			echo "DRY RUN"
		elif sed -i -e '/^Default User/d' $f; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
done

# bump up JVM memory
if [ ! -e /etc/solarnode/env.conf ]; then
	echo -n 'Increasing SolarNode RAM allocation in /etc/solarnode/env.conf... '
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	else
		tee /etc/solarnode/env.conf <<'EOF'
JAVA_OPTS=-Xmx512m \
	-XX:+ExitOnOutOfMemoryError \
	-XX:MaxMetaspaceSize=256m \
	-Djava.security.egd=file:/dev/./urandom \
	-Djavax.xml.bind.JAXBContextFactory=com.sun.xml.bind.v2.ContextFactory \
	-Djava.net.preferIPv4Stack=true
EOF
	fi
fi

# fix "ping" to work for non-root users
if [ -n "$DRY_RUN" ]; then
	dpkg-reconfigure iputils-ping
fi

# cl-deploy will fail if the /boot/grub directory does not exist
if [ ! -d /boot/grub ]; then
	echo -n "Creating /boot/grub directory... "
	if [ -n "$DRY_RUN" ]; then
		echo "DRY RUN"
	elif mkdir /boot/grub; then
		echo "OK"
	else
		echo "ERROR"
	fi
fi

# configure sn-mobile-usb-wwan init, even though package not installed by default
echo "Generating default $AT_INIT_FILE for sn-mobile-usb-wwan package"
cat <<- EOF > "$AT_INIT_FILE"
	AT+DIALMODE=0
	AT\$MYCONFIG="USBNETMODE",1
	AT+USBNETIP=1
	AT+CGDCONT=1,"IP","\$MOBILE_APN"
EOF

echo "Configuring sn-mobile-mm settings in $MOBILE_CONF_FILE"
echo "AT_INIT_FILE=$AT_INIT_FILE" |tee -a "$MOBILE_CONF_FILE"
echo "AUTO_RECONNECT_ENABLE=1" |tee -a "$MOBILE_CONF_FILE"
echo "MOBILE_APN=internet" |tee -a "$MOBILE_CONF_FILE"
echo "MOBILE_RESET_HOOK=/usr/share/solarnode/bin/iotlink-imx93-mobile-reset.sh" |tee -a "$MOBILE_CONF_FILE"

