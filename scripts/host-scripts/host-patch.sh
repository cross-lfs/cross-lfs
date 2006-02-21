#!/bin/bash

### PATCH ###

cd ${SRC}
LOG=patch-buildhost.log

unpack_tarball patch-${PATCH_VER}
cd ${PKGDIR}

max_log_init Patch ${PATCH_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}

# TODO: Probably should do a check to see if we need GNU_SOURCE
#       on the OS we are running the script from... 

#CPPFLAGS=-D_GNU_SOURCE \
CC="${CC-gcc}" CFLAGS="-O2 -pipe" ./configure --prefix=${HST_TOOLS} \
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

