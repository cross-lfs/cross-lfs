#!/bin/bash

# cross-lfs cross glibc header creation
# -------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="glibc-cross-headers.log"
unpack_tarball glibc-${GLIBC_VER}

cd ${PKGDIR}
#3.1b1 - get real version of the glibc we are installing 20030527
target_glibc_ver=`grep VERSION version.h | \
   sed 's@.*\"\([0-9.]*\)\"@\1@'`
export target_glibc_ver

# if target is same as build host, adjust build slightly
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

# unpack linuxthreads add-on if required
if [ ! "Y" = "${USE_NPTL}" -a ! -d ${SRC}/${PKGDIR}/linuxthreads ]; then
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

# MIPS specific fixes   
case ${TGT_ARCH} in
   mips* )
     # Fix syscalls for mips w 2.3.4 
      case ${GLIBC_VER} in
         2.3.[45] ) apply_patch glibc-2.3.4-mips_syscall-2 ;;
      esac
      # For mips we need to use a mips compiler for generating headers
      # this should have been created by cross-gcc-static-no-thread.sh
      CC="${TARGET}-gcc"
   ;;
esac

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

test -d ${SRC}/glibc-${GLIBC_VER}-hdrs &&
   rm -rf ${SRC}/glibc-${GLIBC_VER}-hdrs

mkdir -p ${SRC}/glibc-${GLIBC_VER}-hdrs
cd ${SRC}/glibc-${GLIBC_VER}-hdrs
max_log_init Glibc ${GLIBC_VER} Cross ${CONFLOGS} ${LOG}

# NOTE: ran into this during nptl configury
# TODO: look into if this is required wo nptl
if [ "Y" = ${USE_NPTL} ]; then
   case ${TGT_ARCH} in
      powerpc* | ppc* )
         echo "libc_cv_ppc_machine=yes" >> config.cache
      ;;
   esac
fi

# set without-fp if target has no floating point unit
if [ "${WITHOUT_FPU}" = "Y" ]; then
   extra_conf="${extra_conf} --without-fp"
fi

# HACK: hack around 2.6.8.1 release
case ${KERNEL_VER} in 2.6.8.* ) KERNEL_VER=2.6.8 ;; esac

# Have to use the hosts cpp to generate the headers
CC=${CC-gcc} ../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} --build=${BUILD} \
   --without-cvs --disable-sanity-checks \
   --enable-kernel=${KERNEL_VER} \
   --with-headers=${KERN_HDR_DIR} \
   --with-binutils=${HST_TOOLS}/${TARGET}/bin \
   --cache-file=config.cache ${extra_conf} \
     >> ${LOGFILE} 2>&1 &&

# Use target ld gas et al
PATH=${HST_TOOLS}/${TARGET}/bin:${PATH} \
make ${INSTALL_OPTIONS} install-headers \
   >> ${LOGFILE} 2>&1 &&
echo " o install-headers OK" || barf

echo " include/bits should have been created"
cp bits/stdio_lim.h ${INSTALL_PREFIX}/include/bits &&
touch ${INSTALL_PREFIX}/include/gnu/stubs.h 

# copy across threading headers
cd ${SRC}/${PKGDIR}

# Firstly we need to use the correct directory for our target
# arch. All ix86 builds should point to i386, sparc/sparc32/sparc64
# to point to sparc, powerpc/powerpc64 to powerpc etc...
case ${TGT_ARCH} in
   i?86 )
     ARCH=i386
   ;;
   x86_64 )
     ARCH=x86_64
     TYPE=x86_64
   ;;
   sparc64* )
     ARCH=sparc
     TYPE=sparc64
   ;;
   sparc* )
     ARCH=sparc
     TYPE=sparc32
   ;;
   alpha )
     ARCH=alpha
   ;;
   powerpc64 | ppc64 )
     ARCH=powerpc
     TYPE=powerpc64
   ;;
   powerpc | ppc )
     ARCH=powerpc
     TYPE=powerpc32
   ;;
   s390x )
     ARCH=s390
     TYPE=s390x
   ;;
   s390 )
     ARCH=s390
     TYPE=s390
   ;;
   mips* )
     ARCH=mips
   ;;
esac

if [ "${USE_NPTL}" = "Y" ]; then

   #NPTL
   cp nptl/sysdeps/pthread/pthread.h ${INSTALL_PREFIX}/include/
   cp nptl/sysdeps/unix/sysv/linux/${ARCH}/bits/pthreadtypes.h \
      ${INSTALL_PREFIX}/include/bits/

   # On s390, powerpc and sparc we also need to get 
   # sysdeps/${ARCH}/${TGT_ARCH}/bits/wordsize.h

   # As of 20040909 pthread.h pulls in bits/wordsize.h .
   # TODO: investigate whether the correct wordsize.h gets copied
   #       across for a straight 64bit target (alpha) when doing this
   #       on a 32bit system. ( see sysdeps/wordsize-{32,64} )
   if [ -f sysdeps/${ARCH}/${TYPE}/bits/wordsize.h ]; then
      if [ ! -f ${INSTALL_PREFIX}/include/bits/wordsize.h ]; then
         echo " - copying sysdeps/${ARCH}/${TYPE}/bits/wordsize.h"
         cp sysdeps/${ARCH}/${TYPE}/bits/wordsize.h ${INSTALL_PREFIX}/include/bits/
      fi
   fi

else

   #Linuxthreads
   cp linuxthreads/sysdeps/pthread/pthread.h ${INSTALL_PREFIX}/include/
   cp linuxthreads/sysdeps/pthread/bits/pthreadtypes.h \
      ${INSTALL_PREFIX}/include/bits/

   # TODO: on hppa we'd probably want 
   #       sysdeps/unix/sysv/linux/hppa/bits/initspin.h
   #       instead
   cp linuxthreads/sysdeps/pthread/bits/initspin.h \
      ${INSTALL_PREFIX}/include/bits/
fi
