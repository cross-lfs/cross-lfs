#!/bin/bash

# cross-lfs cross glibc full build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

LOG="glibc-cross.log"
libdirname=lib

# Test how this script has been called.
# This should only really get called during bi-arch/multi-lib  builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ -z ${ALT_TGT} ]; then ALT_TGT="${TARGET}" ; fi

# if target = build, modify build slightly to
# trick configure to believing we are cross compiling
if [ "${TARGET}" = "${BUILD}" -o "${ALT_TGT}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="install_root=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
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

# if we don't have linuxthreads dirs (ie: a glibc release), then
# unpack the linuxthreads tarball
case ${GLIBC_VER} in
   2.4 | 2.4.* ) ;;
   * )
      if [ ! -d linuxthreads -o ! -d linuxthreads_db ]; then
         OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-linuxthreads-${GLIBC_VER}
         PKGDIR=${OLDPKGDIR}
      fi
   ;;
esac

# unpack libidn add-on if required (should be supplied with cvs versions)
if [ "${USE_LIBIDN}" = "Y" ]; then
case ${target_glibc_ver} in
   2.3.[4-9]* | 2.4* )
      cd ${SRC}/${PKGDIR}
      if [ ! -d libidn ]; then
         OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-libidn-${GLIBC_VER}
         PKGDIR=${OLDPKGDIR}
      fi
   ;;
esac
fi

# apply glibc patches as required depending on the above gcc/kernel versions
# see funcs/glibc_funcs.sh
apply_glibc_patches


# HACK: nptl for sparc64 wont build
case ${TGT_ARCH} in
   sparc64 )
      USE_NPTL=N
   ;;
esac

if [ "Y" = "${NO_GCC_EH}" ]; then
   cd ${SRC}/${PKGDIR}
   if [ ! -f Makeconfig-ORIG ]; then cp -p Makeconfig Makeconfig-ORIG ; fi
   sed 's/-lgcc_eh//g' Makeconfig-ORIG > Makeconfig
fi

if [ "Y" = "${USE_NPTL}" ]; then
   # remove linuxthreads dirs if they exist
   # (CVS source contains linuxthreads)
   if [ -d linuxthreads ]; then rm -rf linuxthreads* ; fi

   # As of ~2003-10-06 nptl is included in glibc cvs
   #test -d ./nptl &&
   #test -d ./nptl_db ||
   #unpack_tarball nptl-${NPTL_VER}

   # fix tst-cancelx7 test
   fname="${SRC}/${PKGDIR}/nptl/Makefile"
   grep tst-cancelx7-ARGS ${fname} > /dev/null 2>&1 ||
   {
      echo " - patching ${fname}"
      mv ${fname} ${fname}-ORIG
      sed -e '/tst-cancel7-ARGS = --command "$(built-program-cmd)"/a\
tst-cancelx7-ARGS = --command "$(built-program-cmd)"' \
         ${fname}-ORIG > ${fname}
   }

   extra_conf="${extra_conf} --with-tls --with-__thread"
else
   if [ -d nptl ]; then rm -rf nptl* ; fi
fi

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

test -d ${SRC}/glibc-${GLIBC_VER}-cross${suffix} &&
   rm -rf ${SRC}/glibc-${GLIBC_VER}-cross${suffix}

mkdir -p ${SRC}/glibc-${GLIBC_VER}-cross${suffix}
cd ${SRC}/glibc-${GLIBC_VER}-cross${suffix}


if [ "${USE_NPTL}" = "Y" ]; then
   echo "libc_cv_forced_unwind=yes" > config.cache
   echo "libc_cv_c_cleanup=yes" >> config.cache
   case ${TGT_ARCH} in
      sparc64 )
         echo "libc_cv_sparc64_tls=yes" >> config.cache
      ;;
   esac
   extra_conf="${extra_conf} --cache-file=config.cache"
fi

# Are libs to be installed into a non-standard place? 
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="${extra_conf} --libdir=${BUILD_PREFIX}/${libdirname}"
   # Also create a configparms file setting slibdir to */${libdirname}
   if [ "${USE_SYSROOT}" = "Y" ]; then
      echo "slibdir=/${libdirname}" >> configparms
   else
      echo "slibdir=${TGT_TOOLS}/${libdirname}" >> configparms
   fi
fi

max_log_init Glibc ${GLIBC_VER} Cross ${CONFLOGS} ${LOG}
BUILD_CC=gcc BUILD_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" CFLAGS="-O2 -pipe" \
CC="${TARGET}-gcc ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --host=${ALT_TGT} --build=${BUILD} \
   --without-cvs --disable-profile --enable-add-ons \
   --with-headers=${KERN_HDR_DIR} ${extra_conf} \
   --with-binutils=${HST_TOOLS}/bin --without-gd \
   --mandir=${BUILD_PREFIX}/share/man \
   --infodir=${BUILD_PREFIX}/share/info \
   --libexecdir=${BUILD_PREFIX}/${libdirname}/glibc \
     >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make SHELL="bash" PARALLELMFLAGS="${PMFLAGS}"  \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o install OK"

