#!/bin/bash

# cross-lfs cross-binutils build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="binutils-cross.log"

#NOTE: This to be revisited... could well be satisfied by setup_multiarch...
set -x

if [ "Y" = "${MULTIARCH}" ]; then
   vendor_os=`echo ${TARGET} | sed 's@\([^-]*\)-\(.*\)@\2@'`
   case ${TGT_ARCH} in
      x86_64 )
      ;;
      mipsel* | mips64el )
         TARGET=mips64el-${vendor_os}
      ;;
      sparc* )
         TARGET=sparc64-${vendor_os}
      ;;
      powerpc* | ppc* )
         TARGET=powerpc64-${vendor_os}
      ;;
      s390* )
         TARGET=s390x-${vendor_os}
      ;;
      * )
         # TODO: add some error messages etc
         barf
      ;;
   esac
fi

# if target is same as build host, adjust host slightly to
# trick configure so we do not produce native tools
if [ "${TARGET}" = "${BUILD}" ]; then
   althost=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
   extra_conf="--host=${althost}"
fi
     
set +x
 
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
                                                                                
# Check if we have sysroot set
if [ "${USE_SYSROOT}" = "Y" ]; then
   # if sysroot not already defined, set it to ${LFS}
   extra_conf="${extra_conf} --with-sysroot=${LFS}"
   INSTALL_PREFIX=${LFS}/usr
else
   # sysroot not set, just set libpath
   test Y == "${BINUTILS_WITH_LIB_PATH}" &&
      BINUTILS_LIB_PATH="--with-lib-path=${TGT_TOOLS}/lib" ||
      BINUTILS_LIB_PATH=""

   INSTALL_PREFIX=${TGT_TOOLS}
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
   # Following works for HJL and FSF binutils 2.15
   2.15.9[0124].0.* | 2.15 )
      apply_patch binutils-2.15.91.0.1-genscripts-multilib-2
   ;;
   # Following works for HJL and FSF binutils 2.15
   2.16* )
      apply_patch binutils-2.15.91.0.1-genscripts-multilib-2
   ;;
esac

cd ${SRC}
                                                                                
# Remove pre-existing build directory and recreate
test -d binutils-${BINUTILS_VER}-cross-build &&
   rm -rf binutils-${BINUTILS_VER}-cross-build
                                                                                
mkdir binutils-${BINUTILS_VER}-cross-build
cd binutils-${BINUTILS_VER}-cross-build

max_log_init Binutils ${BINUTILS_VER} Cross ${CONFLOGS} ${LOG}
../${PKGDIR}/configure --prefix=${HST_TOOLS} \
   --target=${TARGET} ${extra_conf} --disable-nls \
   --enable-shared ${SYSROOT_OPTS} \
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
#make ${PMFLAGS} headers -C bfd \
make headers -C bfd \
   >> ${LOGFILE} 2>&1 &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o All OK" || barf

# Copy over libiberty.h
cp -p ${SRC}/${PKGDIR}/include/libiberty.h ${INSTALL_PREFIX}/include/libiberty.h

