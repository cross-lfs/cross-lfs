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
BUS="$2"
test=0

if [ "$KERN_NAME" = "" ]; then
	mesg Bad invocation: \$1 is not set
	exit 1
fi

if [ "$BUS" = "ide" ]; then
	FILES="`ls /sys/bus/ide/drivers/ide-cdrom | grep '\.' `"
		for file in $FILES; do
			TEST="`ls /sys/bus/ide/drivers/ide-cdrom/$file | grep -c $KERN_NAME`"
			if [ "$TEST" = "1" ]; then
				link="`echo $file | cut -f2 -d.`"
				while [ $test -lt 1 ] ; do
					if [ -e /dev/cdrom$link ]; then
						link=$[$link+1]
					else
						test=1
						echo $link
					fi
				done
			fi
		done
fi

if [ "$BUS" = "scsi" ]; then
	link=$KERN_NAME
		while [ $test -lt 1 ] ; do
			if [ -e /dev/cdrom$link ]; then
				link=$[$link+1]
			else
				test=1
				echo $link
			fi
		done
fi

