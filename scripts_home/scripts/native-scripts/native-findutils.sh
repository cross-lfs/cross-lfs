#!/bin/bash

# cross-lfs native findutils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=findutils-native.log

set_libdirname
setup_multiarch

unpack_tarball findutils-${FINDUTILS_VER} &&
cd ${PKGDIR}
test 4.1 = "${FINDUTILS_VER}" &&
   apply_patch findutils-${FINDUTILS_VER}

# TODO: had to hack config.sub so it accepted powerpc64...
#       come up with a check and a hack here...

max_log_init Findutils ${FINDUTILS_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --localstatedir=/var/lib/misc \
   --libexecdir=/usr/${libdirname}/locate \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o install OK" || barf

