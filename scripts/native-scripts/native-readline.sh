#!/bin/bash

# cross-lfs native readline build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=readline-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball readline-${READLINE_VER} &&
cd ${PKGDIR}

case ${READLINE_VER} in
   4.3 ) apply_patch readline-4.3-gnu_fixes-1 ;;
   # Should be fixed next release
   5.0 ) apply_patch readline-5.0-fixes-1 ;;
esac

max_log_init readline ${READLINE_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make SHLIB_XLDFLAGS="-lncurses" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

chmod 755 /usr/${libdirname}/*.${READLINE_VER} &&
mv /usr/${libdirname}/lib{readline,history}.so.5* /${libdirname}
ln -sf ../../${libdirname}/libhistory.so.5 /usr/${libdirname}/libhistory.so
ln -sf ../../${libdirname}/libreadline.so.5 /usr/${libdirname}/libreadline.so

/sbin/ldconfig
