#!/bin/bash

### sharutils ###

cd ${SRC}
LOG=sharutils-blfs.log

set_libdirname
setup_multiarch

unpack_tarball sharutils-${SHARUTILS_VER}
cd ${PKGDIR}

max_log_init sharutils ${SHARUTILS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
make install-man \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

