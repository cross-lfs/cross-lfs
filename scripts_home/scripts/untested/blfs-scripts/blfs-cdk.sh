#!/bin/bash

### cdk ###
#  http://dickey.his.com/cdk/cdk.html

cd ${SRC}
LOG=cdk-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball cdk-${CDK_VER}
cd ${PKGDIR}

if [ ! -f Makefile.in-orig ]; then
   cp -p Makefile.in Makefile.in-orig

   sed 's@gcc@$(CC)@g' Makefile.in-orig > Makefile.in
fi

max_log_init cdk ${CDK_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS} -fPIC" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
(
   make all
   make cdkshlib
) >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
( 
   make install &&
   make installCDKSHLibrary 
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

