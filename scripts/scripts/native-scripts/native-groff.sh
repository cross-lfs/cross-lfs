#!/bin/bash

# cross-lfs native groff build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=groff-native.log

set_libdirname
setup_multiarch

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball groff-${GROFF_VER}
cd ${PKGDIR}

max_log_init Groff ${GROFF_VER} "native (shared)" ${CONFLOGS} ${LOG}

# Assuming page size will be set correctly according to locale
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure \
   --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ln -sf soelim /usr/bin/zsoelim
ln -sf eqn /usr/bin/geqn
ln -sf tbl /usr/bin/gtbl

