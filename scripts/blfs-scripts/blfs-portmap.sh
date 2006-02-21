#!/bin/bash

### portmap ###

cd ${SRC}
LOG=blfs-portmap.log
set_libdirname
setup_multiarch

unpack_tarball portmap_${PORTMAP_VER}
cd ${PKGDIR}
apply_patch portmap-5beta-compilation_fixes-3 
apply_patch portmap-5beta-glibc_errno_fix-1

max_log_init portmap ${PORTMAP_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

