#!/bin/bash

# cross-lfs native gzip build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gzip-native.log 

set_libdirname
setup_multiarch

unpack_tarball gzip-${GZIP_VER} &&
cd ${PKGDIR}

max_log_init Gzip ${GZIP_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

# Change the default install directory
test -f "gzexe.in-ORIG" ||
   mv gzexe.in gzexe.in-ORIG

sed 's@"BINDIR"@/bin@' gzexe.in-ORIG > gzexe.in &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

rm -f /usr/bin/{gunzip,zcat}
ln -sf gzip /usr/bin/gunzip
ln -sf gzip /usr/bin/zcat
ln -sf gunzip /usr/bin/uncompress

