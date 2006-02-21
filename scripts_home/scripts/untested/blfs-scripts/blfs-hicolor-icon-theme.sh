#!/bin/bash
#
# hicolor-icon-theme
#
# Dependencies: none
#

cd ${SRC}
LOG=blfs-hicolor-icon-theme.log

set_libdirname
setup_multiarch

unpack_tarball hicolor-icon-theme-${HC_ICON_THEME_VER} &&
cd ${PKGDIR}

max_log_init hicolor-icon-theme ${HC_ICON_THEME_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
 ./configure --prefix=/usr \
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

