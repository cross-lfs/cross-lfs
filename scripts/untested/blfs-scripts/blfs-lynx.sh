#!/bin/bash

### lynx ###

cd ${SRC}
LOG=lynx-blfs.log

set_libdirname
setup_multiarch

unpack_tarball lynx${LYNX_VER}
cd ${PKGDIR}

# Do we want to use slang, curses or ncurses?
# need to set --with-screen=
if [ "${USE_SLANG}" = "Y" ]; then
   extra_conf="--with-screen=slang"
fi

max_log_init lynx ${LYNX_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure \
   --prefix=/usr --libdir=/etc \
   --with-zlib --with-bzlib \
   --with-ssl ${extra_conf} \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS}
make \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}
make install \
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

