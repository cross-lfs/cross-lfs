#!/bin/bash

DIR=`dirname ${0}`
AUTOCONF_VERS="2.13 2.59"
AUTOMAKE_VERS="1.4-p6 1.5 1.6.3 1.7.9 1.8.5 1.9.6"
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

# Create dir for latest GNU config.sub and config.guess
mkdir -p /usr/share/gnu-config-files
cp ${DIR}/gnu-config-files/config.{sub,guess} /usr/share/gnu-config-files
chmod 755 /usr/share/gnu-config-files/*

for AUTOMAKE_VER in ${AUTOMAKE_VERS}; do
	echo ${AUTOMAKE_VER}
	export AUTOMAKE_VER
	$DIR/automake.sh
done

# copy wrapper script, probably should put it somewhere other than bin
cp ${DIR}/wrappers/am-wrapper-1.sh /usr/bin/am-wrapper.sh
chmod 755 /usr/bin/am-wrapper.sh

for file in aclocal automake ; do
	rm -f /usr/bin/${file}
	ln -sfn am-wrapper.sh /usr/bin/${file}
done

if [ "${MULTIARCH}" = "Y" ]; then
   
$DIR/libtool.sh
