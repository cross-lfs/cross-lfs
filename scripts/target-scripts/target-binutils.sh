#!/bin/bash

# cross-lfs target binutils build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="binutils-target.log"

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


# HACK
if [ ! "X${TGT_CFLAGS}" = "X" ]; then
	ARCH_CFLAGS="${TGT_CFLAGS} ${ARCH_CFLAGS}"
fi

# if target is same as build host, adjust build slightly to avoid running
# configure checks which we cannot run
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
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

## Check if we have sysroot set
if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # sysroot not set, just set libpath
   test Y == "${BINUTILS_WITH_LIB_PATH}" &&
      BINUTILS_LIB_PATH="--with-lib-path=${TGT_TOOLS}/lib" ||
      BINUTILS_LIB_PATH=""
fi

# These are probably not required for sysrooted builds, but
# they don't hurt...
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
   2.16* )
      apply_patch binutils-2.15.91.0.1-genscripts-multilib-2
   ;;
esac

cd ${SRC}
                                                                                
# Remove pre-existing build directory and recreate
test -d binutils-${BINUTILS_VER}-target-build &&
   rm -rf binutils-${BINUTILS_VER}-target-build
                                                                                
mkdir binutils-${BINUTILS_VER}-target-build
cd binutils-${BINUTILS_VER}-target-build

max_log_init Binutils ${BINUTILS_VER} target ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" ../${PKGDIR}/configure \
   --prefix=${BUILD_PREFIX} \
   --build=${BUILD} \
   --host=${TARGET} \
   --target=${TARGET} \
   --disable-nls ${extra_conf} \
   --enable-shared \
   --enable-64-bit-bfd ${BINUTILS_LIB_PATH} \
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
make headers -C bfd \
   >> ${LOGFILE} 2>&1 &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o All OK" || barf

# Copy over libiberty.h
cp -p ${SRC}/${PKGDIR}/include/libiberty.h ${INSTALL_PREFIX}/include/libiberty.h
