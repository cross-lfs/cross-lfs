#!/bin/bash

### libXvMCW ###

cd ${SRC}
LOG=libXvMCW-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball libXvMCW-${LIBXVMCW_VER}
cd ${PKGDIR}

# update libtool so it will take extra options to CC ( ie CC="gcc -m32" )
libtoolize --force

max_log_init libXvMCW ${LIBXVMCW_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure \
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

cat <<EOF
-------------------------------------------------------
  libXvMCW installs a sample configuration file under
  /etc/X11 ( /etc/X11/XvMCConfig ). Edit this file to
  suit your environment ( by default it references 
  libXvMCNVIDIA_dynamic.so.1 )
-------------------------------------------------------
EOF
