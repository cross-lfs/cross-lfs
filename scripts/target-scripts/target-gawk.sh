#!/bin/bash

# cross-lfs target gawk build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gawk-cross.log

unpack_tarball gawk-${GAWK_VER} &&
cd ${PKGDIR}

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

# if target is same as build host, adjust build slightly to avoid running
# configure checks which we cannot run
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

# gawk is braindead for setting version information
# during install while cross compiling, here we will use
# gawk-$(PACKAGE_VERSION) instead of trying to run gawk --version
# (which cant be done when cross compiling, derr) to get version info
test -f Makefile.in-ORIG ||
   cp -p Makefile.in Makefile.in-ORIG
sed 's@\(fullname=gawk-\).*\(;.*\)@\1\$(PACKAGE_VERSION) \2@g' \
   Makefile.in-ORIG > Makefile.in

max_log_init Gawk ${GAWK_VER} "initial (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --build=${BUILD} --host=${TARGET} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

