#!/bin/bash

# cross-lfs native procps build
# -----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=procps-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

# TODO: look into how this is handled on non x86_64 and non multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_makeopts="lib64=${libdirname}"
fi

unpack_tarball procps-${PROCPS_VER} &&
cd ${PKGDIR}

# Following sed implements the LFS procps patch 
#   apply_patch procps-${PROCPS_VER}
# (20030404: works for procps 3.1.5 - 3.1.8)
# Not required for 3.2.x
#test -f w.c-ORIG ||
#   cp w.c w.c-ORIG
#sed 's@setlocale(LC_ALL, "")@setlocale(LC_NUMERIC, "C")@' w.c-ORIG \
#   > w.c

# Mod Makefile, pass extra LDFLAGS from env
# change install dirs to lib64 if biarch

test -f Makefile-ORIG ||
   cp Makefile Makefile-ORIG

LDFLAGS="-s" 

sed -e "s/LDFLAGS :=.*/& ${LDFLAGS}/" \
    -e "s@^\(lib64.*:= \).*@\1${libdirname}@g" \
    Makefile-ORIG > Makefile

max_log_init Procps ${PROCPS_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     CFLAGS="-O2 -pipe ${TGT_CFLAGS}" ${extra_makeopts} \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make CC="${CC-gcc} ${ARCH_CFLAGS}" ${extra_makeopts} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

