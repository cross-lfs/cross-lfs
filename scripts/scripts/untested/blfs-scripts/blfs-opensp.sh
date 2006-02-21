#!/bin/bash

### OpenSP ###

cd ${SRC}
LOG=OpenSP-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball OpenSP-${OPENSP_VER}
cd ${PKGDIR}

apply_patch OpenSP-1.5.1-LITLEN-1
apply_patch OpenSP-1.5.1-gcc34-1

max_log_init OpenSP ${OPENSP_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --disable-static \
    ${extra_conf} --enable-http \
    --enable-default-catalog=/etc/sgml/catalog \
    --enable-default-search-path=/usr/share/sgml \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make pkgdatadir=/usr/share/sgml/OpenSP-${OPENSP_VER} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make pkgdatadir=/usr/share/sgml/OpenSP-${OPENSP_VER} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   create_stub_hdrs /usr/include/OpenSP/config.h
fi

ln -sf onsgmls /usr/bin/nsgmls
ln -sf osgmlnorm /usr/bin/sgmlnorm
ln -sf ospam /usr/bin/spam
ln -sf ospcat /usr/bin/spcat
ln -sf ospent /usr/bin/spent
ln -sf osx /usr/bin/sx
ln -sf osx /usr/bin/sgml2xml
ln -sf libosp.so /usr/${libdirname}/libsp.so

