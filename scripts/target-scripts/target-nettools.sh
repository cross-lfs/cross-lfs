#!/bin/bash

# cross-lfs target net-tools build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

#set -x
cd ${SRC}
LOG=net-tools-target.log

set_libdirname
setup_multiarch

unpack_tarball net-tools-${NETTOOLS_VER}
cd ${PKGDIR}

# Retrieve target_gcc_ver from gcc -v output
target_gcc_ver=`${TARGET}-gcc -v 2>&1 | grep " version " | \
   sed 's@.*version \([0-9.]*\).*@\1@g'`

case ${target_gcc_ver} in
   3.4* | 4.* )
      # Fix some syntax so gcc-3.4 is kept happy
      # NOTE: this patch contains the miitool.c fix
      apply_patch net-tools-1.60-gcc34-3
   ;;
   * )
      # change string in miitool.c to something gcc-3.3 likes...
      # TODO: wrap some logic around this...
      apply_patch net-tools-1.60-miitool-gcc33-1
   ;;
esac


# If we are building with 2.6 headers we need to adjust the x25
# code in X25_setroute to use  the size of "struct x25_address"
# in the memcpy instead of "x25_address" ( x25_address is no longer
# a typedef in <linux/x25.h> )
case "${KERNEL_VER}" in
   2.6* )
      test -f lib/x25_sr.c-ORIG ||
         mv lib/x25_sr.c lib/x25_sr.c-ORIG

      sed 's@\(sizeof(\)\(x25_address)\)@\1struct \2@g' \
         lib/x25_sr.c-ORIG > lib/x25_sr.c
   ;;
esac

# Have noticed an issue with x86_64 biarch and linux-libc-headers-2.6.5.1
# iptunnel.c barfs out on redefinitions of 3 structs in <linux/if.h>
# ( ifmap, ifreq and ifconf )  which are also available in <net/if.h>.
# Removal of reference to <net/if.h> solved the issue...
# TODO: look into this


# Check for previously created configuration files for target.
# TODO: this really should go somewhere other than ${TARBALLS},
#       need a separate configs dir for the scripts for this and
#       kernel config...

test -f ${TARBALLS}/net-tools-${NETTOOLS_VER}-config-${TARGET}.tar.bz2 &&
{
   # Previously installed config files
   bzcat ${TARBALLS}/net-tools-${NETTOOLS_VER}-config-${TARGET}.tar.bz2 | \
      tar xvf -
} || {
   # Will have to do it interactively, save config for reuse
   make config

   tar -cvf ${TARBALLS}/net-tools-${NETTOOLS_VER}-config-${TARGET}.tar config.h config.make config.status
   bzip2 ${TARBALLS}/net-tools-${NETTOOLS_VER}-config-${TARGET}.tar
}

# Fix hostname.c for decnet (pulls in <netdnet/dn.h>, should use <linux/dn.h>
# NOTE: this doesn't fix it... cant be bothered looking into it,
#       just don't bother with decnet...
test -f hostname.c-ORIG ||
   mv hostname.c hostname.c-ORIG
sed 's@netdnet/dn.h@linux/dn.h@g' hostname.c-ORIG > hostname.c


# Have to pass SHELL="bash" to make so that we use bash's "test" as 
# /usr/bin/test under solaris (used when /bin/sh is invoked as it has no
# builtin) doesn't understand -nt (newer than)

max_log_init Net-tools ${NETTOOLS_VER} "target (shared)" ${BUILDLOGS} ${LOG}
make SHELL="bash" \
     CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
     AR="${TARGET}-ar" \
     COPTS="-D_GNU_SOURCE -O2 -Wall -pipe ${TGT_CFLAGS}" \
     LOPTS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make BASEDIR="${LFS}" update \
      >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

