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

# Edits required for 3.1.11 and 3.2.0 beta (except the VERSION edit w 3.2.0)
case ${LIBMIKMOD_VER} in
   3.1.11 )
      apply_patch libmikmod-3.1.11-a

      sed -i -e "s/VERSION=10/VERSION=11/" \
             -e "s/sys_asoundlib/alsa_asoundlib/" \
             -e "s/snd_cards/snd_card_load/g" \
             -e "s|sys/asoundlib.h|alsa/asoundlib.h|g" \
             -e "s/^LIBOBJS/#LIBOBJS/g" \
         configure.in &&
      autoconf || barf
   ;;
   3.2.* )
      sed -i -e "s/sys_asoundlib/alsa_asoundlib/" \
             -e "s/snd_cards/snd_card_load/g" \
             -e "s|sys/asoundlib.h|alsa/asoundlib.h|g" \
             -e "s/^LIBOBJS/#LIBOBJS/g" \
         configure.in &&
      autoconf || barf
   ;;
esac

sed -i -e "/libdir=/s@/lib*@/${libdirname}@g" \
   libmikmod-config.in

max_log_init libmikmod ${LIBMIKMOD_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
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

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/libmikmod-config
fi

case ${LIBMIKMOD_VER} in
   3.1.* ) chmod 755 /usr/${libdirname}/libmikmod.so.2.* ;;
   3.2.* ) chmod 755 /usr/${libdirname}/libmikmod.so.3.* ;;
esac
