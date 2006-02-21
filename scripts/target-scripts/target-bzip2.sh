#!/bin/bash

# cross-lfs target bzip2 build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

LOG="bzip2-target.log"
libdirname="lib"

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
fi

export CC="${TARGET}-gcc ${ARCH_CFLAGS}"
export CXX="${TARGET}-g++ ${ARCH_CFLAGS}"

unpack_tarball bzip2-${BZIP2_VER} &&
cd ${PKGDIR}

# Edit Makefiles
for file in Makefile-libbz2_so Makefile ; do
   test -f ${file}-ORIG ||
      mv ${file} ${file}-ORIG

   sed -e "s@^\(CC=\).*@\1${CC}@g" \
       -e "s@^\(AR=\).*@\1${TARGET}-ar@g" \
       -e "s@^\(RANLIB=\).*@\1${TARGET}-ranlib@g" \
       -e 's@^\(all:.*\) test@\1@g' \
       -e "s@/lib\(/\| \|$\)@/${libdirname}\1@g" \
       ${file}-ORIG > ${file}
done

max_log_init Bzip2 ${BZIP2_VER} "target (shared)" ${BUILDLOGS} ${LOG}
make -f Makefile-libbz2_so \
   >> ${LOGFILE} 2>&1 &&
echo -e "\n${BRKLN}" >> ${LOGFILE} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Remove existing bz* files in ${TGT_TOOLS}/bin
rm -f ${INSTALL_PREFIX}/bin/bz*

min_log_init ${INSTLOGS} &&
CC="${CC}" CXX="${CXX}" make PREFIX=${INSTALL_PREFIX} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

yes | cp bzip2-shared ${INSTALL_PREFIX}/bin/bzip2
ln -s libbz2.so.1.0 libbz2.so

# There is no cp -a under solaris... thats why we build coreutlis cp
cp -a libbz2.so* ${INSTALL_PREFIX}/${libdirname}

rm -f ${INSTALL_PREFIX}/bin/{bunzip2,bzcat}
ln -s bzip2 ${INSTALL_PREFIX}/bin/bunzip2
ln -s bzip2 ${INSTALL_PREFIX}/bin/bzcat
#ldconfig
