#!/bin/bash

# cross-lfs native iproute2 build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# TODO: look into whether this needs to install libs... if
#       so, use libdirname...
cd ${SRC}
LOG=iproute2-native.log
set_libdirname
setup_multiarch

unpack_tarball iproute2-${IPROUTE2_VER}
cd ${PKGDIR}

test -f misc/Makefile-ORIG || cp -p misc/Makefile misc/Makefile-ORIG
chmod 666 misc/Makefile
sed -e '/^TARGETS/s@arpd@@g' \
    misc/Makefile-ORIG > misc/Makefile

# gah, configure wasn't executable
chmod 775 configure

max_log_init iproute2 ${IPROUTE2_VER} "native (shared)" ${CONFLOGS} ${LOG}
./configure \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" SBINDIR="/sbin" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make SBINDIR=/sbin install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

