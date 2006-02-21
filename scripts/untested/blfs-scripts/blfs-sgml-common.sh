#!/bin/bash

### sgml-common ###

cd ${SRC}
LOG=sgml-common-blfs.log

set_libdirname
setup_multiarch

unpack_tarball sgml-common-${SGML_COMMON_VER}
cd ${PKGDIR}

apply_patch sgml-common-0.6.3-manpage-1

max_log_init sgml-common ${SGML_COMMON_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
aclocal >> ${LOGFILE} 2>&1 &&
automake -acf >> ${LOGFILE} 2>&1 &&
autoconf >> ${LOGFILE} 2>&1 &&

CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure ./configure --prefix=/usr --sysconfdir=/etc \
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

install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&
install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat
