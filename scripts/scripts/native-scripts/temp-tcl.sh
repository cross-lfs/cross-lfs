#!/bin/bash

# cross-lfs temporary tcl build (for running testsuites)
# ------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=tcl-temp.log

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
else
   BUILD_PREFIX=${TGT_TOOLS}
fi

unpack_tarball tcl${TCL_VER}-src &&
cd ${PKGDIR}/unix

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"

   # Change TCL_LIBRARY in Makefile so it is under $(libdir)
   test -f Makefile.in-ORIG || cp -p Makefile.in Makefile.in-ORIG
   sed '/TCL_LIBRARY/s@\$(prefix)/lib@$(libdir)@g' \
      Makefile.in-ORIG > Makefile.in
fi

max_log_init Tcl ${TCL_VER} "temp (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make test \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&
# clock test may fail... not a real concern for our purposes...

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

# Following for ~tcl 8.4.12
case ${TCL_VER} in
   8.4.1[2-9]* )
      make install-private-headers \
         >>  ${LOGFILE} 2>&1 &&
      echo " o install-private-headers OK" || barf
   ;;
esac

# Create symlink for tclsh
TCLSH=$(basename $(find ${BUILD_PREFIX}/bin -type f -name tclsh\*))
test "tclsh" != "${TCLSH}" &&
   ln -sf ./${TCLSH} ${BUILD_PREFIX}/bin/tclsh

