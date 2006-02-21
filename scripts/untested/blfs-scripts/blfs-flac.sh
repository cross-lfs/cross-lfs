#!/bin/bash

### flac ###

cd ${SRC}
LOG=flac-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball flac-${FLAC_VER}
cd ${PKGDIR}

case ${TGT_ARCH} in
   x86_64 | i686 ) extra_conf="${extra_conf} --enable-sse" ;;
esac

# Blatantly stolen from gentoo
#apply_patch flac-1.1.2-xmms-config
#apply_patch flac-1.1.2-m4
#apply_patch flac-1.1.2-libtool
#apply_patch flac-1.1.2-gas -Np0
#apply_patch flac-1.1.2-makefile -Np0
#apply_patch flac-1.1.2-noogg -Np0
#./autogen
#libtoolize --copy --force

# This patch is above patches applied and autogen + libtoolize run
apply_patch flac-1.1.2-fixes

max_log_init flac ${FLAC_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LIBS="-lm" ./configure --prefix=/usr ${extra_conf} \
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

