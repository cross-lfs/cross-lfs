#!/bin/sh

### libpng ###

cd ${SRC}
LOG=libpng-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball libpng-${LIBPNG_VER}
cd ${PKGDIR}

case ${LIBPNG_VER} in
   1.2.7 )
      apply_patch libpng-1.2.7-link_to_proper_libs-1
   ;;
   1.2.8 )
      apply_patch libpng-1.2.8-link_to_proper_libs-1
   ;;
esac
apply_patch libpng-1.2.7-fix_pc_for_biarch

max_log_init libpng ${LIBPNG_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
   prefix=/usr LIBPATH=/usr/${libdirname} \
   ZLIBINC=/usr/include ZLIBLIB=/usr/${libdirname} \
   -f scripts/makefile.linux \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
   prefix=/usr LIBPATH=/usr/${libdirname} install \
   -f scripts/makefile.linux \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/libpng12-config
   # Added as libpng-config is a symlink to libpng12-config (which uses the wrapper)
   # so that the wrapper will find libpng-config-${BUILDENV}
   ln -sf libpng12-config-${BUILDENV} /usr/bin/libpng-config-${BUILDENV}
fi
