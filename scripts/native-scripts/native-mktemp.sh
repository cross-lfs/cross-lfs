#!/bin/bash

### MKTEMP ###
cd ${SRC}
LOG="mktemp-native.log"
set_libdirname
setup_multiarch

unpack_tarball mktemp-${MKTEMP_VER} &&
cd ${PKGDIR}

apply_patch mktemp-1.5-add_tempfile-1

max_log_init mktemp ${MKTEMP_VER} native ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" CFLAGS="-O2 -pipe" \
./configure --prefix=/usr \
   --enable-libc \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

