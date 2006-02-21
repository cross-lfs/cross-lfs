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
( 
   umask 0 
   umask
   unpack_tarball tetex-texmf-${TETEX_VER}
   unpack_tarball tetex-texmfsrc-${TETEX_VER}
)

umask
PKGDIR=${OLD_PKGDIR}

cd ${SRC}/${PKGDIR}

case ${TETEX_VER} in
   2.0.2 )
      apply_patch tetex-src-2.0.2-flex-1
      apply_patch tetex-src-2.0.2-remove_readlink-1
   ;;
esac

# Additional config if t1lib, gd were built previously
if [ -f /usr/${libdirname}/libt1.a ]; then
   extra_conf="${extra_conf} --with-system-t1lib"
fi

if [ -f /usr/${libdirname}/libgd.a ]; then
   extra_conf="${extra_conf} --with-system-gd"
fi

# Added LDFLAGS to appease libtool w gdlib
max_log_init tetex ${TETEX_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr \
   --with-system-ncurses --with-system-zlib \
   --with-system-pnglib --without-texinfo \
   --exec-prefix=/usr --bindir=/usr/bin ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# TODO: check whether we should use make world or make all.
#       2.0.2 instructions were make world
min_log_init ${BUILDLOGS} &&
make all \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

texconfig dvips paper a4
texconfig font rw
