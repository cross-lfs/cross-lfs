#!/bin/bash

### arts ###

cd ${SRC}
LOG=arts-kde.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${KDE_PREFIX}/${libdirname}"
fi

# override TARBALLS to point at kde tree
export TARBALLS=${KDE_TARBALLS}/stable/${KDE_VER}/src
unpack_tarball arts-${ARTS_VER}
cd ${PKGDIR}

max_log_init arts ${ARTS_VER} "kde (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=${KDE_PREFIX} ${extra_conf} \
   --disable-debug --disable-dependency-tracking \
   --with-qt-libraries=/opt/qt/${libdirname} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make -k check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

