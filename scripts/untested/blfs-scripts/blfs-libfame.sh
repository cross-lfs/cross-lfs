#!/bin/bash

### libfame ###

cd ${SRC}
LOG=libfame-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libfame-${LIBFAME_VER}
cd ${PKGDIR}

case ${LIBFAME_VER} in
   0.9.1 )
      apply_patch libfame-0.9.1-gcc34-1
      # update config.sub and config.guess so libfame groks newer arches
      apply_patch libfame-0.9.1-gnu_config-1
      sed -i -e '/FAME_RLD_FLAGS=/s@\\${exec_prefix}/lib@${libdir}@g' \
         configure
   ;;
esac

max_log_init libfame ${LIBFAME_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
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
   use_wrapper /usr/bin/libfame-config
fi
