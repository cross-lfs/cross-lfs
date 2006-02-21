#!/bin/bash

# cross-lfs native automake build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=automake-native.log

set_libdirname
setup_multiarch

unpack_tarball automake-${AUTOMAKE_VER} &&
cd ${PKGDIR}

max_log_init Automake ${AUTOMAKE_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Reported by Erik-Jan Post <ej.post@xs4all.nl> 20040924
#
# insthook test fails as insthook.test makefile uses a SCRIPTS variable
# and make is called with "-e". 
# Therefore our SCRIPTS env var we use for specifying the location of our
# scripts clobbers the insthook.test's expected SCRIPTS
#
# Here we just unset it (only will affect this script)
unset SCRIPTS

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# TODO: do we need to do the same for aclocal?
rel=`echo ${AUTOMAKE_VER} | sed 's@\([0-9]\.[0-9]\).*@\1@g'`
ln -sf automake-${rel} /usr/share/automake

