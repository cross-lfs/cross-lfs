#!/bin/bash
#
# fam
#
# Dependencies: portmap
#

cd ${SRC}
LOG=blfs-fam.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball fam-${FAM_VER} &&
cd ${PKGDIR}

# There are issues with linux-libc-headers and the dnotify patch
# For now comment out
#case ${FAM_VER} in
#   2.7.0 )
#      apply_patch fam-2.7.0-dnotify-1
#   ;;
#   * )
#      echo "*** Please check if fam ${FAM_VER} requires patching ***"
#      echo "*** then please update this script (and send patch)      ***"
#      exit 1
#   ;;
#esac

max_log_init fam ${FAM_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
 ./configure --prefix=/usr --build="${TARGET}" \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --sysconfdir=/etc ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

