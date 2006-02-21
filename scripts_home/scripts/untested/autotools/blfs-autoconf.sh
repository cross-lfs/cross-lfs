#!/bin/bash

DIR=`dirname ${0}`
AUTOCONF_VERS="2.13 2.59"
PATCHES=${DIR}/patches
export PATCHES

for AUTOCONF_VER in ${AUTOCONF_VERS}; do
	echo ${AUTOCONF_VER}
	export AUTOCONF_VER
	$DIR/autoconf.sh
done

# copy wrapper script, probably should put it somewhere other than bin
cp ${DIR}/wrappers/ac-wrapper-3.1.sh /usr/bin/ac-wrapper.sh

for file in auto{conf,header,m4te,reconf,scan,update} ifnames; do
	rm -f /usr/bin/${file}
	ln -sfn ac-wrapper.sh /usr/bin/${file}
done

