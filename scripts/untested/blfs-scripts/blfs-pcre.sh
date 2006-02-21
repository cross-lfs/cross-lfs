#!/bin/bash

### pcre ###

cd ${SRC}
LOG=pcre-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball pcre-${PCRE_VER}
cd ${PKGDIR}

max_log_init pcre ${PCRE_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --enable-utf8 \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

mv /usr/${libdirname}/libpcre.so.* /${libdirname}/ &&
ln -sf ../../${libdirname}/libpcre.so.0 /usr/${libdirname}/libpcre.so

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/pcre-config
fi
