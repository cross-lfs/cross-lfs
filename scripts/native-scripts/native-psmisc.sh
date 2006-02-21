#!/bin/bash

# cross-lfs native psmisc build
# -----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=psmisc-native.log

set_libdirname
setup_multiarch

unpack_tarball psmisc-${PSMISC_VER} &&
cd ${PKGDIR}

# Patch psmisc so we can pass CFLAGS from env during configure
for file in src/Makefile.in src/Makefile.am ; do
   test -f ${file}-ORIG ||
      cp ${file} ${file}-ORIG
   sed 's/CFLAGS =/& @CFLAGS@/' ${file}-ORIG > ${file}
done

# Remove newline in killall.c
case ${PSMISC_VER} in
   21.2 )
      test -f src/killall.c-ORIG ||
         cp src/killall.c src/killall.c-ORIG
      # HACK - escape wrongly embedded newline (line 398)
      sed 's@precede other$@& \\@' src/killall.c-ORIG > src/killall.c
   ;;
esac

max_log_init Psmisc ${PSMISC_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr --exec-prefix=/ \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
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

