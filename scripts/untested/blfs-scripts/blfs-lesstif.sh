#!/bin/bash

### lesstif ###

cd ${SRC}
LOG=lesstif-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball lesstif-${LESSTIF_VER}
cd ${PKGDIR}

apply_patch lesstif-0.94.0-use_libdir

max_log_init lesstif ${LESSTIF_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --enable-build-21 \
   --disable-debug \
   --enable-production \
   --disable-build-tests \
   --with-xdnd \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# TODO: Need to edit /usr/bin/mxmkmf to set the correct libdir ...
# (it really should be setup fom --libdir )
if [ "Y" = "${MULTIARCH}" ]i; then
   use_wrapper /usr/bin/mxmkmf
fi

