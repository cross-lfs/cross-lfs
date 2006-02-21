#!/bin/bash

### alsa-utils ###

cd ${SRC}
LOG=alsa-utils-blfs.log

set_libdirname
setup_multiarch

unpack_tarball alsa-utils-${ALSA_UTILS_VER}
cd ${PKGDIR}

max_log_init alsa-utils ${ALSA_UTILS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --mandir=/usr/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

touch /etc/asound.state &&
alsactl store
