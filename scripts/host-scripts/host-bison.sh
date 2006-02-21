#!/bin/bash

### BISON ###

cd ${SRC}
LOG=bison-buildhost.log

unpack_tarball bison-${BISON_VER} &&
cd ${PKGDIR}

max_log_init Bison ${BISON_VER} "buildhost (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" CFLAGS="-O2 -pipe" ./configure --prefix=${HST_TOOLS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

test -f ${HST_TOOLS}/bin/yacc ||
   cat > ${HST_TOOLS}/bin/yacc << "EOF"
#!/bin/sh
# Begin ${HST_TOOLS}/bin/yacc

exec ${HST_TOOLS}/bin/bison -y "$@"

# End ${HST_TOOLS}/bin/yacc
EOF

chmod 755 ${HST_TOOLS}/bin/yacc
