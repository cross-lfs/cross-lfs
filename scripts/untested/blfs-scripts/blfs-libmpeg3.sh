#!/bin/bash

### libmpeg3 ###

cd ${SRC}
LOG=libmpeg3-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball libmpeg3-${LIBMPEG3_VER}
cd ${PKGDIR}

# Eeeek this is a mess...
# Firstly, fix for gcc-3.4
apply_patch libmpeg3-1.5.4-gcc34-1

# Secondly, we are going to use the system a52dec, so blow that
# directory away...
rm -rf a52dec-0.7.3

# We will also modify the Makefile to adjusting the A52 include search path
# enabling shared libmpeg, and also enabling mpeg3split
# (parts stolen from gentoo)
apply_patch libmpeg3-1.5.4-shared_libmpeg3-1

# override OBJDIR
# use uname --machine except where it equals x86_64 and BUILDENV=32
MACHINE=`uname --machine`
if [ "${MACHINE}" = "x86_64" -a "${BUILDENV}" = "32" ]; then
   MACHINE=i686
fi

max_log_init libmpeg3 ${LIBMPEG3_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
make \
CC="${CC-gcc} ${ARCH_CFLAGS}" \
OBJDIR=${MACHINE} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${INSTLOGS} &&
make OBJDIR=${MACHINE} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Fix the produced headers
PREFIX=/usr
for file in `find ${PREFIX}/include/libmpeg3 -type f` ; do
   sed -i 's@\(#include\s\)\"\([-+_a-zA-Z0-9/.]*\)\"@\1<libmpeg3/\2>@' \
      ${file}
done
