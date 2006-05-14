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
case $ACTION in
	add)
		if [ -e /dev/cdrom-temp ]; then
			FILES="`ls /sys/bus/ide/drivers/ide-cdrom | grep 1.`"
			for file in $FILES; do
				TEST="`ls /sys/bus/ide/drivers/ide-cdrom/$file | grep -c $KERN_NAME`"
				if [ "$TEST" = "1" ]; then
					link="`echo $file | cut -f2 -d.`"
					if [ -e /dev/cdrom-temp ]; then
						mv /dev/cdrom-temp /dev/cdrom$link
					fi
					if [ -e /dev/cdr-temp ]; then
						mv /dev/cdr-temp /dev/cdr$link
					fi
					if [ -e /dev/cdrw-temp ]; then
						mv /dev/cdrw-temp /dev/cdrw$link
					fi
					if [ -e /dev/dvd-temp ]; then
						mv /dev/dvd-temp /dev/dvd$link
					fi
					if [ -e /dev/dvdr-temp ]; then
						mv /dev/dvdr-temp /dev/dvdr$link
					fi
					if [ -e /dev/dvdrw-temp ]; then
						mv /dev/dvdrw-temp /dev/dvdrw$link
					fi
				fi
			done
		fi
	;;

	remove)
		FILES="`ls /sys/bus/ide/drivers/ide-cdrom | grep 1.`"
		echo "at remove" > /tmp/cdrom
		for file in $FILES; do
			TEST="`find /sys/bus/ide/drivers/ide-cdrom/$file -name $KERN_NAME`"
			if [ "$TEST" != "" ]; then
				link="`echo $file | cut -f2 -d.`"
				rm /dev/cdrom$link /dev/cdr$link /dev/cdrw$link /dev/dvd$link /dev/dvdrw$link
			fi
		done
	;;

	*)
	exit 1
	;;
esac
