#!/bin/bash

### mDNS ###

cd ${SRC}
LOG=mDNS-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball mDNSResponder-${MDNS_VER}
cd ${PKGDIR}/mDNSPosix

if [ ! "${libdirname}" = "lib" ]; then
   sed -i -e "/^NSSINSTPATH :=/s@/lib@/${libdirname}@g" \
          -e "s@/lib/@/${libdirname}/@g" \
          -e 's@^CFLAGS =@CFLAGS +=@g' \
       Makefile
fi

# Ignoring the java build... this has to be done after install of libdns_sd
# If doing the libjdns_sd build, set JDK to JAVA_HOME...

max_log_init mDNS ${MDNS_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
make os=linux \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   LD="${LD-ld} ${ARCH_LDFLAGS} -shared" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make os=linux install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

