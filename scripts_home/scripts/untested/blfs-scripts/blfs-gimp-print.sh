#!/bin/bash

### gimp-print ###

cd ${SRC}
LOG=gimp-print-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball gimp-print-${GIMP_PRINT_VER}
cd ${PKGDIR}

max_log_init gimp-print ${GIMP_PRINT_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
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
   use_wrapper /usr/bin/gimpprint-config
fi
