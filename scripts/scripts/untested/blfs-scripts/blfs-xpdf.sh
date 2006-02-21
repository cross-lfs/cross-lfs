#!/bin/bash

### xpdf ###

cd ${SRC}
LOG=xpdf-blfs.log

SELF=`basename ${0}`
set_libdirname
setup_multiarch

unpack_tarball xpdf-${XPDF_VER}

case ${XPDF_VER} in
   3.00 )
      cd ${PKGDIR}/xpdf
      apply_patch xpdf-3.00pl1 -Np0
      apply_patch xpdf-3.00pl2 -Np0
      apply_patch xpdf-3.00pl3 -Np0
      cd ${SRC}/${PKGDIR}
      apply_patch xpdf-3.00pl3-freetype_2.1.7_hack-2
   ;;
esac

cd ${SRC}/${PKGDIR}

max_log_init xpdf ${XPDF_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   --sysconfdir=/etc \
   --enable-freetype2 \
   --with-freetype2-includes=/usr/include/freetype2 \
   --enable-a4-paper \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

