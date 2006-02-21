#!/bin/bash

### AUTOMAKE ###

cd ${SRC}
LOG=automake-buildhost.log

unpack_tarball automake-${AUTOMAKE_VER} &&
cd ${PKGDIR}

max_log_init Automake ${AUTOMAKE_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# TODO: do we need to do the same for aclocal?
rel=`echo ${AUTOMAKE_VER} | sed 's@\([0-9]\.[0-9]\).*@\1@g'`
ln -sf automake-${rel} ${HST_TOOLS}/share/automake

