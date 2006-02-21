#!/bin/bash

# cross-lfs target flex build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=flex-target.build

unpack_tarball flex-${FLEX_VER} &&
cd ${PKGDIR}

#if we are building multi-arch, only build for the default env
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

if [ ! "${LIBDIRNAME}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"
fi

case ${FLEX_VER} in
   2.5.31 )
      # Fix brokenness in flex-2.5.31
      apply_patch flex-2.5.31-debian_fixes-2
      # do not regen doc (triggered by above patch)
      touch ./doc/flex.1
   ;;
esac

max_log_init Flex ${FLEX_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} ${extra_conf} \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
#make ${PMFLAGS} LDFLAGS="-s" \
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Create lex wrapper
cat > ${INSTALL_PREFIX}/bin/lex << "EOF"
#!/bin/sh
# Begin ${BUILD_PREFIX}/bin/lex

exec ${BUILD_PREFIX}/bin/flex -l "$@"

# End ${BUILD_PREFIX}/bin/lex
EOF

chmod 755 ${INSTALL_PREFIX}/bin/lex

