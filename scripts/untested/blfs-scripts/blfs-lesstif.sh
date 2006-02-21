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

case ${LESSTIF_VER} in
   0.94.0 )
     apply_patch lesstif-0.94.0-use_libdir
   ;;
   0.94.4 )
     apply_patch lesstif-0.94.4-use_libdir_and_fix_installdirs
     apply_patch lesstif-0.94.4-testsuite_fix-1
   ;;
esac

# fix mxmkmf generation to point at correct location when multi-arch
sed -i -e "/^lcfgdir=/s@/lib/@/${libdirname}/@g" \
   lib/config/mxmkmf.in

max_log_init lesstif ${LESSTIF_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
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

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/mxmkmf
fi

