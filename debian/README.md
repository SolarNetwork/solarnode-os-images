# SolarNode OS (Debian)

This directory contains scripts and support for Debian-based SolarNodeOS images for various 
hardware devices, like the Raspberry Pi.

# Customize script

The [bin/customize.sh](bin/customize.sh) script is the main tool for taking an "upstream" Debian
based operating system image and turning it into SolarNodeOS. It relies on `systemd-nspawn` to
configure the operating system.
