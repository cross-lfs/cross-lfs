#!/bin/bash

# cross-lfs native bzip2 build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="bzip2-native.log"

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball bzip2-${BZIP2_VER} &&
cd ${PKGDIR}

# Edit Makefiles
for file in Makefile-libbz2_so Makefile ; do
   test -f ${file}-ORIG ||
      mv ${file} ${file}-ORIG

   sed -e "s@/lib\(/\| \|$\)@/${libdirname}\1@g" \
       ${file}-ORIG > ${file}
done

max_log_init Bzip2 ${BZIP2_VER} "target (shared)" ${BUILDLOGS} ${LOG}
make \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CXX="${CXX-g++} ${ARCH_CFLAGS}" \
   LDFLAGS="-s" -f Makefile-libbz2_so \
   >> ${LOGFILE} 2>&1 &&
echo -e "\n${BRKLN}" >> ${LOGFILE} &&
make ${PMFLAGS} \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CXX="${CXX-g++} ${ARCH_CFLAGS}" \
   LDFLAGS="-s" \
   -f Makefile-libbz2_so \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Remove existing symlinks/files
rm -f /usr/bin/bz* /bin/bz* &&

min_log_init ${INSTLOGS} &&
make \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CXX="${CXX-g++} ${ARCH_CFLAGS}" \
   PREFIX=/usr install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

cp -f bzip2-shared /bin/bzip2
cp -af libbz2.so* /${libdirname} &&
ln -sf ../../${libdirname}/libbz2.so.1.0 /usr/${libdirname}/libbz2.so &&
rm -f /usr/bin/{bunzip2,bzcat,bzip2} &&
mv -f /usr/bin/{bzip2recover,bzless,bzmore} /bin &&
ln -sf bzip2 /bin/bunzip2 &&
ln -sf bzip2 /bin/bzcat &&

/sbin/ldconfig

