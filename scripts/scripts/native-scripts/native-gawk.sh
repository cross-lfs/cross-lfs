#!/bin/bash

# cross-lfs native gawk build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gawk-native.log

set_libdirname
setup_multiarch

unpack_tarball gawk-${GAWK_VER} &&
cd ${PKGDIR}

# Following mimics gawk patch
files="Makefile.in awklib/Makefile.in"
for file in ${files}; do

   test -f ${file}-ORIG ||
      cp ${file} ${file}-ORIG

   sed -e 's:libexecdir = @libexecdir@/awk:libexecdir = @libexecdir@:g' \
       -e 's:datadir = @datadir@/awk:datadir = @datadir@/gawk:g' \
       ${file}-ORIG > ${file}
done

max_log_init Gawk ${GAWK_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --libexecdir=/usr/${libdirname}/gawk \
   --bindir=/bin \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# When specifying --bindir the symlink doesn't get created (???)
ln -sf gawk /bin/awk

