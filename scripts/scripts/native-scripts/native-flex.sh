#!/bin/bash

# cross-lfs native flex build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=flex-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball flex-${FLEX_VER} &&
cd ${PKGDIR}

case ${FLEX_VER} in
   2.5.31 )
      # Fix brokenness in flex-2.5.31
      apply_patch flex-2.5.31-debian_fixes-2
      # do not regen doc (triggered by above patch)
      touch ./doc/flex.1
   ;;
esac

max_log_init Flex ${FLEX_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Create lex wrapper
cat > /usr/bin/lex << "EOF"
#!/bin/sh
# Begin /usr/bin/lex

exec /usr/bin/flex -l "$@"

# End /usr/bin/lex
EOF

chmod 755 /usr/bin/lex

