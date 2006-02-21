#!/bin/bash

# cross-lfs native libtool build
# ------------------------------
# $LastChangedBy: roliver $
# $LastChangedDate: 2005-05-21 15:22:56 +1000 (Sat, 21 May 2005) $
# $LastChangedRevision: 528 $
# $HeadURL: svn+ssh://roliver@be-linux.org/svn/cross-lfs/cross-lfs/trunk/scripts/native-scripts/native-libtool.sh $
#

cd ${SRC}
LOG=libtool-native.log

SELF=`basename ${0}`
DIR=`dirname ${0}`
PATCHES=${DIR}/patches
export PATCHES

set_buildenv
set_libdirname
setup_multiarch

if [ ! "{libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

### LIBTOOL ###
unpack_tarball libtool-${LIBTOOL_VER} &&
cd ${PKGDIR}

# Gentoo fixes for libtool...
#--------------------------------------------------
rm -f ltmain.sh

apply_patch libtool-1.4.2-multilib
apply_patch libtool-1.4.3-lib64
apply_patch libtool-1.4.2-archive-shared
apply_patch libtool-1.5.6-ltmain-SED
apply_patch libtool-1.4.2-expsym-linux
apply_patch libtool-1.4.3-pass-thread-flags
apply_patch libtool-1.5.14-ltmain_sh-max_cmd_len
apply_patch libtool-1.5-filter-host-tags
apply_patch libtool-1.5.10-locking
apply_patch libtool-1.5.14-egrep


rm -f ltmain.shT
date=`./mkstamp < ./ChangeLog` && \
eval `egrep '^[[:space:]]*PACKAGE' configure` && \
eval `egrep '^[[:space:]]*VERSION' configure` && \
sed -e "s/@PACKAGE@/${PACKAGE}/" -e "s/@VERSION@/${VERSION}/" \
    -e "s%@TIMESTAMP@%$date%" ./ltmain.in > ltmain.shT

mv -f ltmain.shT ltmain.sh

cp libtool.m4 acinclude.m4

touch acinlude.m4
aclocal
automake -c -a
autoconf

cd libltdl
touch acinlude.m4
aclocal
automake -c -a
autoconf

cd ${SRC}/${PKGDIR}

#--------------------------------------------------

max_log_init Libtool ${LIBTOOL_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make \
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

rm -f /usr/share/libtool/config.{guess,sub}
rm -f /usr/share/libtool/libltdl/config.{guess,sub}
ln -sfn ../gnu-config-files/config.sub /usr/share/libtool/config.sub
ln -sfn ../gnu-config-files/config.guess /usr/share/libtool/config.guess
ln -sfn ../../gnu-config-files/config.sub \
        /usr/share/libtool/libltdl/config.sub
ln -sfn ../../gnu-config-files/config.guess \
        /usr/share/libtool/libltdl/config.guess

ldconfig

