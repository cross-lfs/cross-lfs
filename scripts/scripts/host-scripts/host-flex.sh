#!/bin/bash

### FLEX ###

cd ${SRC}
LOG=flex-buildhost.build

unpack_tarball flex-${FLEX_VER} &&
cd ${PKGDIR}

case ${FLEX_VER} in
   2.5.31 )
      # Fix brokenness in flex-2.5.31
      apply_patch flex-2.5.31-debian_fixes-2
   ;;
esac

max_log_init Flex ${FLEX_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" ./configure --prefix=${HST_TOOLS} \
   --disable-nls >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
grep "^bigcheck:" Makefile &&
{ 
   make bigcheck \
      >> ${LOGFILE} 2>&1
} || {
   make check \
      >> ${LOGFILE} 2>&1
} &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Create lex wrapper
cat > ${HST_TOOLS}/bin/lex << "EOF"
#!/bin/sh
# Begin ${HST_TOOLS}/bin/lex

exec ${HST_TOOLS}/bin/flex -l "$@"

# End ${HST_TOOLS}/bin/lex
EOF

chmod 755 ${HST_TOOLS}/bin/lex

