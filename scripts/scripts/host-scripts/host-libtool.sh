#!/bin/bash

### LIBTOOL ###

cd ${SRC}
LOG=libtool-buildhost.log

unpack_tarball libtool-${LIBTOOL_VER} &&
cd ${PKGDIR}

max_log_init Libtool ${LIBTOOL_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make install \
      >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

