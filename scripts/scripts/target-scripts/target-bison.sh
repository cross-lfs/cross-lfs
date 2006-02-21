#!/bin/bash

# cross-lfs target bison build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=bison-target.log

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"
fi

unpack_tarball bison-${BISON_VER} &&
cd ${PKGDIR}

max_log_init Bison ${BISON_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

test -f ${INSTALL_PREFIX}/bin/yacc ||
   cat > ${INSTALL_PREFIX}/bin/yacc << "EOF"
#!/bin/sh
# Begin ${BUILD_PREFIX}/bin/yacc

exec ${BUILD_PREFIX}/bin/bison -y "$@"

# End ${BUILD_PREFIX}/bin/yacc
EOF

chmod 755 ${INSTALL_PREFIX}/bin/yacc
