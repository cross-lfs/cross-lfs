#!/bin/sh

### tcp-wrappers ###

cd ${SRC}
LOG="tcp-wrappers-blfs.log"
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball tcp_wrappers_${TCPWRAP_VER}
cd ${PKGDIR}
apply_patch tcp_wrappers-7.6-shared_lib_plus_plus-1
apply_patch tcp_wrappers-7.6-gcc34-1

if [ ! "${libdirname}" = "lib" ]; then
   sed -i -e "s@/lib/@/${libdirname}/@g" Makefile
fi

max_log_init tcp-wrappers ${TCPWRAP_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" REAL_DAEMON_DIR=/usr/sbin \
   STYLE=-DPROCESS_OPTIONS linux \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

