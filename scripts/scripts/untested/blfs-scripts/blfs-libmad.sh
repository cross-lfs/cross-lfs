#!/bin/bash

### libmad ###

cd ${SRC}
LOG=libmad-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

#====================================================
# Following 2 if's for biarch predominately...
# Set the fixed point math routines appropriately

# if ALT_TGT is defined, set --host and --build
if [ ! -z ${ALT_TGT} ]; then
   extra_conf="${extra_conf} --host=${ALT_TGT}"
   extra_conf="${extra_conf} --build=${ALT_TGT}"
fi

# TODO: this will have to be set on 64bit machines regardless
#       if it is biarch or not...
if [ "64" = "${BUILDENV}" ] ; then
   extra_conf="${extra_conf} --enable-fpm=64bit"
fi
#====================================================

unpack_tarball libmad-${LIBMAD_VER}
cd ${PKGDIR}

max_log_init libmad ${LIBMAD_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
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

