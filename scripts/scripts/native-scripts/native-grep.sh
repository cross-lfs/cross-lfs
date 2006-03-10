#!/bin/bash

# cross-lfs native grep build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=grep-native.log

set_libdirname
setup_multiarch

unpack_tarball grep-${GREP_VER} &&
cd ${PKGDIR}

case ${GREP_VER} in
   2.5.1a ) apply_patch grep-2.5.1a-redhat_fixes-2 ;;
esac

max_log_init Grep ${GREP_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr --bindir=/bin \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Make Grep tests executable
chmod 750 ./tests/* &&

#min_log_init ${TESTLOGS} &&
#make check \
#   >>  ${LOGFILE} 2>&1 &&
#echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

