#!/bin/bash

### libusb ###

cd ${SRC}
LOG=libusb-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libusb-${LIBUSB_VER}
cd ${PKGDIR}

max_log_init libusb ${LIBUSB_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
(
   make && 
   make apidox
) >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
(
   make install &&
   install -v -d -m755 /usr/share/doc/libusb-${LIBUSB_VER}/html &&
   install -v -m644 doc/html/* /usr/share/doc/libusb-${LIBUSB_VER}/html &&
   install -v -d -m755 /usr/share/doc/libusb-${LIBUSB_VER}/apidocs &&
   install -v -m644 apidocs/html/* /usr/share/doc/libusb-${LIBUSB_VER}/apidocs
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper /usr/bin/libusb-config
fi
