#!/bin/bash

### BINUTILS ###

cd ${SRC}
LOG="binutils-buildhost.log"

unpack_tarball binutils-${NATIVE_BINUTILS_VER} &&

# Determine whether this binutils requires
# 'make configure-host' and whether
# ld search path can be set with --with-lib-path.
# Returned in ${BINUTILS_CONF_HOST} and
# ${BINUTILS_WITH_LIB_PATH} respectively
                                                                                
# TODO: check for architecture specific patches in check_binutils
#       ( alpha )
check_binutils

cd ${SRC}/${PKGDIR}
                                                                                
# 20031015 - fix static linking issues during testsuite
#            with current CVS glibc. kernel 2.5.68+
#            Will only patch HJL 2.14.90.0.[6-7]
                                                                                
case ${NATIVE_BINUTILS_VER} in
   2.14.90.0.[6-7] )
      apply_patch binutils-2.14.90.0.7-fix-static-link
   ;;
esac
                                                                                
cd ${SRC}
                                                                                
# Remove pre-existing build directory and recreate
test -d binutils-${NATIVE_BINUTILS_VER}-buildhost-build &&
   rm -rf binutils-${NATIVE_BINUTILS_VER}-buildhost-build
                                                                                
mkdir binutils-${NATIVE_BINUTILS_VER}-buildhost-build
cd binutils-${NATIVE_BINUTILS_VER}-buildhost-build

max_log_init Binutils ${NATIVE_BINUTILS_VER} target ${CONFLOGS} ${LOG}
CC="${CC-gcc}" ../${PKGDIR}/configure \
   --prefix=${HST_TOOLS} \
   --disable-nls \
   --enable-shared \
   --enable-64-bit-bfd \
   >> ${LOGFILE} 2>&1 &&
{
   # Run make configure-host if required
   test Y != "${BINUTILS_CONF_HOST}" ||
   {
      echo -e "\nmake configure-host\n${BRKLN}" >> ${LOGFILE}
      make configure-host >> ${LOGFILE} 2>&1
   }
} &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make -k check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o All OK" || barf

