#!/bin/bash

### xmms ###

cd ${SRC}
LOG=xmms-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
   extra_conf="${extra_conf} --with-ogg-libraries=/usr/${libdirname}" 
   extra_conf="${extra_conf} --with-vorbis-libraries=/usr/${libdirname}"
fi

unpack_tarball xmms-${XMMS_VER}
cd ${PKGDIR}

#case ${TGT_ARCH} in
#   x86_64 ) 
#      if [ "${BUILDENV}" = "32" ]; then 
#         extra_conf="${extra_conf} --enable-simd"
#      fi
#   ;;
#   i?86 ) extra_conf="${extra_conf} --enable-simd" ;;
#esac

if [ ! "${libdirname}" = "lib" ]; then
   # configure hack so we set libtool lib search path to look in 
   # */${libdirname}
   sed -i -e "/^sys_lib_\(\|dl\)search_path_spec/s@/lib@/${libdirname}@g" \
      configure
fi

max_log_init xmms ${XMMS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
# Use only on 32bit
# --enable-simd

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   # keep 32bit xmms (why, I dont know ;-) )
   use_wrapper /usr/bin/{xmms,xmms-config}
fi

