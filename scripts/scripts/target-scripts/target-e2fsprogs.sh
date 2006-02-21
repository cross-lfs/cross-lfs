#!/bin/bash

# cross-lfs target e2fsprogs build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# NOTE: This installs to the target root,
#       NOT to ${TGT_TOOLS}
#
# NOTE: also requires gettext built native on the build host


cd ${SRC}
LOG=e2fsprogs-target.log
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
   extra_conf="--with-root-prefix=\"\""
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

unpack_tarball e2fsprogs-${E2FSPROGS_VER}

cd ${PKGDIR}
# Apply patch for HTREE problem posted by GS 3/19/2003
#apply_patch e2fsprogs-${E2FSPROGS_VER}

case ${KERNEL_VER} in
   2.6* )
   # patch util.c to remove SCSI_BLOCK_MAJOR references
   # SCSI_DISK_MAJOR is no longer defined in linux/major.h for 2.6 kernel 
   # TODO: check future e2fsprogs versions to see if this is fixed
   case ${E2FSPROGS_VER} in
      1.34* )
         # check if SCSI_DISK_MAJOR defined in linux/major.h
         grep SCSI_DISK_MAJOR ${INSTALL_PREFIX}/include/linux/major.h > /dev/null 2>&1 ||
            apply_patch e2fsprogs-${E2FSPROGS_VER}-2.6.0hdr-fix
      ;;
   esac
   ;;
esac


case ${E2FSPROGS_VER} in
   1.35 )
      # Fix some permissions issues when building the e2fsprogs 1.35 tarball
      # as a normal user. Need to check if previous versions are affected
      chmod 755 configure
      chmod 644 po/*
   ;;
   1.37 )
      # Fix braindead error in e2p tests where include paths aren't
      # being passed 
      if [ ! -f lib/e2p/Makefile.in-ORIG ]; then
         mv lib/e2p/Makefile.in lib/e2p/Makefile.in-ORIG
      fi

      sed 's@-DTEST_PROGRAM@$(ALL_CFLAGS) &@g' \
         lib/e2p/Makefile.in-ORIG > lib/e2p/Makefile.in 
   ;;
esac

# Edit configure so libdir and root_libdir point at */lib64 .
# Also handles additional_libdir (used if--with-libiconv-prefix is set,
# if we did set it (which we dont) we'd want the 64bit version anyway) ...
chmod 755 configure
test -f configure-ORIG ||
   cp -p configure configure-ORIG

sed "/libdir=.*\/lib/s@/lib@/${libdirname}@g" \
   configure-ORIG > configure

# We need to check if the build OS has a <getopt.h>.
# If it doesn't, and HAVE_GETOPT_H is defined, util/subst.c will barf
# (its compiled with BUILD_CC ie: the hosts cc). This is the case building
# linux from solaris. Hack util/subst.c where necessary

# TODO: actually try to compile something...
if [ ! -f /usr/include/getopt.h ]; then
   test -f util/subst.c-ORIG ||
      mv util/subst.c util/subst.c-ORIG

   # This will avoid the problem.
   # Ideally the build-host would have a separate define than for
   # the target, one day I may even patch it so it does...
   sed 's@HAVE_GETOPT_H@HOST_&@g' \
      util/subst.c-ORIG > util/subst.c
fi

cd ${SRC}
test -d ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build &&
    rm -rf ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build

mkdir ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build &&
cd ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build

# When cross-compiling configure cannot determine sizes and assumes
# short=2, int=4, long=4, long long=8
# This may not be correct for certain architectures, override here
case ${TGT_ARCH} in
   ppc64 | powerpc64 )
      # TODO: what is size of long long on ppc64?
      echo "ac_cv_sizeof_long_long=8" >> config.cache
      echo "ac_cv_sizeof_long=8" >> config.cache
      echo "ac_cv_sizeof_int=4" >> config.cache
      echo "ac_cv_sizeof_short=2" >> config.cache
      extra_conf="${extra_conf} --cache-file=config.cache"
   ;;
esac

max_log_init E2fsprogs ${E2FSPROGS_VER} "Final (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
LD="${TARGET}-ld" STRIP="${TARGET}-strip" \
CFLAGS="-O2 -pipe" ../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} --enable-elf-shlibs ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make CC="${TARGET}-gcc ${ARCH_CFLAGS}" LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
make ${INSTALL_OPTIONS} install-libs \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # if ${LFS}/sbin doesn't exist, create it
   set -x
   if [ ! -d ${LFS}/sbin ]; then
      mkdir -p ${LFS}/sbin
   fi
   
   # Install these for the benefit of init scripts. 
   # Should be overwritten in ch 6.
   cd ${LFS}/sbin
   ln -sf ..${TGT_TOOLS}/sbin/fsck.ext2 .
   ln -sf ..${TGT_TOOLS}/sbin/fsck.ext3 .
   ln -sf ..${TGT_TOOLS}/sbin/e2fsck .
   set +x
fi
