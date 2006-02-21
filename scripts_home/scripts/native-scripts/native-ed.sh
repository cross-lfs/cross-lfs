#!/bin/bash

# cross-lfs native ed build
# -------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=ed-native.log

set_libdirname
setup_multiarch

unpack_tarball ed-${ED_VER}
cd ${PKGDIR}

# TODO: patch is for ed 0.2, if this barfs check if patch needed
#       for this version of ed 
apply_patch ed-0.2-mkstemp-1

max_log_init Ed ${ED_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
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

mv -f /usr/bin/{ed,red} /bin

