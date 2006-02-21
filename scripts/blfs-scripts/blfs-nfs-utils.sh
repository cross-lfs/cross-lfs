#!/bin/bash

### nfs-utils ###

set_libdirname
setup_multiarch

cd ${SRC}
LOG=nfs-utils-blfs.log

unpack_tarball nfs-utils-${NFSUTILS_VER}
cd ${PKGDIR}

# Unset TARGET env var, it b0rks things here...
unset TARGET 

max_log_init nfs-utils ${NFSUTILS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 ${TGT_CFLAGS}" \
./configure --prefix=/usr --sysconfdir=/etc \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
env -i make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
env -i make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

