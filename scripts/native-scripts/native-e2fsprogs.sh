#!/bin/bash

# cross-lfs native e2fsprogs build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=e2fsprogs-native.log

set_libdirname
setup_multiarch

unpack_tarball e2fsprogs-${E2FSPROGS_VER}

# Apply patch for HTREE problem posted by GS 3/19/2003
cd ${PKGDIR}
#apply_patch e2fsprogs-${E2FSPROGS_VER}

case ${KERNEL_VER} in
   2.6* )
   # patch util.c to remove SCSI_BLOCK_MAJOR references
   # SCSI_DISK_MAJOR is no longer defined in linux/major.h for 2.6 kernel 
   # TODO: check future e2fsprogs versions to see if this is fixed
   case ${E2FSPROGS_VER} in
      1.34* )
         # check if SCSI_DISK_MAJOR defined in linux/major.h
         grep SCSI_DISK_MAJOR /usr/include/linux/major.h > /dev/null 2>&1 ||
            apply_patch e2fsprogs-${E2FSPROGS_VER}-2.6.0hdr-fix
      ;;
   esac
   ;;
esac

# Fix some permissions issues when building the e2fsprogs 1.35 tarball
# as a normal user. Need to check if previous versions are affected
case ${E2FSPROGS_VER} in
   1.35 )
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
# Also handles additional_libdir (used if --with-libiconv-prefix is set,
# if we did set it (which we dont) we'd want the 64bit one anyway) ...
test -f configure-ORIG ||
   cp -p configure configure-ORIG

sed "/libdir=.*\/lib/s@/lib@/${libdirname}@g" \
   configure-ORIG > configure

cd ${SRC}

test -d ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build &&
    rm -rf ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build

mkdir ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build &&
cd ${SRC}/e2fsprogs-${E2FSPROGS_VER}-build

max_log_init E2fsprogs ${E2FSPROGS_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe" \
../${PKGDIR}/configure \
   --prefix=/usr \
   --with-root-prefix="" \
   --enable-elf-shlibs \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
make install-libs \
   >> ${LOGFILE} 2>&1 &&
install-info /usr/share/info/libext2fs.info /usr/share/info/dir &&
echo " o ALL OK" || barf

/sbin/ldconfig

