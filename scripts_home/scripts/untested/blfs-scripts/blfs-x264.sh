#!/bin/bash

### x264 ###

cd ${SRC}
LOG=x264-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
   XLIBS="/usr/X11R6/${libdirname}"
fi

unpack_tarball x264-${X264_VER}
cd ${PKGDIR}

# edit configure script so we can set CC, override ARCH and set the
# location of our X libraries
apply_patch x264-svn-20050731-configure_fixes

max_log_init x264 ${X264_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
XLIBS="${XLIBS}" \
TGT_ARCH="${TGT_ARCH}" \
./configure --prefix=/usr ${extra_conf} \
 --extra-cflags="-pipe ${TGT_CFLAGS}" \
 --enable-mp4-output \
 --enable-pthread \
 --enable-visualize \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make DESTDIR=/tmp/${PKGDIR}-${BUILDENV} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

