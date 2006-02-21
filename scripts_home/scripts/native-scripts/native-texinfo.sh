#!/bin/bash

# cross-lfs native texinfo build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=texinfo-native.log

set_libdirname
setup_multiarch

unpack_tarball texinfo-${TEXINFO_VER} &&
cd ${PKGDIR}

max_log_init Texinfo ${TEXINFO_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info \
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
make TEXMF=/usr/share/texmf install-tex \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

