#!/bin/sh
########################################################################
#
# Description : network_helper.sh
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

if [ "$INTERFACE" = "" ]; then
	mesg Bad NET invocation: \$INTERFACE is not set
	exit 1
fi

case $ACTION in
	add)
		case $INTERFACE in

		ppp*|ippp*|isdn*|plip*|lo*|irda*|dummy*|ipsec*|tun*|tap*)
			debug_mesg assuming $INTERFACE is already up
			exit 0
		;;

		*)
			export IN_HOTPLUG=1
			exec /etc/sysconfig/network-devices/ifup $INTERFACE
		;;

	esac
	;;

	remove)
		case $INTERFACE in

		ppp*|ippp*|isdn*|plip*|lo*|irda*|dummy*|ipsec*|tun*|tap*)
			debug_mesg assuming $INTERFACE is already up
			exit 0
		;;

		*)
			export IN_HOTPLUG=1
			exec /etc/sysconfig/network-devices/ifdown $INTERFACE
		;;

	esac
	;;

	*)
	exit 1
	;;
esac
