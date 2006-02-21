#!/bin/bash
#
# gdbm
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-gdbm.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball gdbm-${GDBM_VER} &&
cd ${PKGDIR}

max_log_init gdbm ${GDBM_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --build="${TARGET}" \
   --mandir=/usr/share/man --infodir=/usr/share/info ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make BINOWN=root BINGRP=root install \
   >> ${LOGFILE} 2>&1 &&
make BINOWN=root BINGRP=root install-compat \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

