#!/bin/bash

### gail ###

cd ${SRC}
LOG=gail-gnome-platform.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${GNOME_PREFIX}/${libdirname}"
fi

# override TARBALLS to point at gnome/platform tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/platform/${GNOME_REL_MAJ}/${GNOME_REL}/sources

unpack_tarball gail-${GAIL_VER}
cd ${PKGDIR}

max_log_init gail ${GAIL_VER} "gnome-platform (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=${GNOME_PREFIX} ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

mn_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ ! -d /usr/${libdirname}/gtk-2.0 ]; then
   mkdir -p /usr/${libdirname}/gtk-2.0
   ln -sf ${GNOME_PREFIX}/${libdirname}/gtk-2.0/modules \
      /usr/${libdirname}/gtk-2.0
fi
