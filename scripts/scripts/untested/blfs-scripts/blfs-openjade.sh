#!/bin/bash

### openjade ###

cd ${SRC}
LOG=openjade-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball openjade-${OPENJADE_VER}
cd ${PKGDIR}

max_log_init openjade ${OPENJADE_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --disable-static \
    ${extra_conf} --enable-http \
    --enable-splibdir=/usr/${libdirname} \
    --enable-default-catalog=/etc/sgml/catalog \
    --enable-default-search-path=/usr/share/sgml \
    --datadir=/usr/share/sgml/openjade-${OPENJADE_VER} \
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

ln -sf openjade /usr/bin/jade &&
ln -sf libogrove.so /usr/${libdirname}/libgrove.so &&
ln -sf libospgrove.so /usr/${libdirname}/libspgrove.so &&
ln -sf libostyle.so /usr/${libdirname}/libstyle.so &&
install -m644 dsssl/catalog /usr/share/sgml/openjade-${OPENJADE_VER}/ &&
install -m644 dsssl/*.{dtd,dsl,sgm} \
    /usr/share/sgml/openjade-${OPENJADE_VER} &&
install-catalog --add /etc/sgml/openjade-${OPENJADE_VER}.cat \
    /usr/share/sgml/openjade-${OPENJADE_VER}/catalog &&
install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/openjade-${OPENJADE_VER}.cat

