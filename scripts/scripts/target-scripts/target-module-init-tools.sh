#!/bin/bash

# cross-lfs target module-init-tools build
# ----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# NOTE: this installs into the target root, NOT into ${TGT_TOOLS}
cd ${SRC}
LOG=module-init-tools-target.log

set_libdirname
setup_multiarch

unpack_tarball module-init-tools-${MODINITTOOLS_VER} &&
cd ${PKGDIR}

# Patch so we can run 'make moveold' under our target root.
# TODO: wrap this with some logic
apply_patch module-init-tools-3.0-cross-moveold

max_log_init Module-init-tools ${MODINITTOOLS_VER} "Target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe" \
./configure --prefix=/ --host="${TARGET}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# H A C K 
sed -i 's@^MAN.*@@g' Makefile

min_log_init ${BUILDLOGS} &&

# Check if modprobe.old exists, if so don't run
# make moveold

if [ ! -f ${LFS}/sbin/modprobe.old -a -f ${LFS}/sbin/modprobe ]; then
   make DESTDIR="${LFS}" moveold \
      >> ${LOGFILE} 2>&1 &&
   echo "===============================================" \
      >> ${LOGFILE} || barf
fi

make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make DESTDIR="${LFS}" install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

#test -f ${LFS}/etc/modules.conf &&
#   ./generate-modprobe.conf /etc/modprobe.conf

