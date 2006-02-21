#!/bin/sh
#
# NTP
#
cd ${SRC}
LOG=ntp-blfs.log

set_libdirname
setup_multiarch

unpack_tarball ntp-${NTP_VER} &&
cd ${PKGDIR}

# Fix issues when compiling with gcc4 (shouldn't hurt for gcc versions)
apply_patch ntp-4.2.0-gcc4

max_log_init ntp ${NTP_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr --bindir=/usr/sbin --sysconfdir=/etc \
   --with-crypto \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

