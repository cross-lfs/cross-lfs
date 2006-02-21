#!/bin/bash
#
# ed
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-ed.log

set_libdirname
setup_multiarch

unpack_tarball ed-${ED_VER} &&
cd ${PKGDIR}

# Would normally put a case stmt around this, but hey, ed doesn't get
# updated too often ;-)
apply_patch ed-0.2-mkstemp-1

max_log_init ed ${ED_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
 ./configure --prefix=/usr --build="${TARGET}" \
   --exec-prefix="" \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

