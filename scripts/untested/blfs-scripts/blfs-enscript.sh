#!/bin/bash

### enscript ###

cd ${SRC}
LOG=enscript-blfs.log

set_libdirname
setup_multiarch

unpack_tarball enscript-${ENSCRIPT_VER}
cd ${PKGDIR}

max_log_init enscript ${ENSCRIPT_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --sysconfdir=/etc/enscript \
   --localstatedir=/var \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS}
make \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}
make install \
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

