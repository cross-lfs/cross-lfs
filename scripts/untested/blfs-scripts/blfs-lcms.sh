#!/bin/bash 

### lcms ###

cd ${SRC}
LOG=lcms-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball lcms-${LCMS_VER}
cd ${PKGDIR}

# TODO: need to patch python/lcms.i as SWIG_LPGAMMATABLE is not defined
# TODO: check python output what it defines for site-packeages during
#       bi-arch builds... python script dir is always lib, not lib64
#       ( thio could be an issue with the python build ).
#       Also, produced .la files need editing, and for some reason
#       libtool brings in /usr/lib64/lib{jpeg,tiff}.la during 32bit builds

max_log_init lcms ${LCMS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --with-python ${extra_conf} \
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

