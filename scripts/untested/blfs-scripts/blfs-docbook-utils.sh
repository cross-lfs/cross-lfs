#!/bin/bash

### docbook-utils ###

cd ${SRC}
LOG=docbook-utils-blfs.log

set_libdirname
setup_multiarch

unpack_tarball docbook-utils-${DBK_UTILS_VER}
cd ${PKGDIR}

max_log_init docbook-utils ${DBK_UTILS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

for doctype in html ps dvi man pdf rtf tex texi txt; do
    ln -s docbook2${doctype} /usr/bin/db2${doctype}
done
