#!/bin/bash

### xmms ###

cd ${SRC}
LOG=xmms-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball xmms-${XMMS_VER}
cd ${PKGDIR}

# NOTE: for 64bit I had to temporarily move /usr/lib/lib{glib,gmodule}.la
#       out of the way to make it build...
#

max_log_init xmms ${XMMS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
# Use only on 32bit
# --enable-simd

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${BIARCH}" ]i; then
   # keep 32bit xmms (why, I dont know ;-) )
   use_wrapper /usr/bin/{xmms,xmms-config}
fi

chmod 755 /usr/${libdirname}/xmms.so.2.*
