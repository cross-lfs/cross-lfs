#!/bin/bash

### graphviz ###

cd ${SRC}
LOG=graphviz-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

if [ "Y" = "${MULTIARCH}" ]; then
   extra_conf="${extra_conf} --with-expatlibdir=/usr/${libdirname}"
   # fix LIBPOSTFIX so we dont always search lib64 on x86_64, ppc64 etc
   # when building 32bit
   if [ "${libdirname}" = "lib" ]; then
      sed -i -e "/LIBPOSTFIX/s@64@@g" configure
   fi
fi


unpack_tarball graphviz-${GRAPHVIZ_VER}
cd ${PKGDIR}

max_log_init graphviz ${GRAPHVIZ_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
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

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/dotneato-config
fi
