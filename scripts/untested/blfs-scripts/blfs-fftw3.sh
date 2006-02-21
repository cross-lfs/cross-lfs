#!/bin/bash

### fftw3 ###

cd ${SRC}

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball fftw-${FFTW3_VER}
if [ -d ${PKGDIR}-single ]; then rm -rf ${PKGDIR}-single ; fi
mv ${PKGDIR} ${PKGDIR}-single
unpack_tarball fftw-${FFTW3_VER}
if [ -d ${PKGDIR}-double ]; then rm -rf ${PKGDIR}-double ; fi
mv ${PKGDIR} ${PKGDIR}-double
unpack_tarball fftw-${FFTW3_VER}
if [ -d ${PKGDIR}-long-double ]; then rm -rf ${PKGDIR}-long-double ; fi
mv ${PKGDIR} ${PKGDIR}-long-double


### SINGLE ###
cd ${SRC}/${PKGDIR}-single

LOG=fftw3-single-blfs.log

# TODO: gonna need to set extra_conf for each arch methinks...
#       currently only handling amd64/i686

MACHINE=`uname --machine`
if [ "${MACHINE}" = "x86_64" ]; then
   case ${BUILDENV} in
      32 )
         extra_conf="${extra_conf} --enable-sse"
      ;;
   esac
fi

max_log_init fftw3-single ${FFTW3_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   --enable-shared --enable-threads --enable-float \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

#### DOUBLE ###
cd ${SRC}/${PKGDIR}-double

LOG=fftw3-double-blfs.log

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# OK, for 32bit on amd64, we can use -sse2 extensions, but it barfs on
# 64bit... 
#
# TODO: gonna need to set extra_conf for each arch methinks...
#       currently only handling amd64/i686

MACHINE=`uname --machine`
if [ "${MACHINE}" = "x86_64" ]; then
   case ${BUILDENV} in
      32 )
         extra_conf="${extra_conf} --enable-sse2"
      ;;
   esac
fi

max_log_init fftw3-double ${FFTW3_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   --enable-shared --enable-threads \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf


#### LONG DOUBLE ###
cd ${SRC}/${PKGDIR}-double

LOG=fftw3-long-double-blfs.log

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# OK, for 32bit on amd64, we can use -sse extensions, but it barfs on
# 64bit... k7 extensions work for 64bit though...
#
# TODO: gonna need to set extra_conf for each arch methinks...
#       currently only handling amd64/i686

max_log_init fftw3-double ${FFTW3_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   --enable-shared --enable-threads --enable-long-double \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

