#!/bin/bash

### gexif ###

cd ${SRC}
LOG=gexif-blfs.log

set_libdirname
setup_multiarch

unpack_tarball gexif-${GEXIF_VER}
cd ${PKGDIR}

max_log_init gexif ${GEXIF_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make DESTDIR=/tmp/${PKGDIR} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

