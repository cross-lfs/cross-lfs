#!/bin/bash

### TEXINFO ###

cd ${SRC}
LOG=texinfo-buildhost.log

unpack_tarball texinfo-${TEXINFO_VER} &&
cd ${PKGDIR}

max_log_init Texinfo ${TEXINFO_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} \
   --disable-nls \
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

#min_log_init ${INSTLOGS} &&
#make TEXMF=${HST_TOOLS}/share/texmf install-tex \
#   >> ${LOGFILE} 2>&1 &&
#echo " o ALL OK" || barf

