#!/bin/bash

### mysql ###

cd ${SRC}
LOG=mysql-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball mysql-${MYSQL_VER}
cd ${PKGDIR}

max_log_init mysql ${MYSQL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXLAGS="${TGT_CFLAGS}" \
CPPFLAGS="-D_GNU_SOURCE" \
./configure --prefix=/usr ${extra_conf} \
   --libexecdir=/usr/${libdirname}/mysql --localstatedir=/var/lib/mysql \
   --enable-thread-safe-client --enable-assembler \
   --enable-local-infile --with-named-thread-libs=-lpthread \
   --with-unix-socket-path=/var/run/mysql/mysql.sock \
   --without-debug --without-bench --without-readline \
   --with-libwrap --with-openssl \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} testdir=/usr/${libdirname}/mysql/mysql-test \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make testdir=/usr/${libdirname}/mysql/mysql-test install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/{mysql_config,mysql_fix_privilege_tables,mysql_install_db,mysqlbug}
   create_stub_hdrs /usr/include/mysql/my_config.h
fi

cd /usr/${libdirname} &&
ln -sf mysql/libmysqlclient{,_r}.so* .
