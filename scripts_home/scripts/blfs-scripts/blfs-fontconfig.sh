#!/bin/sh
#
# Fontconfig
#
cd ${SRC}
LOG=fontconfig-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball fontconfig-${FONTCONFIG_VER} &&

cd ${PKGDIR}

max_log_init Fontconfig ${FONTCONFIG_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --sysconfdir=/etc \
   --disable-docs \
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

# HACK: this is most likely NOT needed...
if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/fc-cache /usr/bin/fc-list 
fi

