#!/bin/bash

# cross-lfs target nasm build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="nasm-target.log"

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="INSTALLROOT=${LFS}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

unpack_tarball nasm-${NASM_VER} &&
cd ${SRC}/${PKGDIR}

# build nasm, bin86 and lilo 32 bit
case ${TGT_ARCH} in
   x86_64 ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init nasm ${NASM_VER} target ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" CFLAGS="-O2 -pipe" \
./configure --prefix=${BUILD_PREFIX} --host=${TARGET} \
   --libexecdir=${TGT_TOOLS}/lib/nasm \
   --mandir=${TGT_TOOLS}/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
# should use "make everything" to generate docs, but we won't
# have ps2pdf yet
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} &&
make ${INSTALL_OPTIONS} install_rdf \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

