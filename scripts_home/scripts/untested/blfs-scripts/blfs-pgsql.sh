#!/bin/bash

### postgresql ###

cd ${SRC}
LOG=postgresql-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball postgresql-${PGSQL_VER}
cd ${PKGDIR}

echo ${ARCH_LDFLAGS}

max_log_init postgresql ${PGSQL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
LD="${LD-ld} ${ARCH_LDFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --enable-thread-safety \
   --with-krb5 --with-openssl \
   --with-perl --with-python --with-tcl \
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
   use_wrapper /usr/bin/pg_config 
   create_stub_hdrs /usr/include/{pg_config.h,postgresql/server/pg_config.h}
fi
