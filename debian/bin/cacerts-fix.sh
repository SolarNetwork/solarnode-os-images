#!/bin/sh

# Replace the Oracle JVM cacerts bundle by the OS-provided ca-certificates-java one

if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

if ! dpkg -s ca-certificates-java >/dev/null 2>&1; then
	apt-get -q update && apt-get install ca-certificates-java
fi

if [ ! -e /etc/ssl/certs/java/cacerts ]; then
	echo "Hmm, the /etc/ssl/certs/java/cacerts is missing; cannot continue."
	exit 1
fi

for f in `find /usr/lib/jvm -type f -name cacerts`; do
	echo "Creating link from $f -> /etc/ssl/certs/java/cacerts"
	mv $f $f.bak
	ln -s /etc/ssl/certs/java/cacerts `dirname $f`
done
