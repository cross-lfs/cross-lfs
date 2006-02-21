#!/bin/bash

### libmikmod ###

cd ${SRC}
LOG=libmikmod-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libmikmod-${LIBMIKMOD_VER}
cd ${PKGDIR}

sed -i -e "s/VERSION=10/VERSION=11/" \
       -e "s/sys_asoundlib/alsa_asoundlib/" \
       -e "s/snd_cards/snd_card_load/g" \
       -e "s|sys/asoundlib.h|alsa/asoundlib.h|g" \
    configure.in &&
autoconf &&

max_log_init libmikmod ${LIBMIKMOD_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
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

# TODO: Need to edit /usr/bin/mxmkmf to set the correct libdir ...
# (it really should be setup fom --libdir )
if [ "Y" = "${MULTIARCH}" ]i; then
   use_wrapper /usr/bin/libmikmod-config
fi

chmod 755 /usr/${libdir}/libmikmod.so.2.*
