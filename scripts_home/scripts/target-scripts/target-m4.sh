#!/bin/bash

# cross-lfs target m4 build
# -------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=m4-target.log

unpack_tarball m4-${M4_VER} &&
cd ${PKGDIR} 

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="prefix=${INSTALL_PREFIX}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

# NOTE: with gcc-3.4.0, linux-libc-headers-2.6.5.1 on 
#       biarch x86_64-pc-linux-gnu the build barfed out with
#       errors in lib/regex.c due to conflicting types for
#       malloc. removed definitions of malloc/realloc and
#       made it so stlib.h always gets read.
#
#     : same results with linux-libc-headers-2.6.6.0 with
#       gcc-3.4.1-20040620 on x86_64-pc-linux-gnu
#
# TODO: check if other architecturess are affected, and for what
#       glibc/gcc/m4 versions.
#
#     : same issue w powerpc...
#
#       Get a better fix for this....
case ${TGT_ARCH} in
   x86_64 | ppc | powerpc | powerpc64 )
      apply_patch m4-1.4-regex_c-hack
   ;;
esac

max_log_init M4 ${M4_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" ./configure --prefix=${BUILD_PREFIX} \
  --host=${TARGET} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

