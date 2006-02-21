#!/bin/bash

### shared-mime-info ###

cd ${SRC}
LOG=shared-mime-info-blfs.log

set_libdirname
setup_multiarch

unpack_tarball shared-mime-info-${SHD_MIME_INFO_VER}
cd ${PKGDIR}

max_log_init shared-mime-info ${SHD_MIME_INFO_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
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

