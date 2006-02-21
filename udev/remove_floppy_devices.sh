#!/bin/sh
########################################################################
#
# Description : remove_floppy_devices
#
# Authors     : Based on Open Suse Udev Rules
#               kay.sievers@suse.de
#
# Adapted to  : Jim Gifford
# LFS
#
# Version     : 00.00
#
# Notes       :
#
########################################################################

fdname=$1

for dev in /dev/${fdname}*; do
	rm -f $dev
done
