#!/bin/bash

# cross-lfs native diffutils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=diffutils-native.log

set_libdirname
setup_multiarch

unpack_tarball diffutils-${DIFFUTILS_VER} &&
cd ${PKGDIR}

max_log_init Diffutils ${DIFFUTILS_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

