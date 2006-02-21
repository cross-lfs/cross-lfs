#!/bin/bash

# cross-lfs native glibc build
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="glibc-native.log"

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

# Only add --build=foo ( and probably should set --host=foo )
# if we are doing a multi-arch build.
# By rights --host should be inferred from --build, and CC will
# be set for the correct emulation ( via -m32/-m64 etc ) anyway
if [ "Y" = "${MULTIARCH}" ]; then
   if [ -z "${ALT_TGT}" ]; then ALT_TGT="${TARGET}" ; fi
   extra_conf="--build=${ALT_TGT}"
fi

if [ "${USE_SYSROOT}" = "Y" ]; then
   KERN_HDR_PREFIX=/usr
else
   KERN_HDR_PREFIX="${TGT_TOOLS}"
fi

# point at the correct kernel headers
#------------------------------------
if [ "Y" = "${USE_SANITISED_HEADERS}" ]; then
   KERN_HDR_DIR="${KERN_HDR_PREFIX}/kernel-hdrs"
else
   KERN_HDR_DIR="${KERN_HDR_PREFIX}/include"
fi

unpack_tarball glibc-${GLIBC_VER} &&
cd ${PKGDIR}

# Gather package version information
#-----------------------------------
target_glibc_ver=`grep VERSION version.h | \
   sed 's@.*\"\([0-9.]*\)\"@\1@'`
export target_glibc_ver

# Retrieve target_gcc_ver from gcc -v output
target_gcc_ver=`${CC-gcc} -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

# get kernel version from kernel headers
kernver=`grep UTS_RELEASE ${KERN_HDR_DIR}/linux/version.h | \
         sed 's@.*\"\([0-9.]*\).*\"@\1@g' `

# if we don't have linuxthreads dirs (ie: a glibc release), then
# unpack the linuxthreads tarball
if [ ! -d linuxthreads -o ! -d linuxthreads_db ]; then
   OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-linuxthreads-${GLIBC_VER}
   PKGDIR=${OLDPKGDIR}
fi

# unpack libidn add-on if required (should be supplied with cvs versions)
case ${target_glibc_ver} in
   2.3.[4-9]* | 2.4* )
      cd ${SRC}/${PKGDIR}
      if [ ! -d libidn ]; then
         OLDPKGDIR=${PKGDIR} ; unpack_tarball glibc-libidn-${GLIBC_VER}
         PKGDIR=${OLDPKGDIR}
      fi
   ;;
esac

# apply glibc patches as required depending on the above gcc/kernel versions
# see funcs/glibc_funcs.sh
apply_glibc_patches

# configuration for pthread type
#-------------------------------
# HACK: nptl for sparc64 wont build
case ${TGT_ARCH} in
   sparc64 )
      USE_NPTL=N
   ;;
esac

if [ "Y" = "${USE_NPTL}" ]; then
   # remove linuxthreads dirs if they exist
   # (CVS source contains linuxthreads)
   test -d linuxthreads && 
      rm -rf linuxthreads*

   # As of ~2003-10-06 nptl is included in glibc cvs
   #test -d ./nptl &&
   #test -d ./nptl_db ||
   #unpack_tarball nptl-${NPTL_VER}

   # fix tst-cancelx7 test (if needed)
   fname="${SRC}/${PKGDIR}/nptl/Makefile"
   grep tst-cancelx7-ARGS ${fname} > /dev/null 2>&1 || {
      echo " - patching ${fname}"
      mv ${fname} ${fname}-ORIG
      sed -e '/tst-cancel7-ARGS = --command "$(built-program-cmd)"/a\
tst-cancelx7-ARGS = --command "$(built-program-cmd)"' \
         ${fname}-ORIG > ${fname}
   }

   extra_conf="${extra_conf} --with-tls --with-__thread"
else
   if [ -d ./nptl ]; then rm -rf nptl* ; fi
fi

# set without-fp if target has no floating point unit
if [ "${WITHOUT_FPU}" = "Y" ]; then
   extra_conf="${extra_conf} --without-fp"
fi

# set --enable-kernel to match the kernel version 
# of the kernel headers glibc is to be built against
#-------------------------------------------------
# HACK: hack around 2.6.8.1 release
case ${kernver} in 2.6.8.* ) kernver=2.6.8 ;; esac
extra_conf="${extra_conf} --enable-kernel=${kernver}"

# End prep
#--------------------------------
touch /etc/ld.so.conf

test -d ${SRC}/glibc-${GLIBC_VER}-native${suffix} &&
   rm -rf ${SRC}/glibc-${GLIBC_VER}-native${suffix}

mkdir ${SRC}/glibc-${GLIBC_VER}-native${suffix}
cd ${SRC}/glibc-${GLIBC_VER}-native${suffix}

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="${extra_conf} --libdir=/usr/${libdirname}"
   # Also create a configparms file setting slibdir to */libdirname
   echo "slibdir=/${libdirname}" >> configparms
fi

max_log_init Glibc ${GLIBC_VER} native ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe" PARALLELMFLAGS="${PMFLAGS}" \
CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
../${PKGDIR}/configure --prefix=/usr \
   --without-cvs --disable-profile --enable-add-ons \
   --with-headers=${KERN_HDR_DIR} ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --libexecdir=/usr/${libdirname}/glibc \
      >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make PARALLELMFLAGS="${PMFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Tests moved after install, during glibc tests
# at times librt will be rebuilt... incorrectly.
# Better to install first and not have to worry
# about anything built correctly being replaced
# by something broken...

echo "-Installing Glibc" &&
min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o install OK" || barf

make localedata/install-locales \
   >>  ${LOGFILE} 2>&1 &&
echo " o install-locales OK" || barf
ln -sf ../usr/share/zoneinfo/${TZ} /etc/localtime &&

# Use make -k check... will have to revisit this
min_log_init ${TESTLOGS} &&
make -k check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

# install sample nscd.conf
if [ ! -f /etc/nscd.conf ]; then
   echo -n " o Creating /etc/nscd.conf - "
   cp ${SRC}/${PKGDIR}/nscd/nscd.conf /etc/nscd.conf &&
   echo "OK" || echo "FAIL"
fi

if [ ! -d /var/run/nscd ]; then
   mkdir -p /var/run/nscd
fi
