#!/bin/sh
########################################################################
#
# Description : cdsymlink_helper.sh
#
# Authors     : Jim Gifford
#
# Version     : 00.00
#
# Notes       :
#
########################################################################

. /lib/udev/helper.functions
. /etc/sysconfig/udev_helper

KERN_NAME="$1"

if [ "$KERN_NAME" = "" ]; then
	mesg Bad invocation: \$1 is not set
	exit 1
fi

FILES="`ls /sys/bus/ide/drivers/ide-cdrom | grep 1.`"
	for file in $FILES; do
		TEST="`ls /sys/bus/ide/drivers/ide-cdrom/$file | grep -c $KERN_NAME`"
		if [ "$TEST" = "1" ]; then
			link="`echo $file | cut -f2 -d.`"
			echo $link
			echo "link = $link" >> /tmp/cdrom
		fi
	done
