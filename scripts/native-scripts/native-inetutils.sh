#!/bin/bash

# cross-lfs native inetutils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=inetutils-native.log

set_libdirname
setup_multiarch

unpack_tarball inetutils-${INETUTILS_VER}
cd ${PKGDIR}

# Retrieve target_gcc_ver from gcc -v output
target_gcc_ver=`${TARGET}-gcc -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

case ${target_gcc_ver} in
   4.* )
      apply_patch inetutils-1.4.2-gcc4_fixes-1
   ;;
esac

max_log_init inetutils ${INETUTILS_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --libexecdir=/usr/${libdirname}/inetutils \
   --sysconfdir=/etc --localstatedir=/var \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --disable-whois --disable-syslogd --disable-logger --disable-servers \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

mv /usr/bin/ping /bin/

