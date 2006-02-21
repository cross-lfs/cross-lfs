#!/bin/bash

# cross-lfs temporary texinfo build
# ---------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=texinfo-temp.log

unpack_tarball texinfo-${TEXINFO_VER} &&
cd ${PKGDIR}

max_log_init Texinfo ${TEXINFO_VER} "temp (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${TGT_TOOLS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
make TEXMF=${TGT_TOOLS}/share/texmf install-tex \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

