#!/bin/bash

# cross-lfs target tcp-wrappers build
# -----------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="tcp-wrappers-target.log"
libdirname=lib

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

unpack_tarball tcp_wrappers_${TCPWRAP_VER}

cd ${PKGDIR}
apply_patch tcp_wrappers-7.6-shared_lib_plus_plus-1
apply_patch tcp_wrappers-7.6-gcc34-1

if [ ! "${libdirname}" = "lib" ]; then
   sed -i -e "s@/lib/@/${libdirname}/@g" Makefile
fi

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   sed -i -e "s@\(\${DESTDIR}\)/usr@\1${TGT_TOOLS}@g" Makefile
fi

max_log_init tcp-wrappers ${TCPWRAP_VER} "target (shared)" ${BUILDLOGS} ${LOG}
make CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
   AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
   REAL_DAEMON_DIR="${BUILD_PREFIX}/sbin" \
   STYLE="-DPROCESS_OPTIONS" linux \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
#su -c "mkdir -p ${TGT_TOOLS}/share/man/man{5,8} ; make install" \
mkdir -p ${INSTALL_PREFIX}/share/man/man{5,8} &&
su -c "make ${INSTALL_OPTIONS} install" \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

