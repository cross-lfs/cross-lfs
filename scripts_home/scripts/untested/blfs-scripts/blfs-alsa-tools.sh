#!/bin/bash

### alsa-tools ###

# The only tool of any use to me from here is ac3dec

cd ${SRC}
LOG=alsa-tools-blfs.log

set_libdirname
setup_multiarch

unpack_tarball alsa-tools-${ALSA_TOOLS_VER}
cd ${PKGDIR}

apply_patch alsa-tools-1.0.8-update_ac3dec_config_foo-1

cd ${SRC}/${PKGDIR}/ac3dec

max_log_init alsa-tools ${ALSA_TOOLS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --mandir=/usr/share/man \
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

