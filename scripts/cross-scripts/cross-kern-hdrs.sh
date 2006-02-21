#!/bin/bash

# cross-lfs kernel header creation
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# install kernel headers 

cd ${SRC}
LOG=kernel-headers.log
unpack_tarball linux-${KERNEL_VER} &&
cd ${PKGDIR}

# 20030510
# If we are building for x86_64, and the kernel is greater than 2.6.4,
# we need to fix unistd.h so glibc doesn't barf during assembly.
# TODO: track this issue, still exists as of 2.6.6 ...
case ${KERNEL_VER} in
   2.6.[4-6] )
      apply_patch linux-2.6.6-x86_64-unistd_h-fix
   ;;
esac
                                                                                
max_log_init kernel-headers ${KERNEL_VER} '' ${INSTLOGS} ${LOG}

#
case ${TGT_ARCH} in
   i?86 )                   ARCH=i386    ;;
   x86_64 | x86-64 )        ARCH=i386    ;;
   sparc64* | ultrasparc* ) ARCH=sparc64 ;;
   sparc* )                 ARCH=sparc   ;;
   powerpc64 | ppc64 )      ARCH=ppc64   ;;
   powerpc | ppc )          ARCH=ppc     ;;
   s390* )                  ARCH=s390    ;;
   mips* )                  ARCH=mips    ;;
   arm* )                   ARCH=arm     ;;
   * )                      ARCH=${TGT_ARCH} ;;
esac

set -x
ARCH=${ARCH} CROSS_COMPILE=${TARGET}- make mrproper \
   >> ${LOGFILE} 2>&1 &&
set +x                                                                                
# Pre-configure kernel
# TODO: for want of somewhere better, put kernel .config files
#       in ${SCRIPTS}. Should really let user supply filename
#       via plfs-config
# Kernel .config files should reside under ${CONFIGS}/kernel
test -f ${CONFIGS}/kernel/linux-${KERNEL_VER}-${TGT_ARCH}.config &&
{
   echo "got kernel config"
   cp ${CONFIGS}/kernel/linux-${KERNEL_VER}-${TGT_ARCH}.config .config
   yes "" | make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- oldconfig 
} >> ${LOGFILE} 2>&1
                                                                                
# 2.5/2.6 series kernels dont have "make symlinks" target but use
# "make include/asm"
# Check for the include/asm target and use it if its available
make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- include/linux/version.h &&
grep "^include/asm:" Makefile > /dev/null 2>&1 &&
{
   case ${ARCH} in
      arm | cris ) make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- \
                        include/asm include/asm-${ARCH}/.arch ;;
      * )          make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- include/asm ;;
   esac
} || {
   make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- symlinks
} >> ${LOGFILE} 2>&1 &&

# Install the headers.

# If we are using sanitised headers, and we are installing the
# raw kernel headers, install raw headers into
# ${TGT_TOOLS}/kernel-hdrs and the sanitised ones into
# ${TGT_TOOLS}/include

if [ "${USE_SYSROOT}" = "Y" ]; then
   INSTALL_PREFIX="${LFS}/usr"
else
   INSTALL_PREFIX="${TGT_TOOLS}"
fi

if [ "${USE_SANITISED_HEADERS}" = "Y" ]; then
   KERN_HDR_DIR="${INSTALL_PREFIX}/kernel-hdrs"
else
   KERN_HDR_DIR="${INSTALL_PREFIX}/include"
fi

# If we are doing a multiarch build we will need the kernel headers for
# both architectures and will have to create stub headers in include/asm

test "Y" = "${MULTIARCH}" &&
{
   case ${TGT_ARCH} in
   x86_64 | x86-64 )
      ARCH1_SWITCH=__x86_64__
      ARCH1=x86_64
      ARCH2=i386
   ;;
   sparc* | ultrasparc* )
      ARCH1_SWITCH=__arch64__
      ARCH1=sparc64
      ARCH2=sparc
   ;;
   ppc* | powerpc* )
      ARCH1_SWITCH=__powerpc64__
      ARCH1=ppc64
      ARCH2=ppc
   ;;
   s390* )
      ARCH1_SWITCH=__s390x__
      ARCH1=s390x
      ARCH2=s390
   ;;
   esac

   # TODO: This needs to be done better
   #       Here we are handling the case of mips, where only the one set of
   #       asm headers are provided (and needed) for multi-arch.
   if [ -z "${ARCH1_SWITCH}" ]; then
      mkdir -p ${KERN_HDR_DIR}/asm
      yes | cp -Rp include/asm/* ${KERN_HDR_DIR}/asm
   else
      mkdir -p ${KERN_HDR_DIR}/asm
      yes | cp -Rp include/asm-${ARCH1} ${KERN_HDR_DIR}
      yes | cp -Rp include/asm-${ARCH2} ${KERN_HDR_DIR}

      # Create stubs ( see build-init.x.x.x.sh )
      create_kernel_stubs ${ARCH1} ${ARCH1_SWITCH} ${ARCH2} ${KERN_HDR_DIR}
   fi
   
} || {
   # Install kernel headers in
   #  ${TGT_TOOLS}/include 
   mkdir -p ${KERN_HDR_DIR}/asm
   yes | cp -Rp include/asm/* ${KERN_HDR_DIR}/asm
}

yes | cp -Rp include/asm-generic ${KERN_HDR_DIR}
yes | cp -Rp include/linux ${KERN_HDR_DIR}

# Don't need this if we pre-configured the kernel
touch ${KERN_HDR_DIR}/linux/autoconf.h

