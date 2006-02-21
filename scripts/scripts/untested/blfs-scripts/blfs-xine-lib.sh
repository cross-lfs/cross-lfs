#!/bin/bash

### xine-lib ###

cd ${SRC}
LOG=xine-lib-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# Uncomment to use external ffmpeg
use_external_ffmpeg="Y"

case ${TGT_ARCH} in
   x86_64 )
      if [ "${BUILDENV}" = "32" ]; then
         extra_conf="${extra_conf} --host=${ALT_TGT}"
         extra_conf="${extra_conf} --build=${ALT_TGT}"
      fi
   ;;
esac

unpack_tarball xine-lib-${XINE_LIB_VER}
cd ${PKGDIR}

if [ "${use_external_ffmpeg}" = "Y" ]; then
   extra_conf="${extra_conf} --with-external-ffmpeg"
fi

if [ "${use_directx}" = "Y" -a "${BUILDENV}" = "32" ]; then
   extra_conf="${extra_conf} --with-dxheaders=/usr/include/wine/windows"
   extra_ldflags="-L/usr/lib/wine"
fi

# Add -m32 to
max_log_init xine-lib ${XINE_LIB_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O3 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O3 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname} ${extra_ldflags}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper /usr/bin/xine-config
fi
