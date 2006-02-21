#!/bin/bash

# cross-lfs target util-linux build
# ---------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# NOTE: this script defaults to installing into the new root ( ${LFS} ).
#       work has to be done on configure to make it install to 
#       ${TGT_TOOLS}

# NOTE: *** For gods sake ryan, fix the setting of CPU and ARCH ***

cd ${SRC}
LOG=util-linux-target.log

set_libdirname
setup_multiarch

unpack_tarball util-linux-${UTILLINUX_VER} &&
cd ${PKGDIR}

case ${UTILLINUX_VER} in
   2.12 | 2.12a )
      case ${KERNEL_VER} in
         2.[56].* )
            # Fixes for utillinux 2.12 + 2.12a for building against 2.6
            # kernel headers
            apply_patch util-linux-2.12a-kernel_headers-1
         ;;
      esac
   ;;
   2.12[k-q] )
      # fix cramfs, this fix will need to be tracked for later versions...
      apply_patch util-linux-2.12q-cramfs-1
      # fix sfdisk for mips n32/64 as n32/64 uses lseek, not llseek
      apply_patch util-linux-2.12q-sfdisk_use_lseek_for_mips64-1
   ;;
esac

case ${UTILLINUX_VER} in
   2.12 | 2.12[a-m] )
      # Patch to fix fdiskbsdlabel.h for m68k, also adds unistd.h to list
      # of includes for swapon.c
      apply_patch util-linux-2.12a-cross-lfs-fixes
   ;;
   2.12* )
      # Patch to fix fdiskbsdlabel.h for m68k
      apply_patch util-linux-2.12n-cross-lfs-fixes
   ;;
esac

# Make FHS compliant
# Get list of files which reference etc/adjtime
filelist=`grep -l -d recurse etc/adjtime *`

# Edit each file in turn
for file in ${filelist} ; do
   test -f ${file}-ORIG ||
      cp ${file} ${file}-ORIG
   # Change instance of etc/adjtime to var/lib/hwclock/adjtime
   sed 's%etc/adjtime%var/lib/hwclock/adjtime%' \
      ${file}-ORIG > ${file}
done
mkdir -p ${LFS}/var/lib/hwclock

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   echo " o Changing hard coded references to /usr/include to point at ${TGT_TOOLS}"
   flist=`grep -d recurse -l /usr/include *`
   for file in ${flist}; do
      (
      echo " - editing ${file}"
      test -f ${file}-ORIG || cp ${file} ${file}-ORIG
      sed 's@/usr/include@${TGT_TOOLS}/include@g' ${file}-ORIG > ${file}
      )
   done
fi

# Optimization defaults to -O2
max_log_init Util-linux ${UTILLINUX_VER} "Final (shared)" ${CONFLOGS} ${LOG}
export CC="${TARGET}-gcc ${ARCH_CFLAGS}"

# Here it is just plain ugly. We set CPU and ARCH to something that wont trigger
# anything in MCONFIG
export CPU=m68k
export ARCH=m68k
export DESTDIR=${LFS}

./configure \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# Don't build kill or sln
# (procps supplies kill and glibc supplies sln)
# No need to supply LDFLAGS="-s", taken care of during configure
#
# Optionally, for x86, unset CPUOPT (defaults to i486 if cpu not i386)
# or set specifically for your cpu type.
# See MCONFIG...
#
# also, build login by setting HAVE_SHADOW to no, this can be revisited
# if/when we cross-compile the shadow package

min_log_init ${BUILDLOGS} &&
make HAVE_KILL=yes HAVE_SLN=yes HAVE_SHADOW=no CPUOPT="" \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
echo Password:
su -c "export PATH=${PATH} ; make HAVE_KILL=yes HAVE_SLN=yes HAVE_SHADOW=no install" \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

