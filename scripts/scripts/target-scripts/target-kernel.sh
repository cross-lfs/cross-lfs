#!/bin/bash

# cross-lfs target linux kernel build
# -----------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${HST_TOOLS}/bin &&
gzip -dc ${TARBALLS}/depmod.pl.gz > depmod.pl &&
patch < ${PATCHES}/depmod-pl-lfh-cross-compile.patch &&
chmod 755 depmod.pl || barf

### KERNEL ###
set -x

cd ${SRC}
LOG=kernel.log
unpack_tarball linux-${KERNEL_VER} &&

cd ${SRC}/${PKGDIR}

case ${TGT_ARCH} in
   i?86 )			ARCH=i386 ;;
   sparc64* | ultrasparc* )	ARCH=sparc64 ;;
   sparc* )			ARCH=sparc ;;
   powerpc64 | ppc64 )		ARCH=ppc64 ;;
   powerpc | ppc )		ARCH=ppc ;;
   s390* )			ARCH=s390 ;;
   mips* )			ARCH=mips ;;
   * )				ARCH=${TGT_ARCH} ;;
esac
echo $PATH

# get gas version
target_gas_ver=`${TARGET}-as --version | head -n 1 | \
   sed 's@.* \([0-9.]*\) .*@\1@g'`

# get gcc version
target_gcc_ver=`${TARGET}-gcc -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

case ${KERNEL_VER} in
   2.4.* )
      apply_patch linux-2.4-lfh-Makefile &&
      if [ "${ARCH}" =  "m68k" ] ; then
         test -f ${PATCHES}/linux-${KERNEL_VER}-m68k-lfh.patch && \
            apply_patch linux-${KERNEL_VER}-m68k-lfh
      fi
   ;;
   2.6.* )
      # TODO: need to handle kernel patching a whole lot better
      #       than this...
      # What might be better is to have a separate dir for kernel patches
      # and apply conditionally all patches in said directory.
      # Maybe something like
      # patches/kernel/2.6
      #                   /2.6.x <- version specific
      #                         /binutils-2.16 <- binutils ver specific for kern
      #                         /gcc-4 <- gcc ver specific

      # fix issues with kernel concerning 2.16 binutils
      # checked against 2.6.11, need to check against 2.6.12
      case ${target_gas_ver} in
         2.16* ) apply_patch linux-2.6-seg-5 ;;
      esac

      # fix gcc4 compilation issues
      # Note: you cannot compile kernel < 2.6.9 with gcc4
      case ${target_gcc_ver} in
         4.* ) 
            case ${KERNEL_VER} in
               2.6.9* | 2.6.1[01]* ) apply_patch linux-2.6.11-gcc4_fixes -Np0 ;;
            esac
         ;;
      esac

      # update cx88 driver (applies 2.6.10 + 2.6.11, need to check 2.6.12+ )
      case ${KERNEL_VER} in
         2.6.10* ) apply_patch linux-2.6.10-cx88-update ;;
         2.6.11* ) apply_patch linux-2.6.11-rc4-enable_dvico_dvb ;;
      esac

      # This is to remove some gnu-specific expr syntax and invoke depmod.pl
      # instead of depmod since we need a depmod that is not a target-native
      # binary.
      case ${KERNEL_VER} in
         2.6.[4-9]* | 2.6.1[01]* ) apply_patch linux-2.6-lfh-Makefile ;;
         2.6.14* )
            apply_patch linux-2.6-lfh-Makefile-2 
            # TODO: interim fix only - see http://lkml.org/lkml/2005/11/10/146
            apply_patch linux-2.6.14-fix_generic_get_unaligned
         ;;
         2.6.1[2-9]* ) apply_patch linux-2.6-lfh-Makefile-2 ;;
      esac
   ;;
esac

max_log_init kernel ${KERNEL_VER} '' ${CONFLOGS} ${LOG}

# TODO: Fix this up again... won't stop on error now...
#-----------------------------------------------------------
make mrproper >> ${LOGFILE} 2>&1 

test -f ${CONFIGS}/kernel/linux-${KERNEL_VER}-${TGT_ARCH}.config &&
{
   cp ${CONFIGS}/kernel/linux-${KERNEL_VER}-${TGT_ARCH}.config .config || barf
   echo "got kernel config"
   yes "" | make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- oldconfig
} || {
   echo "generating kernel config"
   case ${KERNEL_VER} in
      2.4.* )
         yes "" | env -i PATH=${PATH} make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- config ;;
      2.6.* )
         yes "" | env -i PATH=${PATH} make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- defconfig ;;
   esac 
}
echo " o Configure OK" &&
#-----------------------------------------------------------

min_log_init ${BUILDLOGS}

case ${KERNEL_VER} in
   2.4.* )
      env -i PATH=${PATH} make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- dep &&
      env -i PATH=${PATH} make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- vmlinux &&
      env -i PATH=${PATH} make ARCH=${ARCH} CROSS_COMPILE=${TARGET}- modules
   ;;
   2.6.* )
      env -i PATH=${PATH} make V=1 ARCH=${ARCH} CROSS_COMPILE=${TARGET}-
   ;;
esac >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}

if grep -q ^CONFIG_MODULES .config ; then
   mkdir -p ${LFS}/lib/modules &&
   env -i PATH=${PATH} make INSTALL_MOD_PATH=${LFS} ARCH=${ARCH} CROSS_COMPILE=${TARGET}- modules_install \
      >> ${LOGFILE} 2>&1 || barf
fi

mkdir -p ${LFS}/boot

case ${ARCH} in
   alpha )
      if [ -e arch/${ARCH}/boot/vmlinux.gz ]; then
         cp arch/${ARCH}/boot/vmlinux.gz ${LFS}/boot/vmlinux-${KERNEL_VER}.gz
      else
         gzip -c vmlinux > ${LFS}/boot/vmlinux-${KERNEL_VER}.gz
      fi
   ;;
   ppc* )
      cp vmlinux ${LFS}/boot/vmlinux-${KERNEL_VER} 
   ;;
   * )
      if [ -e arch/${ARCH}/boot/bzImage ]; then
         cp arch/${ARCH}/boot/bzImage ${LFS}/boot/bzImage-${KERNEL_VER}
      else
         cp vmlinux ${LFS}/boot/vmlinux-${KERNEL_VER}
      fi
   ;;
esac &&

cp System.map ${LFS}/boot/System.map-${KERNEL_VER} &&
cp .config ${LFS}/boot/config-${KERNEL_VER} &&

# Create /usr/share/hwdata dir and populate with pci.ids (for hald)
mkdir -p ${LFS}/usr/share/hwdata &
cp -p drivers/pci/pci.ids ${LFS}/usr/share/hwdata &

cd ${LFS}/boot &&
ln -s System.map-${KERNEL_VER} System.map &&
cd ${LFS} &&
rm -f lib/modules/${KERNEL_VER}/build && # delete this link as it points to the build host filesystem
chmod -R g-w,o-w boot lib/modules &&
echo " o All OK" || barf
