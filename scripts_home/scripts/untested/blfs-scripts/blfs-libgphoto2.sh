#!/bin/bash

### libgphoto2 ###

cd ${SRC}
LOG=libgphoto2-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libgphoto2-${LIBGPHOTO2_VER}
cd ${PKGDIR}

# LDFLAGS to appease libtool with libjpeg 
max_log_init libgphoto2 ${LIBGPHOTO2_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
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

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper /usr/bin/{gphoto2-config,gphoto2-port-config}
fi
