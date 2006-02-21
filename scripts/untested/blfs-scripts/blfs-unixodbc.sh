#!/bin/bash

### unixODBC ###

cd ${SRC}
LOG=unixODBC-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

USE_QT=Y
if [ "Y" = "${USE_QT}" ]; then
   QTDIR="${QTDIR-/opt/qt}"
   extra_conf="${extra_conf} --with-qt-dir=${QTDIR}" 
   extra_conf="${extra_conf} --with-qt-bin=${QTDIR}/bin"
   extra_conf="${extra_conf} --with-qt-includes=${QTDIR}/include"
   extra_conf="${extra_conf} --with-qt-libraries=${QTDIR}/${libdirname}"
fi

unpack_tarball unixODBC-${UNIXODBC_VER}
cd ${PKGDIR}

# Fix flex 2.5.31 issues w YY_FLUSH_BUFFER being undefined
apply_patch unixODBC-2.2.11-flex_fixes

# fix libtool search paths
if [ ! "Y" = "${libdirname}" ]; then
   sed -i -e "/^sys_lib_\(\|dl\)search_path_spec=/s@/lib@/${libdirname}@g" \
      configure
   #sed -i -e "/^sys_lib_\(\|dl\)search_path_spec=/s@/lib@/${libdirname}@g" \
   #   libltdl/configure
fi

max_log_init unixODBC ${UNIXODBC_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXLAGS="${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr --sysconfdir=/etc ${extra_conf} \
   --infodir=/usr/share/info --mandir=/usr/share/man \
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

