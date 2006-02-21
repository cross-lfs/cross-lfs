#!/bin/bash

# gtk12 
#-------
#
# Dependencies: glib12 X
#

cd ${SRC}
LOG=gtk12-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball "gtk\+-${GTK12_VER}"
cd ${PKGDIR}

apply_patch "gtk\+-1.2.10-update_config_foo-1"

max_log_init gtk12 ${GTK12_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info \
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

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/gtk-config
fi
