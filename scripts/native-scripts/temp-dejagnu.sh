#!/bin/bash

# cross-lfs temporary dejagnu build (for running testsuites)
# ----------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=dejagnu-temp.log

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
else
   BUILD_PREFIX=${TGT_TOOLS}
fi

unpack_tarball dejagnu-${DEJAGNU_VER} &&
cd ${PKGDIR}

max_log_init Dejagnu ${DEJAGNU_VER} "temp (shared)" ${CONFLOGS} ${LOG}
./configure --prefix=${BUILD_PREFIX} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make  \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf
