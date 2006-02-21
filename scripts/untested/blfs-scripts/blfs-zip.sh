#!/bin/bash
#
# zip
#

cd ${SRC}
LOG=blfs-zip.log

set_libdirname
setup_multiarch

unpack_tarball zip${ZIP_VER} &&
cd ${PKGDIR}

max_log_init zip ${ZIP_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}

sed -i -e 's@$(INSTALL) man/zip.1@$(INSTALL_PROGRAM) man/zip.1@' \
    unix/Makefile

make ${PMFLAGS} CC="${CC-gcc} ${ARCH_CFLAGS}" \
   prefix=/usr -f unix/Makefile generic_gcc \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make prefix=/usr -f unix/Makefile install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

