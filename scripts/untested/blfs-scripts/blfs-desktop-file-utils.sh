#!/bin/bash

### desktop-file-utils ###

cd ${SRC}
LOG=desktop-file-utils-gnome-platform.log

set_libdirname
setup_multiarch

unpack_tarball desktop-file-utils-${DT_FILE_UTILS_VER}
cd ${PKGDIR}

max_log_init desktop-file-utils ${DT_FILE_UTILS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" ./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

