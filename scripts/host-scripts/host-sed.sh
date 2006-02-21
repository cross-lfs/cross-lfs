#!/bin/bash

### SED ###

cd ${SRC}
LOG=sed-buildhost.build

unpack_tarball sed-${SED_VER} &&
cd ${PKGDIR}

case ${SED_VER} in
   4.1 )
      # when sed'ing in-place the target files permissions are changed
      # this fixes this behaviour
      apply_patch sed-4.1-permissions-1
   ;;
esac

max_log_init Sed ${SED_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

