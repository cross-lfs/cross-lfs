#!/bin/bash

# cross-lfs target modutils build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=modutils.log

unpack_tarball modutils-${MODUTILS_VER} &&
cd ${PKGDIR}

max_log_init Modutils ${MODUTILS_VER} "Final (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" ./configure \
 --host="${TARGET}" --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make BUILDCC=gcc LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make DESTDIR="${LFS}" STRIP= install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

