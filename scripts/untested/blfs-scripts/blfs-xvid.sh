#!/bin/bash

### xvid ###

cd ${SRC}
LOG=xvid-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

if [ "${MULTIARCH}" = "Y" ]; then
   case ${TGT_ARCH} in
      x86_64 )
         if [ "${BUILDENV}" = "32" ]; then
            extra_conf="${extra_conf} --build=${ALT_TGT}"
            extra_conf="${extra_conf} --host=${ALT_TGT}"
            extra_conf="${extra_conf} --target=${ALT_TGT}"
         fi
      ;;
   esac
fi

unpack_tarball xvidcore-${XVID_VER}
cd ${PKGDIR}/build/generic

max_log_init xvid ${XVID_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O3 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
(
   make list-cflags &&
   make list-install-path &&
   make list-targets &&
   make 
) >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
(
   make install &&
   ln -v -sf libxvidcore.so.4.? /usr/${libdirname}/libxvidcore.so.4 &&
   ln -v -sf libxvidcore.so.4 /usr/${libdirname}/libxvidcore.so &&
   chmod -v 644 /usr/${libdirname}/libxvidcore.a
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

