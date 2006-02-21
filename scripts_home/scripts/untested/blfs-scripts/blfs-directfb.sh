#!/bin/bash

### DirectFB ###

cd ${SRC}
LOG=DirectFB-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball DirectFB-${DIRECTFB_VER}
cd ${PKGDIR}

case ${TGT_ARCH} in
   i686 ) extra_conf="${extra_conf} --enable-mmx --enable-sse" ;;
   x86_64 )
      ## Need patch for SIMD on amd64, patch stolen from gentoo
      #if [ "${BUILDENV}" = "64" ]; then
      #   case ${DIRECTFB_VER} in
      #      0.9.2[12] ) apply_patch DirectFB-0.9.21-simd-amd64 ;;
      #   esac
      #fi
      #extra_conf="${extra_conf} --enable-mmx --enable-sse"

   ;;
esac

# fix integer type redefinition errors
#--------------------------------------
# This is primarily here to fix amd64 64bit compilation, but if the
# linux-libc-headers are sane, this should not pose a problem for other
# architectures.
apply_patch DirectFB-0.9.22-dfb_types_amd64_hack

max_log_init DirectFB ${DIRECTFB_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr ${extra_conf} \
   --enable-sysfs --enable-video4linux2 --enable-unique \
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

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper /usr/bin/directfb-config
fi
