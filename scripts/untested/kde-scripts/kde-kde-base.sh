#!/bin/bash

### kdebase ###

cd ${SRC}
LOG=kdebase-kde.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${KDE_PREFIX}/${libdirname}"
   extra_conf="${extra_conf} --enable-libsuffix=${BUILDENV}"
fi

# override TARBALLS to point at kde/stable tree
export TARBALLS=${KDE_TARBALLS}/stable/${KDE_VER}/src

unpack_tarball kdebase-${KDEBASE_VER}
cd ${PKGDIR}

max_log_init kdebase ${KDEBASE_VER} "kde (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=${KDE_PREFIX} ${extra_conf} \
   --disable-debug --disable-dependency-tracking \
   --with-qt-libraries=/opt/qt/${libdirname} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
#--enable-fast-malloc=full \

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

