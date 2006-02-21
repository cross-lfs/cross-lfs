#!/bin/bash

# cross-lfs build-host nasm build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="nasm-host.log"

unpack_tarball nasm-${NASM_VER} &&
cd ${SRC}/${PKGDIR}

# build nasm, bin86 and lilo 32 bit
#case ${TGT_ARCH} in
#   x86_64 ) ARCH_CFLAGS="-m32" ;;
#esac

mkdir -p ${HST_TOOLS}/share/man/man1

max_log_init nasm ${NASM_VER} host ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe" \
./configure --prefix=${HST_TOOLS} \
   --libexecdir=${HST_TOOLS}/lib/nasm \
   --mandir=${HST_TOOLS}/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
# should use "make everything" to generate docs, but we won't
# have ps2pdf yet
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} &&
make install_rdf \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

