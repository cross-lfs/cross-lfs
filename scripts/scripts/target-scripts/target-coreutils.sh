#!/bin/bash

# cross-lfs target coreutils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=coreutils-target.log

unpack_tarball coreutils-${COREUTILS_VER}
cd ${PKGDIR}

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

# If we don't want to conform to POSIX 200212L, override
# NOTE: This is coreutils 5.0 specific, later versions will have
#       a configure/compile time option
case ${COREUTILS_VER} in
   5.1.7 | 5.[2-9]* ) ;;
   * )   mv lib/posixver.c lib/posixver.c-ORIG
         sed '/\/\* The POSIX version that utilities should conform to/i\
#undef _POSIX2_VERSION\
#define _POSIX2_VERSION 199209L\
   ' lib/posixver.c-ORIG > lib/posixver.c
   ;;
esac

# Cannot check whether we have a working getline in glibc when
# cross compiling. Say yes here as we will get failure on x86_64
# where getline is type _IO_ssize_t in stdio.h (long with x86_64)
# and the provided getline in coreutils (well gnulib) is type int.
echo "am_cv_func_working_getline=yes" >> config.cache

# UTILS_OPEN_MAX does not get defined when cross-compiling as
# it is an AC_RUN test used to determine roughly how many open
# FD's a process can have.
# We will set it to 1024 (NR_OPEN in /usr/include/linux/limits.h )
echo "utils_cv_sys_open_max=1024" >> config.cache

# if target is same as build host, adjust build slightly to avoid running
# configure checks which we cannot run
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

max_log_init Coreutils ${COREUTILS_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" DEFAULT_POSIX2_VERSION=199209 \
./configure --prefix=${BUILD_PREFIX}  \
   --build=${BUILD} --host=${TARGET} --cache-file=config.cache \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
echo Password: &&
su -c "make ${INSTALL_OPTIONS} install" \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

