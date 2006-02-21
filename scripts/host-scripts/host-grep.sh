#!/bin/bash

### GREP ###

cd ${SRC}
LOG=grep-buildhost.log

unpack_tarball grep-${GREP_VER} &&
cd ${PKGDIR}

max_log_init Grep ${GREP_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} --with-included-regex \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Make Grep tests executable
chmod 750 ./tests/* &&

min_log_init ${TESTLOGS} &&
# May fail 2 tests...
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

