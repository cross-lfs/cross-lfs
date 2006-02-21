#!/bin/sh
########################################################################
#
# Description : Firmware Script
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

. /etc/sysconfig/rc
. ${rc_functions}

FIRMWARE_DIRS="/lib/firmware"

if [ ! -e /sys/$DEVPATH/loading ]; then
    boot_mesg "firmware loader misses sysfs directory"
    exit 0
fi

for DIR in $FIRMWARE_DIRS; do
    [ -e "$DIR/$FIRMWARE" ] || continue
    boot_mesg "loading $DIR/$FIRMWARE"
    echo 1 > /sys/$DEVPATH/loading
    cat "$DIR/$FIRMWARE" > /sys/$DEVPATH/data
    echo 0 > /sys/$DEVPATH/loading
    exit
done

echo -1 > /sys/$DEVPATH/loading
boot_mesg "Cannot find  firmware file '$FIRMWARE'"
exit 1
