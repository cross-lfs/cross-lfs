#!/bin/bash

# cross-lfs target iproute2 build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=iproute2-target.log
set_libdirname
setup_multiarch

unpack_tarball iproute2-${IPROUTE2_VER}
cd ${PKGDIR}

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_BASEDIR=""
   BUILD_PREFIX="/usr"
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_BASEDIR=${TGT_TOOLS}
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX=${TGT_TOOLS}
   INSTALL_OPTIONS=""
fi

test -f tc/Makefile-ORIG || cp -p tc/Makefile tc/Makefile-ORIG
chmod 666 tc/Makefile
sed -e "s@/usr/lib@${BUILD_PREFIX}/${libdirname}@g" \
    -e 's@\(install[-a-zA-Z0-9 ]*\)-s@\1@g' \
    tc/Makefile-ORIG > tc/Makefile

test -f misc/Makefile-ORIG || cp -p misc/Makefile misc/Makefile-ORIG
chmod 666 misc/Makefile
sed -e '/^TARGETS/s@arpd@@g' \
    -e 's@\(install[-a-zA-Z0-9 ]*\)-s@\1@g' \
    misc/Makefile-ORIG > misc/Makefile

# Bleh, configure sometimes is not executable
chmod 755 ./configure

max_log_init iproute2 ${IPROUTE2_VER} "target (shared)" ${CONFLOGS} ${LOG}
./configure ${INSTALL_PREFIX}/include \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make CC="${TARGET}-gcc ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
     AR="${TARGET}-ar" \
     SBINDIR="${BUILD_BASEDIR}/sbin" \
     CONFDIR="${BUILD_BASEDIR}/etc/iproute2" \
     DOCDIR="${BUILD_PREFIX}/share/doc/iproute2" \
     KERNEL_INCLUDE="${BUILD_PREFIX}/include" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
su -c "make CC=\"${TARGET}-gcc ${ARCH_CFLAGS}\" \
     AR=\"${TARGET}-ar\" \
     SBINDIR=\"${BUILD_BASEDIR}/sbin\" \
     CONFDIR=\"${BUILD_BASEDIR}/etc/iproute2\" \
     DOCDIR=\"${BUILD_PREFIX}/share/doc/iproute2\" \
     KERNEL_INCLUDE=\"${BUILD_PREFIX}/include\" \
     ${INSTALL_OPTIONS} install" \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # for LFS bootscripts
   if [ ! -d ${LFS}/sbin ]; then mkdir -p ${LFS}/sbin ; fi
   ln -sf ..${TGT_TOOLS}/sbin/ip ${LFS}/sbin
fi

