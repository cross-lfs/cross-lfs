#!/bin/bash

### wine ###

cd ${SRC}
LOG=wine-blfs.log

unpack_tarball Wine-${WINE_VER}
cd ${PKGDIR}

max_log_init wine ${WINE_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
./configure --prefix=/usr --sysconfdir=/etc \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
( 
   make depend &&
   make
) >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

