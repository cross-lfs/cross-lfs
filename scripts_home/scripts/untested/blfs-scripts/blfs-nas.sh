#!/bin/bash
#
# nas
#
# Dependencies: X
#

cd ${SRC}
LOG=blfs-nas.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball nas-${NAS_VER}.src &&
cd ${PKGDIR}

max_log_init nas ${NAS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
/usr/X11R6/bin/xmkmf \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make World \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
make install.man \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

