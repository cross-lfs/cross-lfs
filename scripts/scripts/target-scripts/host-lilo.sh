#!/bin/bash

# cross-lfs build-host lilo build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="lilo-host.log"
unpack_tarball lilo-${LILO_VER} &&
cd ${SRC}/${PKGDIR}

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

# TODO: THIS IS WRONG.
case ${TGT_ARCH} in
   x86_64 ) ARCH_CFLAGS="-m32" ;;
esac

max_log_init Lilo ${LILO_VER} host ${BUILDLOGS} ${LOG}
make CC="gcc ${ARCH_CFLAGS}" \
   SBIN_DIR=${HST_TOOLS}/sbin \
   USRSBIN_DIR=${HST_TOOLS}/sbin \
   MAN_DIR=${HST_TOOLS}/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   SBIN_DIR=${HST_TOOLS}/sbin \
   USRSBIN_DIR=${HST_TOOLS}/sbin \
   MAN_DIR=${HST_TOOLS}/share/man \
   >> ${LOGFILE} &&
echo " o ALL OK" || barf

