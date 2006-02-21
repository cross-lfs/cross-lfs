#!/bin/sh
########################################################################
#
# Description : load_ide_modules
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

device=${DEVPATH#/devices/*/ide?/}
drive=${device#?.}
bus=${device%.?}
name=$(printf "hd%x" $(($drive + $bus * 2 + 10)))
procfile="/proc/ide/$name/media"

loop=50
while ! test -e $procfile; do
    sleep 0.1;
    test "$loop" -gt 0 || exit 1
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
