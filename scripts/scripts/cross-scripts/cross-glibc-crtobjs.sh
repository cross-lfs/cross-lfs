#!/bin/bash

# cross-lfs glibc startfiles build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

# Defaults
LOG="glibc-cross-crt-objs.log"
libdirname=lib


# Test how this script has been called.
# This should only really get called during bi-arch/multi-lib  builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ -z "${ALT_TGT}" ]; then ALT_TGT="${TARGET}" ; fi

# if target = build, modify build slightly to
# trick configure into believing we are cross compiling
# and avoid some configure checks
if [ "${TARGET}" = "${BUILD}" -o "${ALT_TGT}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
fi

if [ "${USE_SANITISED_HEADERS}" = "Y" ]; then
   KERN_HDR_DIR="${INSTALL_PREFIX}/kernel-hdrs"
else
   KERN_HDR_DIR="${INSTALL_PREFIX}/include"
fi

unpack_tarball glibc-${GLIBC_VER}
cd ${PKGDIR}

# Gather package version information
#-----------------------------------
target_glibc_ver=`grep VERSION version.h | \
   sed 's@.*\"\([0-9.]*\)\"@\1@'`
export target_glibc_ver

# Retrieve target_gcc_ver from gcc -v output
target_gcc_ver=`${TARGET}-gcc -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

# check kernel headers for version
kernver=`grep UTS_RELEASE ${KERN_HDR_DIR}/linux/version.h | \
         sed 's@.*\"\([0-9.]*\).*\"@\1@g' `

if [ ! -d linuxthreads -o ! -d linuxthreads_db ]; then
   cd ${SRC}/${PKGDIR}
   OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-linuxthreads-${GLIBC_VER}
   PKGDIR=${OLDPKGDIR}
fi

# unpack libidn add-on if required (should be supplied with cvs versions)
case ${target_glibc_ver} in
   2.3.[4-9]* | 2.4* )
      cd ${SRC}/${PKGDIR}
      if [ ! -d libidn ]; then
         OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-libidn-${GLIBC_VER}
         PKGDIR=${OLDPKGDIR}
      fi
   ;;
esac

# apply glibc patches as required depending on the above gcc/kernel versions
# see funcs/glibc_funcs.sh
apply_glibc_patches

# set without-fp if target has no floating point unit
if [ "${WITHOUT_FPU}" = "Y" ]; then
   extra_conf="${extra_conf} --without-fp"
fi

# set --enable-kernel to match the kernel version 
# of the kernel headers glibc is to be built against
#-------------------------------------------------
# HACK: hack around 2.6.8.1 release
case ${kernver} in 2.6.8.* ) kernver=2.6.8 ;; esac
extra_conf="${extra_conf} --enable-kernel=${kernver}"

test -d ${SRC}/glibc-${GLIBC_VER}-crtobjs${suffix} &&
   rm -rf ${SRC}/glibc-${GLIBC_VER}-crtobjs${suffix}

mkdir -p ${SRC}/glibc-${GLIBC_VER}-crtobjs${suffix}
cd ${SRC}/glibc-${GLIBC_VER}-crtobjs${suffix}

if [ "${USE_NPTL}" = "Y" ]; then
   extra_conf="${extra_conf} --enable-add-ons=nptl"
   extra_conf="${extra_conf} --with-tls --with-__thread"
   echo "libc_cv_forced_unwind=yes" > config.cache
   echo "libc_cv_c_cleanup=yes" >> config.cache

   # TODO: check for biarch etc
   case ${TGT_ARCH} in
      sparc64* | ultrasparc* )
         echo "libc_cv_sparc64_tls=yes" >> config.cache
      ;;
   esac

   extra_conf="${extra_conf} --cache-file=config.cache"
else
   extra_conf="${extra_conf} --enable-add-ons=linuxthreads"
fi

max_log_init Glibc ${GLIBC_VER} Cross ${CONFLOGS} ${LOG}
BUILD_CC=gcc BUILD_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" \
CFLAGS="-O2 -pipe" \
CC="${TARGET}-gcc ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --host=${ALT_TGT} --build=${BUILD} \
   --without-cvs \
   --disable-profile ${extra_conf} \
   --with-headers=${KERN_HDR_DIR} \
   --with-binutils=${HST_TOOLS}/bin \
     >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

# OK, we have an issue when building on solaris, make invokes /bin/sh
# by default. Issue is primarily with the System V /bin/echo which always
# expands and interprets special characters (such as \n) instead of just
# echoing the string. The invoked /bin/sh does not inherit our set PATH and
# use the bsd style echo we created earlier. 
# To get around this issue we will just force make to use "bash" as
# its shell and use bash's internal echo, which works how we would expect it.

min_log_init ${BUILDLOGS} &&
make SHELL="bash" PARALLELMFLAGS="${PMFLAGS}" csu/subdir_lib \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&

mkdir -p ${INSTALL_PREFIX}/${libdirname} &&
cp -fp csu/crt[1in].o ${INSTALL_PREFIX}/${libdirname} &&
echo " o install OK"

