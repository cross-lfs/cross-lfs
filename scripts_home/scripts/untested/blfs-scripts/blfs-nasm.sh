#!/bin/bash

### NASM ###
cd ${SRC}
LOG="nasm-blfs.log"

unpack_tarball nasm-${NASM_VER} &&
cd ${SRC}/${PKGDIR}

# build nasm, bin86 and lilo 32 bit
case ${TGT_ARCH} in
   x86_64 ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init nasm ${NASM_VER} blfs ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" CFLAGS="-O2 -pipe" \
./configure --prefix=/usr \
   --libexecdir=/usr/lib/nasm \
   --mandir=/usr/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
# should use "make everything" to generate docs, but we don't
# know if we have ps2pdf yet
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} &&
make install_rdf \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

