#!/bin/bash

### scrollkeeper ###

cd ${SRC}
LOG=scrollkeeper-gnome-desktop.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# override TARBALLS to point at gnome/desktop tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/desktop/${GNOME_REL_MAJ}/${GNOME_REL}/sources

unpack_tarball scrollkeeper-${SCROLLKEEPER_VER}
cd ${PKGDIR}

#######
# TODO: probably should add extra directories to --with-omfdirs...
#######

# Set perl binary to use if multiarch (else intltool component barfs)
export INTLTOOL_PERL="${PERL}"

max_log_init scrollkeeper ${SCROLLKEEPER_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --sysconfdir=/etc --localstatedir=/var --disable-static \
   --with-omfdirs=/usr/share/omf \
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

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/scrollkeeper-config
fi
