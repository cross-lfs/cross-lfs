#!/bin/bash

# cross-lfs target grep build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gzip-target.log

unpack_tarball gzip-${GZIP_VER} &&
cd ${PKGDIR}

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

# Configure isn't setup to use ${TARGET}-nm for a test... fix it
test -f configure-ORIG ||
   mv configure configure-ORIG

sed "s@nm conftest@${TARGET}-&@" configure-ORIG > configure
chmod 755 configure

max_log_init Gzip ${GZIP_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} \
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

rm -f ${INSTALL_PREFIX}/bin/{gunzip,zcat}
ln -sf gzip ${INSTALL_PREFIX}/bin/gunzip
ln -sf gzip ${INSTALL_PREFIX}/bin/zcat
ln -sf gunzip ${INSTALL_PREFIX}/bin/uncompress
