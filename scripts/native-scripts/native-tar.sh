#!/bin/bash

# cross-lfs native tar build
# --------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# 20030419 - make libexecdir /usr/lib/tar (FHS Compliant)

cd ${SRC}
LOG=tar-native.log
unpack_tarball tar-${TAR_VER}
set_libdirname
setup_multiarch

cd ${PKGDIR}
case ${TAR_VER} in
   1.13 )   apply_patch tar-${TAR_VER} ;;
   1.15.1 ) apply_patch tar-1.15.1-sparse_fix-1 
            apply_patch tar-1.15.1-gcc4_fix_tests ;;
esac

max_log_init Tar ${TAR_VER} "native (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
./configure --prefix=/usr --bindir=/bin \
   --libexecdir=/usr/${libdirname}/tar \
      >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

