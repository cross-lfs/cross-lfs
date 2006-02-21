#!/bin/bash

### a2ps ###

cd ${SRC}
LOG=a2ps-blfs.log
libdir=lib

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball a2ps-${A2PS_VER}
cd ${PKGDIR}

# TODO: NEEDS WORK
#       update libtool so we understand newer architectures
#libtoolize --copy --force

sed -i -e "s|emacs||" contrib/Makefile.in &&
sed -i -e "s|/usr/local/share|/usr/share|" configure &&
sed -i -e "s|char \*malloc ();|/* char *malloc (); */|" \
    lib/path-concat.c

max_log_init a2ps ${A2PS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --sysconfdir=/etc/a2ps --localstatedir=/var \
   --enable-shared --mandir=/usr/share/man \
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

