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

input_join_words() {
    local array="$1" tmp
    [ "$array" ] || return 0

    set $array
    tmp="$1"
    shift
    while [ "$#" -gt 0 ]; do
	tmp="$tmp:$1"
	shift
    done

    echo "$tmp"
}

input_convert_vars() {
    i_bustype=0; i_vendor=0; i_product=0; i_version=0; i_evBits=0

    if [ "$PRODUCT" ]; then
	set -- $(IFS='/'; echo $PRODUCT '')
	i_bustype=$((0x$1))
	i_vendor=$((0x$2))
	i_product=$((0x$3))
	[ "$4" ] && i_version=$((0x$4)) # XXX
    fi

    [ "$EV" ] && i_evBits=$((0x$EV))

    i_keyBits=$(input_join_words "$KEY")
    i_relBits=$(input_join_words "$REL")
    i_absBits=$(input_join_words "$ABS")
    i_mscBits=$(input_join_words "$MSC")
    i_ledBits=$(input_join_words "$LED")
    i_sndBits=$(input_join_words "$SND")
    i_ffBits=$( input_join_words "$FF")
}

input_match_bits() {
    local mod_bits="$1" dev_bits="$2"
    [ "$dev_bits" ] || return 0

    local mword dword
    mword=$((0x${mod_bits##*:}))
    dword=$((0x${dev_bits##*:}))

    while true; do
	if [ $(( $mword & $dword != $mword )) -eq 1 ]; then
	    return 1
	fi

	mod_bits=${mod_bits%:*}
	dev_bits=${dev_bits%:*}

	case "$mod_bits-$dev_bits" in
	    *:*-*:*)		continue ;;
	    *:*-*|*-*:*)	return 0 ;;
	    *)			return 1 ;;
	esac
    done
}

load_drivers() {
    local TYPE="$1" FILENAME="$2"

    ${TYPE}_map_modules < $FILENAME

    for MODULE in $DRIVERS; do
	/sbin/modprobe $MODULE || true
    done
}

input_map_modules() {
    local line module
    local relBits mscBits ledBits sndBits keyBits absBits ffBits

    while read line; do
	# comments are lines that start with "#" ...
	# be careful, they still get parsed by bash!
	case "$line" in
	\#*) continue ;;
	esac

	set $line

	module="$1"
	matchBits=$(($2))

	bustype=$(($3))
	vendor=$(($4))
	product=$(($5))
	version=$(($6))

	evBits="$7"
	keyBits="$8"
	relBits="$9"

	shift 9
	absBits="$1"
	cbsBits="$2"
	ledBits="$3"
	sndBits="$4"
	ffBits="$5"
	driverInfo=$(($6))

	if [ $INPUT_DEVICE_ID_MATCH_BUS -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_BUS )) ] && 
		[ $bustype -ne $i_bustype ]; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_VENDOR -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_VENDOR )) ] && 
		[ $vendor -ne $i_vendor ]; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_PRODUCT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_PRODUCT )) ] && 
		[ $product -ne $i_product ]; then
	    continue
	fi

	# version i_version $i_version < version $version
	if [ $INPUT_DEVICE_ID_MATCH_VERSION -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_VERSION )) ] && 
		[ $version -ge $i_version ]; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_EVBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_EVBIT )) ] && 
		input_match_bits "$evBits" "$i_evBits"; then
	    continue
	fi
	if [ $INPUT_DEVICE_ID_MATCH_KEYBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_KEYBIT )) ] && 
		input_match_bits "$keyBits" "$i_keyBits"; then
	    continue
	fi
	if [ $INPUT_DEVICE_ID_MATCH_RELBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_RELBIT )) ] && 
		input_match_bits "$relBits" "$i_relBits"; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_ABSBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_ABSBIT )) ] && 
		input_match_bits "$absBits" "$i_absBits"; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_MSCBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_MSCBIT )) ] && 
		input_match_bits "$mscBits" "$i_mscBits"; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_LEDBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_LEDBIT )) ] && 
		input_match_bits "$ledBits" "$i_ledBits"; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_SNDBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_SNDBIT )) ] && 
		input_match_bits "$sndBits" "$i_sndBits"; then
	    continue
	fi

	if [ $INPUT_DEVICE_ID_MATCH_FFBIT -eq $(( $matchBits & $INPUT_DEVICE_ID_MATCH_FFBIT )) ] && 
		input_match_bits "$ffBits" "$i_ffBits"; then
	    continue
	fi

	if [ $matchBits -eq 0 -a $driverInfo -eq 0 ]; then
		continue
	fi

	# It was a match!
	case " $DRIVERS " in
	    *" $module "*)
		: already found
	    ;;
	    *)
		DRIVERS="$module $DRIVERS"
	    ;;
	esac

    done
}

INPUT_DEVICE_ID_MATCH_BUS=1
INPUT_DEVICE_ID_MATCH_VENDOR=2
INPUT_DEVICE_ID_MATCH_PRODUCT=4
INPUT_DEVICE_ID_MATCH_VERSION=8
INPUT_DEVICE_ID_MATCH_EVBIT=$((0x010))
INPUT_DEVICE_ID_MATCH_KEYBIT=$((0x020))
INPUT_DEVICE_ID_MATCH_RELBIT=$((0x040))
INPUT_DEVICE_ID_MATCH_ABSBIT=$((0x080))
INPUT_DEVICE_ID_MATCH_MSCBIT=$((0x100))
INPUT_DEVICE_ID_MATCH_LEDBIT=$((0x200))
INPUT_DEVICE_ID_MATCH_SNDBIT=$((0x400))
INPUT_DEVICE_ID_MATCH_FFBIT=$((0x800))

MAP_CURRENT="/lib/modules/$(uname -r)/modules.inputmap"
[ -r $MAP_CURRENT ] || exit 0

input_convert_vars
load_drivers input $MAP_CURRENT

exit 0
