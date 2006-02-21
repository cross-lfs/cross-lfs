#!/bin/bash

# cross-lfs native autoconf build
# -------------------------------
# $LastChangedBy: roliver $
# $LastChangedDate: 2005-05-21 15:22:56 +1000 (Sat, 21 May 2005) $
# $LastChangedRevision: 528 $
# $HeadURL: svn+ssh://roliver@be-linux.org/svn/cross-lfs/cross-lfs/trunk/scripts/native-scripts/native-autoconf.sh $
#

cd ${SRC}
LOG=autoconf-native.log

echo ${AUTOCONF_VER}
set_libdirname
setup_multiarch

unpack_tarball autoconf-${AUTOCONF_VER} &&
cd ${PKGDIR}

# From gentoo
case ${AUTOCONF_VER} in
2.1* )
   sed -i -e "s@\* Autoconf:@\* Autoconf v${AUTOCONF_VER:0:3}:@" \
          -e '/START-INFO-DIR-ENTRY/ i INFO-DIR-SECTION GNU programming tools' \
      autoconf.texi
;;
2.59 )
   apply_patch autoconf-2.59-more-quotes
;;
esac

max_log_init Autoconf ${AUTOCONF_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --program-suffix="-${AUTOCONF_VER}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

case ${AUTOCONF_VER} in
2.5* )
   sed -i "/^program_transform_name/s@-${AUTOCONF_VER}@@" man/Makefile
;;
esac

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

#min_log_init ${TESTLOGS} &&
#make check \
#   >>  ${LOGFILE} 2>&1 &&
#echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
      >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

mv /usr/share/info/autoconf.info \
   /usr/share/info/autoconf-${AUTOCONF_VER}.info
