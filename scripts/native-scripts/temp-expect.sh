#!/bin/sh

# cross-lfs temporary expect build (for running testsuites)
# ---------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=expect-temp.log

# Test if the 64 script has been called.
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
else
   BUILD_PREFIX=${TGT_TOOLS}
fi

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"
fi

unpack_tarball expect-${EXPECT_VER} &&
cd ${PKGDIR}

case ${EXPECT_VER} in
   5.3[89]* | 5.40* )
      #apply_patch expect-${EXPECT_VER}
      apply_patch expect-5.39.0-spawn
   ;;
esac

max_log_init Expect ${EXPECT_VER} "temp (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --with-tcl=${BUILD_PREFIX}/${libdirname} \
   --with-x=no --disable-symbols ${extra_conf} \
   --cache-file=/dev/null \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
# 1 test may fail... hopefully not a real concern...
make test \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg 

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf
