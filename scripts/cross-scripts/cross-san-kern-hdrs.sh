#!/bin/bash

# cross-lfs sanitized kernel header installation
# ----------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# install kernel headers 

cd ${SRC}
LOG=sanitised-kernel-headers.log
unpack_tarball linux-libc-headers-${LINUX_LIBC_HDRS_VER} &&
cd ${PKGDIR}

# Setup ownership and permissions properly
# TODO: This assumes you are root...
#chown -R 0 *
#chgrp -R 0 *

# Setup permissions
find . -type d | xargs chmod 755
find . -type f | xargs chmod 644

max_log_init sanitised-kernel-headers ${LINUX_LIBC_HDRS_VER} '' ${INSTLOGS} ${LOG}

# Install the headers.

# If we are using sanitised headers,
# install the sanitised ones into
# ${TGT_TOOLS}/include
if [ "${USE_SYSROOT}" = "Y" ]; then
   INSTALL_PREFIX="${LFS}/usr"
else
   INSTALL_PREFIX="${TGT_TOOLS}"
fi
KERN_HDR_DIR=${INSTALL_PREFIX}/include

# If we are doing a biarch build we will need the kernel headers for
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
      mips* )
         ARCH1=mips
      ;;
   esac

   # TODO: This needs to be done better
   #       Here we are handling the case of mips, where only the one set of
   #       asm headers are provided (and needed) for multi-arch.
   if [ -z "${ARCH1_SWITCH}" ]; then
      mkdir -p ${KERN_HDR_DIR}/asm
      yes | cp -Rp include/asm-${ARCH1}/* ${KERN_HDR_DIR}/asm
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
   # TODO: this needs to be done better...
   case ${TGT_ARCH} in
      i?86 )                   ARCH=i386    ;;
      x86_64 | x86-64 )        ARCH=x86_64  ;;
      powerpc | ppc )          ARCH=ppc     ;;
      powerpc64 | ppc64 )      ARCH=ppc64   ;;
      sparc64* | ultrasparc* ) ARCH=sparc64 ;;
      sparc* )                 ARCH=sparc   ;;
      s390 )                   ARCH=s390    ;;
      s390x )                  ARCH=s390x   ;;
      mips* )                  ARCH=mips    ;;
      arm* )                   ARCH=arm     ;;
      * )                      ARCH=${TGT_ARCH} ;;
   esac

   mkdir -p ${KERN_HDR_DIR}/asm
   yes | cp -Rp include/asm-${ARCH}/* ${KERN_HDR_DIR}/asm
   # TODO: probably more here to do for arm...

   # This should be replaced by a var, for the moment defaulting to
   # ebsa285
   case ${TGT_ARCH} in
      arm* )  ln -sf arch-ebsa285 ${KERN_HDR_DIR}/asm/arch ;;
   esac

}

yes | cp -Rp include/linux ${KERN_HDR_DIR}

