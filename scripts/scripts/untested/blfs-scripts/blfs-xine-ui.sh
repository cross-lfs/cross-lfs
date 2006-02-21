#!/bin/bash

### xine-ui ###

cd ${SRC}
LOG=xine-ui-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball xine-ui-${XINE_UI_VER}
cd ${PKGDIR}

max_log_init xine-ui ${XINE_UI_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O3 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O3 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
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
   # We'll use a wrapper for each existing binary
   files="aaxine cacaxine fbxine xine xine-remote"
   for file in ${files}; do
      if [ -f /usr/bin/${file} ]; then
            use_wrapper /usr/bin/${file}
      fi
   done
fi
