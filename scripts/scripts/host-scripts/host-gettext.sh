#!/bin/bash

### GETTEXT ###

cd ${SRC}
LOG=gettext-buildhost.log

unpack_tarball gettext-${GETTEXT_VER} &&
cd ${PKGDIR}

max_log_init Gettext ${GETTEXT_VER}  "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" ./configure --prefix=${HST_TOOLS} \
   --disable-shared \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

#min_log_init ${TESTLOGS} &&
#make check \
#   >>  ${LOGFILE} 2>&1 &&
#echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

