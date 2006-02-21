#!/bin/bash

# cross-lfs target bin86 build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="bin86-target.log"

unpack_tarball bin86-${BIN86_VER} &&

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

cd ${SRC}/${PKGDIR}

# only build 32bit
case ${TGT_ARCH} in
   x86_64 ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init Bin86 ${BIN86_VER} target ${BUILDLOGS} ${LOG}
make CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make PREFIX=${INSTALL_PREFIX} install \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf
