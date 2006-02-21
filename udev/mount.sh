#!/bin/sh
########################################################################
#
# Description : Input devices
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
. /etc/sysconfig/storage

test "$HOTPLUG_MOUNT_FSTAB" != yes && exit

# Handle only partitions of sd
case "$DEVNAME" in
	/dev/sd*|/dev/hd*) : ;;
	*) exit 0 ;;
esac
case "$DEVNAME" in
	*sd[a-z]|*hd[a-z]) exit 0 ;;
esac

NODES=$DEVNAME
for sl in `udevinfo -q symlink -p $DEVPATH`; do
	NODES="$NODES /dev/$sl"
done
boot_mesg "Avilable nodes: $NODES"

NODE=
declare -i FSCK=0
while read dn mp fs opts dump fsck x; do
	for n in $NODES; do
		if [ "$n" == "$dn" ] ; then
			case $opts in
				*hotplug*) : ;;
				*) exit 0 ;;
			esac
			NODE="$n"
			FSCK="$fsck"
			boot_mesg "matching line for $DEVNAME:"
			boot_mesg "$dn $mp $fs $opts $dump $fsck $x"
			break 2
		fi
	done
done < /etc/fstab

if [ "$HOTPLUG_CHECK_FILESYSTEMS" == yes -a "$FSCK" -gt 0 ] ; then
	MESSAGE="`fsck -a $DEVNAME`"
	RET=$?
	boot_mesg "$MESSAGE"
	case $RET in
		0|1) : ;;
		2|3) 
			boot_mesg "Please unplug device $DEVNAME, and plug it again" 
			logger -t $0 "fsck for '$DEVNAME' failed. Will not mount it."
			exit 0
			;;
		*) 
			err_mesg "fsck failed on $DEVNAME. Please fsck filesystem manually." 
			logger -t $0 "fsck for '$DEVNAME' failed. Will not mount it."
			exit 1
			;;
	esac
fi


if [ -n "$NODE" ] ; then
	MESSAGE="`mount -av "$NODE"`"
	test $? != 0 && logger -t $0 "Could not mount '$DEVNAME'."
	boot_mesg "$MESSAGE"
fi
