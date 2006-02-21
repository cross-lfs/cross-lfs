#!/bin/bash

# Temporary KDE setup script... this to be controlled via a wrapper

mkdir -p /opt/kde-${KDE_VER}

export KDE_PREFIX=/opt/kde-${KDE_MAJ}

export PATH=${PATH}:${KDE_PREFIX}/bin
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${KDE_PREFIX}/lib/pkgconfig

grep ${KDE_PREFIX}/${libdir} /etc/ld.so.conf > /dev/null 2>&1 ||
   echo "${KDE_PREFIX}/${libdir}" >> /etc/ld.so.conf

grep ${KDE_PREFIX}/man /etc/man.conf > /dev/null 2>&1 ||
echo "${KDE_PREFIX}/man" >> /etc/man.conf

if [ -z ${XDG_DATA_DIRS} ]; then
   export XDG_DATA_DIRS=/usr/share:${KDE_PREFIX}/share
else
   export XDG_DATA_DIRS=${XDG_DATA_DIRS}:${KDE_PREFIX}/share
fi
