#!/bin/bash

### intltool ###

cd ${SRC}
LOG=intltool-gnome-platform.log

set_libdirname
# Set perl binary to use if multiarch...
if [ "${MULTIARCH}" = "Y" ]; then
   export PERL="/usr/bin/perl-${BUILDENV}"
fi

# override TARBALLS to point at gnome/platform tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/platform/${GNOME_REL_MAJ}/${GNOME_REL}/sources

unpack_tarball intltool-${INTLTOOL_VER}
cd ${PKGDIR}

max_log_init intltool ${INTLTOOL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

