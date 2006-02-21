#!/bin/bash

# cross-lfs build-host bin86 build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="bin86-host.log"

unpack_tarball bin86-${BIN86_VER} &&
cd ${SRC}/${PKGDIR}

# only build 32bit
case ${BUILD} in
   x86_64* ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init Bin86 ${BIN86_VER} host ${BUILDLOGS} ${LOG}
make CC="gcc ${ARCH_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
make CC="gcc ${ARCH_CFLAGS}" -C ld \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make  CC="gcc ${ARCH_CFLAGS}" PREFIX=${HST_TOOLS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf
