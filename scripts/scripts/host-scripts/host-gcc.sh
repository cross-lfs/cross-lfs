#!/bin/bash

### GCC ( static ) ###

cd ${SRC}

LOG="gcc-buildhost.log"

unpack_tarball gcc-${GCC_VER}

# 20030427
# Cannot trust ${GCC_VER} to supply us with the correct
# gcc version (especially if cvs).
# Grab it straight from version.c
cd ${SRC}/${PKGDIR}
target_gcc_ver=`grep version_string gcc/version.c | \
                sed 's@.* = "\([0-9.]*\).*@\1@g'`

test -d ${SRC}/gcc-${GCC_VER}-buildhost &&
   rm -rf ${SRC}/gcc-${GCC_VER}-buildhost

mkdir -p ${SRC}/gcc-${GCC_VER}-buildhost &&
cd ${SRC}/gcc-${GCC_VER}-buildhost &&

max_log_init Gcc ${GCC_VER} "buildhost (static)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" CXXFLAGS="-O2 -pipe" \
../${PKGDIR}/configure --prefix=${HST_TOOLS} \
   --enable-languages=c --enable-__cxa_atexit \
   --enable-c99 --enable-long-long --enable-threads=posix \
   --disable-nls --disable-shared \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} BOOT_LDFLAGS="-s" BOOT_CFLAGS="-O2 -pipe" \
   STAGE1_CFLAGS="-O2 -pipe" bootstrap \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make -k check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

test -L ${HST_TOOLS}/bin/cc || ln -s gcc ${HST_TOOLS}/bin/cc

