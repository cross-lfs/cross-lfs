#!/bin/bash

# cross-lfs native libtool build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=libtool-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ ! "{libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

### LIBTOOL ###
unpack_tarball libtool-${LIBTOOL_VER} &&
cd ${PKGDIR}

max_log_init Libtool ${LIBTOOL_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --datadir=/usr/share/misc ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ldconfig

