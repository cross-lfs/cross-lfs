#!/bin/bash

pos=0
n=0
sp="$1"
what="$2"
found=0

[ -e /proc/sys/dev/cdrom/info ] || exit 1

/bin/cat /proc/sys/dev/cdrom/info | { 
	while read line; do
		if [ "$found" = "0" -a "${line/drive name:}" != "$line" ]; then
			set ${line/drive name:}	
			while [ $# -gt 0 ]; do
				pos=$[$pos+1]
				if [ "$1" == "$sp" ]; then
					found=1
					break
				fi
				shift
			done
			[ "$found" = "0" ] && exit 1
		elif [ "${line/$what:}" != "$line" ]; then
			set ${line##*$what:}	
			while [ $# -gt 0 ]; do
				n=$[$n+1]
				if [ "$n" == "$pos" ]; then
					if [ "$1" = "1" ]; then
						exit 0
					fi
					break
				fi
				shift
			done
		fi    
	done
exit 1
}
