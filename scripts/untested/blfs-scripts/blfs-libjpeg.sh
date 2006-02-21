#!/bin/bash

### libjpeg ###

cd ${SRC}
LOG=libjpeg-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball jpegsrc.${LIBJPEG_VER}
cd ${PKGDIR}

# Update config.{sub,guess} to support newer architectures
# Update libtool scripts
apply_patch jpegsrc.v6b-update_configury-1

if [ ! "${libdirname}" = "lib" ]; then
   sed -i "/^libdir =/s/lib$/${libdirname}/g" makefile.cfg
fi

max_log_init libjpeg ${LIBJPEG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --enable-static --enable-shared ${extra_conf} \
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

