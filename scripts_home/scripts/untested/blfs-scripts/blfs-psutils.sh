#!/bin/sh

### psutils ###

cd ${SRC}
LOG=psutils-blfs.log

set_libdirname
setup_multiarch

unpack_tarball psutils-${PSUTILS_VER}
cd ${PKGDIR}

sed -e 's@/usr/local@/usr@g' \
    -e "s@^CFLAGS = @&${TGT_CFLAGS} @g" \
   Makefile.unix > Makefile

max_log_init psutils ${PSUTILS_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}
make install \
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

