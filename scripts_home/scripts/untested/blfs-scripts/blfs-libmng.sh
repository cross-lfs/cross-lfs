#!/bin/bash

### libmng ###

cd ${SRC}
LOG=libmng-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball libmng-${LIBMNG_VER}
cd ${PKGDIR}

max_log_init libmng ${LIBMNG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
sed -e 's@\(^prefix=\).*@\1/usr@g' \
    -e 's@\(^CFLAGS=\)\(.*\)@\1${TGT_CFLAGS} -fPIC \2@g' \
    -e "s@\$(prefix)/lib.*@\$(prefix)/${libdirname}@g" \
    -e "s@/usr/local/lib@\$(prefix)/${libdirname}@g" \
    -e "s@/usr/local@\$(prefix)@g" \
   < makefiles/makefile.linux > Makefile

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} CC="${CC-gcc} ${ARCH_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
(
make prefix=/usr install &&
install -v -m644 doc/man/*.3 /usr/share/man/man3 &&
install -v -m644 doc/man/*.5 /usr/share/man/man5 &&
install -v -m755 -d /usr/share/doc/libmng-${LIBMNG_VER} &&
install -v -m644 doc/*.{png,txt} /usr/share/doc/libmng-${LIBMNG_VER}
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

