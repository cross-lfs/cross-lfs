#!/bin/bash

# cross-lfs native kbd build
# --------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=kbd-native.log

set_libdirname
setup_multiarch

unpack_tarball kbd-${KBD_VER}
cd ${PKGDIR}

# TODO: Turn this into a sed/awk of Makefile.in for building reqd misc packages
case ${KBD_VER} in
   1.08 ) apply_patch kbd-1.08 ;;
   1.12 ) apply_patch kbd-1.12 ;;
esac

max_log_init Kbd ${KBD_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
     LDFLAGS="${LDFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
    >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

