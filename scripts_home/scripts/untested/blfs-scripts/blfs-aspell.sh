#!/bin/bash

### aspell ###

# TODO: wants ncurses with wide support for utf8...
cd ${SRC}
LOG=aspell-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball aspell-${ASPELL_VER}
cd ${PKGDIR}

# TODO: for biarch, may install these with --program-suffix=${suffix}
#       as the tools dont behave nice when called via a wrapper after
#       being renamed...
#

max_log_init aspell ${ASPELL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
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
   use_wrapper /usr/bin/{aspell,prezip-bin,pspell-config,run-with-aspell}
fi

# TODO: Install a dictionary
