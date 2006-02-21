#!/bin/bash

# cross-lfs native module-init-tools build
# ----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=module-init-tools-native.log

set_libdirname
setup_multiarch

unpack_tarball module-init-tools-${MODINITTOOLS_VER} &&
cd ${PKGDIR}

max_log_init Module-init-tools ${MODINITTOOLS_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/ \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# As of 3.1, the manpage creation requires docbook2man
# We do not have this yet
min_log_init ${BUILDLOGS} &&
make DOCBOOKTOMAN="" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Remove any existing binaries
rm /sbin/*mod*

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

#test -f /etc/modules.conf &&
#   ./generate-modprobe.conf /etc/modprobe.conf

