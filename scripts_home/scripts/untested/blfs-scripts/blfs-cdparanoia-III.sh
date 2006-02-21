#!/bin/bash
#
# cdparanoia-III
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-cdparanoia-III.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball cdparanoia-III-${CDPARANOIA_VER}.src &&
cd ${PKGDIR}

# Patching

# Retrieve target_gcc_ver from gcc -v output
target_gcc_ver=`${CC-gcc} -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

case ${CDPARANOIA_VER} in
   alpha9.8 )
      apply_patch cdparanoia-III-alpha9.8-includes-1
      case ${target_gcc_ver} in
         3.4* ) apply_patch cdparanoia-III-alpha9.8-gcc34-1 ;;
      esac
   ;;
   * )
      echo "*** Please check if cdparanoia ${CDPARANOIA_VER} requires patching ***"
      echo "*** then please update this script (and send patch) ***"
      exit 1
   ;;
esac

max_log_init cdparanoia ${CDPARANOIA_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
 ./configure --prefix=/usr --host="${TARGET}" ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} FLAGS="${TGT_CFLAGS} -fPIC" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

