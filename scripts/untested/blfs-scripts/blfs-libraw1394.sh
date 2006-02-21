#!/bin/bash

### libraw1394 ###

cd ${SRC}
LOG=libraw1394-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libraw1394-${LIBRAW1394_VER}
cd ${PKGDIR}

max_log_init libraw1394 ${LIBRAW1394_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
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

# device needs to be created
# Output from make dev...
#
# mknod -m 600 /dev/raw1394 c 171 0
# chown root.root /dev/raw1394
#
# /dev/raw1394 created
# It is owned by root with permissions 600.  You may want to fix
# the group/permission to something appropriate for you.
# Note however that anyone who can open raw1394 can access all
# devices on all connected 1394 buses unrestricted, including
# harddisks and other probably sensitive devices.

if [ ! -e /dev/raw1394 ]; then
   make dev
fi
