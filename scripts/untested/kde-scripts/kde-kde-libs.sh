#!/bin/bash

### kdelibs ###

cd ${SRC}
LOG=kdelibs-kde.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${KDE_PREFIX}/${libdirname}"
   extra_conf="${extra_conf} --enable-libsuffix=${BUILDENV}"
   # for some reason /opt/kde/lib64 was missing during linking...
   # you'd think the pkgconfig or .la files would have sorted that...
   extra_conf="${extra_conf} --with-extra-libs=${KDE_PREFIX}/${libdirname}"
fi

# override TARBALLS to point at kde/stable tree
export TARBALLS=${KDE_TARBALLS}/stable/${KDE_VER}/src
unpack_tarball kdelibs-${KDELIBS_VER}
cd ${PKGDIR}

# override PATCHES to point at kde/stable tree
export PATCHES="${KDE_TARBALLS}/stable/${KDE_VER}/patches"

case ${KDE_VER} in
   3.3.2 )
      apply_patch post-3.3.2-kdelibs-htmlframes2 -Np0 
      apply_patch post-3.3.2-kdelibs-kioslave -Np0
      patch -Np0 kio/kio/job.cpp ${PATCHES}/post-3.3.2-kdelibs-kio.diff
   ;;
esac

max_log_init kdelibs ${KDELIBS_VER} "kde (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAS="${TGT_CFLAGS}" \
./configure --prefix=${KDE_PREFIX} ${extra_conf} \
   --disable-debug --disable-dependency-tracking \
   --enable-fast-malloc=full \
   --with-qt-libraries=/opt/qt/${libdirname} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

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

