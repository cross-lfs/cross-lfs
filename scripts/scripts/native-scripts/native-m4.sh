#!/bin/bash

# cross-lfs native m4 build
# -------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=m4-native.log

set_libdirname
setup_multiarch

unpack_tarball m4-${M4_VER} &&
cd ${PKGDIR} 

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

max_log_init M4 ${M4_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

