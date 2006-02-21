#!/bin/bash

# cross-lfs native binutils build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="binutils-native.log"

set_libdirname
setup_multiarch

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball binutils-${BINUTILS_VER} &&

# Determine whether this binutils requires
# 'make configure-host' and whether
# ld search path can be set with --with-lib-path.
# Returned in ${BINUTILS_CONF_HOST} and
# ${BINUTILS_WITH_LIB_PATH} respectively
                                                                                
# TODO: check for architecture specific patches in check_binutils
#       ( alpha )
check_binutils

cd ${SRC}/${PKGDIR}

case ${BINUTILS_VER} in
   # 20031015 - fix static linking issues during testsuite
   #            with current CVS glibc. kernel 2.5.68+
   #            Will only patch HJL 2.14.90.0.[6-7]
   2.14.90.0.[6-7] ) apply_patch binutils-2.14.90.0.7-fix-static-link ;;

   # Issue with HJL binutils 2.15.94.0.1 stripping needed information
   # one manifestation is with stripping TLS info from libc.a
   2.15.94.0.1 ) apply_patch binutils-2.15.94.0.1-fix-strip-1 ;;
esac

# remove libpath from ldscript search paths so we can use
# --libpath= to set library install location 
# ( ie /usr/lib64 if building binutils bins and libs 64bit )
# TODO: we dont need the whole genscripts-multilib patch, we only really
#       need to remove libpath
# TODO: also need to update patches for 2.14.x

case ${BINUTILS_VER} in
   2.14 )
      apply_patch binutils-2.14-genscripts-multilib
   ;;
   2.14.90.0.8 )
      apply_patch binutils-2.14.90.0.8-genscripts-multilib
   ;;
   2.15.9[0124].0.* | 2.15 )
      apply_patch binutils-2.15.91.0.1-genscripts-multilib-2
   ;;
esac

cd ${SRC}
                                                                                
# Remove pre-existing build directory and recreate
test -d binutils-${BINUTILS_VER}-native-build &&
   rm -rf binutils-${BINUTILS_VER}-native-build
                                                                                
mkdir binutils-${BINUTILS_VER}-native-build
cd binutils-${BINUTILS_VER}-native-build

# --host=${TARGET} here, or it will be set *-unknown-linux-gnu
max_log_init Binutils ${BINUTILS_VER} native ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
../${PKGDIR}/configure \
   --prefix=/usr \
   --host=${TARGET} \
   --disable-nls ${extra_conf} \
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
make ${PMFLAGS} LDFLAGS="-s" \
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

# Copy over libiberty.h
cp -p ${SRC}/${PKGDIR}/include/libiberty.h /usr/include/libiberty.h
