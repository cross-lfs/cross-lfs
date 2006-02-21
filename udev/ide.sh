#!/bin/sh
########################################################################
#
# Description : Load ide
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

# calculate device name from bus and drive number
device=${DEVPATH#/devices/*/ide?/}
drive=${device#?.}
bus=${device%.?}
unitnum=$((96 + 1 + $drive + $bus * 2))
name=$(printf "hd\\$(printf '%o' $unitnum)")
procfile="/proc/ide/$name/media"

# wait for /proc file to appear
loop=30
while ! test -e $procfile; do
    sleep 0.1;
    test "$loop" -gt 0 || break
    loop=$(($loop - 1))
done

read media < $procfile
case "$media" in
    cdrom)
	/sbin/modprobe ide-cd
	;;
    disk)
	/sbin/modprobe ide-disk
	;;
    floppy)
	/sbin/modprobe ide-floppy
	;;
    tape)
	/sbin/modprobe ide-tape
	;;
    *)
	/sbin/modprobe ide-generic
	;;
esac
