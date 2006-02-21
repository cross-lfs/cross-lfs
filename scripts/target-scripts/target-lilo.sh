#!/bin/sh

# cross-lfs target lilo build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="lilo-target.log"
unpack_tarball lilo-${LILO_VER} &&
cd ${SRC}/${PKGDIR}

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_BASEDIR=""
   BUILD_PREFIX="/usr"
else
   BUILD_BASEDIR=${TGT_TOOLS}
   BUILD_PREFIX=${TGT_TOOLS}
fi

case ${KERNEL_VER} in
   2.[56].* )
      case ${LILO_VER} in
         22.5.1 )
            #apply_patch lilo-22.5.1-2.6.0hdr-fix
            #avoid LVM for the moment
            if [ ! -f Makefile-ORIG ]; then cp -p Makefile Makefile-ORIG ; fi
            sed '/^CONFIG=/s@ -DLVM@@g' Makefile-ORIG > Makefile

            # need PAGE_SIZE from <asm/page.h>
            if [ ! -f boot.c-ORIG ]; then cp -p boot.c boot.c-ORIG ; fi
            sed '/^#include <sys\/stat.h>/a \
#include <asm/page.h>' boot.c-ORIG > boot.c

            if [ ! -f partition.c-ORIG ]; then
              cp -p partition.c partition.c-ORIG
            fi
            sed '/^#include <asm\/unistd.h>/a \
#include <asm/page.h>' partition.c-ORIG > partition.c
         ;;
      esac
   ;;
esac

case ${TGT_ARCH} in
   x86_64 ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init Lilo ${LILO_VER} target ${BUILDLOGS} ${LOG}
make CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
   SBIN_DIR=${BUILD_BASEDIR}/sbin \
   USRSBIN_DIR=${BUILD_PREFIX}/sbin \
   ROOT=${LFS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   SBIN_DIR=${BUILD_BASEDIR}/sbin \
   USRSBIN_DIR=${BUILD_PREFIX}/sbin \
   MAN_DIR=${BUILD_PREFIX}/share/man \
   ROOT=${LFS} \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

