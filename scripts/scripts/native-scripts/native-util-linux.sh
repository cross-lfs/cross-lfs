#!/bin/bash

# cross-lfs native util-linux build
# ---------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=util-linux-native.log

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
   2.12[k-r] )
      # fix cramfs (issue w llh)
      apply_patch util-linux-2.12q-cramfs-1
   ;;
esac

case ${UTILLINUX_VER} in
   2.12[a-m] )
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
mkdir -p /var/lib/hwclock &&

# Optimization defaults to -O2
max_log_init Util-linux ${UTILLINUX_VER} "native (shared)" ${CONFLOGS} ${LOG}
export CC="${CC-gcc} ${ARCH_CFLAGS}"

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

min_log_init ${BUILDLOGS} &&
make HAVE_KILL=yes HAVE_SLN=yes CPUOPT="" \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make HAVE_KILL=yes HAVE_SLN=yes install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

