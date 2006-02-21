#!/bin/bash

### tetex ###

cd ${SRC}
LOG=tetex-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball tetex-src-${TETEX_VER}
#save pkgdir
OLD_PKGDIR=${PKGDIR}
mkdir -p /usr/share/texmf
cd /usr/share/texmf
unpack_tarball tetex-texmf-${TETEX_VER}
unpack_tarball tetex-texmfsrc-${TETEX_VER}

PKGDIR=${OLD_PKGDIR}

cd ${SRC}/${PKGDIR}

apply_patch tetex-src-2.0.2-flex-1
apply_patch tetex-src-2.0.2-remove_readlink-1

max_log_init tetex ${TETEX_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --with-system-ncurses --with-system-zlib \
   --with-system-pnglib --without-texinfo \
   --exec-prefix=/usr --bindir=/usr/bin ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make world \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

texconfig dvips paper a4
texconfig font rw
