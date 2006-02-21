#!/bin/bash

### M4 ###

cd ${SRC}
LOG=m4-buildhost.log

unpack_tarball m4-${M4_VER} &&
cd ${PKGDIR} 

max_log_init M4 ${M4_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" ./configure --prefix=${HST_TOOLS} \
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

