#!/bin/bash
#
# unzip
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-unzip.log

set_libdirname
setup_multiarch

unpack_tarball unzip${UNZIP_VER} &&
cd ${PKGDIR}

case ${UNZIP_VER} in
   551 | 552 )
      apply_patch unzip-5.51-fix_Makefile-1
      apply_patch unzip-5.51-fix_libz-1
      apply_patch unzip-5.51-dont_make_noise-1
   ;;
   * )
      echo "*** Please check if unzip ${UNZIP_VER} requires patching ***"
      echo "*** then please update this script (and send patch)      ***"
      exit 1
   ;;
esac

cp unix/Makefile .

max_log_init unzip ${UNZIP_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}

case ${TARGET} in
   i?86* )
      make ${PMFLAGS} CC="${CC-gcc} ${ARCH_CFLAGS}" \
           prefix=/usr LOCAL_UNZIP="-DUSE_UNSHRINK" linux \
         >> ${LOGFILE} 2>&1 &&
      make ${PMFLAGS} CC="${CC-gcc} ${ARCH_CFLAGS}" \
           prefix=/usr LOCAL_UNZIP="-DUSE_UNSHRINK" linux_shlibz \
         >> ${LOGFILE} 2>&1 &&
      echo " o Build OK" || barf
   ;;
   * )
      make ${PMFLAGS} CC="${CC-gcc} ${ARCH_CFLAGS}" \
           prefix=/usr LOCAL_UNZIP="-DUSE_UNSHRINK" linux_noasm \
         >> ${LOGFILE} 2>&1 &&
      echo " o Build OK" || barf
   ;;
esac

min_log_init ${INSTLOGS} &&
make prefix=/usr LOCAL_UNZIP="-DUSE_UNSHRINK" install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

