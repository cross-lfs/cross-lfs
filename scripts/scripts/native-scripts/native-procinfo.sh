#!/bin/bash

# cross-lfs native procinfo build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=procinfo-native.log

set_libdirname
setup_multiarch

unpack_tarball procinfo-${PROCINFO_VER} &&
cd ${PKGDIR}

# fix manpage installation
sed -i 's@\($(prefix)\)\(/man\)@\1/share\2@g' Makefile

max_log_init Procinfo ${PROCINFO_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
     LDLIBS="-lncurses" \
     LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

