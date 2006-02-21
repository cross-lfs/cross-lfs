#!/bin/bash

# cross-lfs native automake build
# -------------------------------
# $LastChangedBy: roliver $
# $LastChangedDate: 2005-05-21 15:22:56 +1000 (Sat, 21 May 2005) $
# $LastChangedRevision: 528 $
# $HeadURL: svn+ssh://roliver@be-linux.org/svn/cross-lfs/cross-lfs/trunk/scripts/native-scripts/native-automake.sh $
#

cd ${SRC}
LOG=automake-native.log

set_libdirname
setup_multiarch

unpack_tarball automake-${AUTOMAKE_VER} &&
cd ${PKGDIR}

case ${AUTOMAKE_VER} in
1.4* )
   apply_patch automake-1.4-libtoolize
   apply_patch automake-1.4-subdirs-89656
   apply_patch automake-1.4-ansi2knr-stdlib
   automake_texi=automake.texi
;;
1.5* )
   apply_patch automake-1.5-target_hook
   apply_patch automake-1.5-slot
   apply_patch automake-1.5-test-fixes
   automake_texi=automake.texi
;;
1.6* )
   automake_texi=automake.texi
;;
1.7.9 )
   apply_patch automake-1.7.9-infopage-namechange
   automake_texi=automake.texi
;;
1.8* )
   apply_patch automake-1.8.2-infopage-namechange
   automake_texi=doc/automake.texi
;;
1.9.6 )
   apply_patch automake-1.9.6-infopage-namechange
   automake_texi=doc/automake.texi
;;
esac

export WANT_AUTOCONF=2.5

sed -i -e "/^@setfilename/s|automake|automake${AUTOMAKE_VER:0:3}|" \
       -e "s|automake: (automake)|automake v${AUTOMAKE_VER:0:3}: (automake${AUTOMAKE_VER:0:3})|" \
       -e "s|aclocal: (automake)|aclocal v${AUTOMAKE_VER:0:3}: (automake${AUTOMAKE_VER:0:3})|" \
   ${automake_texi}

max_log_init Automake ${AUTOMAKE_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

case ${AUTOMAKE_VER} in
1.4* )
   min_log_init ${BUILDLOGS} &&
   make pkgdatadir=/usr/share/automake-${AUTOMAKE_VER:0:3} \
        m4datadir=/usr/share/aclocal-${AUTOMAKE_VER:0:3} \
        install \
      >> ${LOGFILE} 2>&1 &&
   echo " o Build OK" || barf
;;
* )
   min_log_init ${BUILDLOGS} &&
   make install \
      >> ${LOGFILE} 2>&1 &&
   echo " o Build OK" || barf
;;
esac

case ${AUTOMAKE_VER} in
1.5 )
   mv /usr/bin/automake /usr/bin/automake-${AUTOMAKE_VER:0:3}
   mv /usr/bin/aclocal /usr/bin/aclocal-${AUTOMAKE_VER:0:3}
   rm -rf /usr/share/automake-${AUTOMAKE_VER:0:3} \
          /usr/share/aclocal-${AUTOMAKE_VER:0:3}
   mv /usr/share/automake /usr/share/automake-${AUTOMAKE_VER:0:3}
   mv /usr/share/aclocal /usr/share/aclocal-${AUTOMAKE_VER:0:3}
;;
esac

ln -sfn ../gnu-config-files/config.sub \
        /usr/share/automake-${AUTOMAKE_VER:0:3}/config.sub
ln -sfn ../gnu-config-files/config.guess \
        /usr/share/automake-${AUTOMAKE_VER:0:3}/config.guess
