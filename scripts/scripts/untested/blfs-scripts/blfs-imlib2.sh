#!/bin/bash

### imlib2 ###

cd ${SRC}
LOG=imlib2-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball imlib2-${IMLIB2_VER}
cd ${PKGDIR}

case ${TGT_ARCH} in
   x86_64 )
      # if building 32bit, ensure we override the configure checks for
      # enabling amd64 assembly and force mmx instead
      if [ "${BUILDENV}" = "32" ]; then
         extra_conf="${extra_conf} --disable-amd64 --enable-mmx"
      fi
   ;;
esac

# curse of libjpeg and libtool again... set LDFLAGS
max_log_init imlib2 ${IMLIB2_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
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
   use_wrapper /usr/bin/imlib2-config
fi
