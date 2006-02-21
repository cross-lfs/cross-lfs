#!/bin/bash

# cross-lfs native /dev tree creation
# -----------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#


#set -x
cd ${SRC}
LOG=dev-native.log

do_makedev() {
   ### MAKEDEV ###
   LOG="MAKEDEV.log"
   max_log_init MAKEDEV ${MAKEDEV_VER} "" ${INSTLOGS} ${LOG}
   bzcat < ${TARBALLS}/MAKEDEV-${MAKEDEV_VER}.bz2 > /dev/MAKEDEV &&
   echo " o unpacked OK" &&
   cd /dev &&
   chmod 754 MAKEDEV &&
   echo "Password: " &&
   su -c "./MAKEDEV -v generic-nopty" > ${LOGFILE} 2>&1 &&
   echo " o Devices created OK" || barf
}

do_udev() {
   LOG=udev-native.log

   set_libdirname
   setup_multiarch

   unpack_tarball udev-${UDEV_VER}
   cd ${PKGDIR}

   # apply a patch to fix permissions on /dev/null being reset root 600 by
   # fcron. This behaviour appeared with udev-027
   case ${UDEV_VER} in
      027 )
         apply_patch udev-027-permissions-1
      ;;
   esac

   max_log_init udev ${UDEV_VER} "" ${BUILDLOGS} ${LOG}
   CFLAGS="${TGT_CFLAGS}" \
   make CC="${CC-gcc} ${ARCH_CFLAGS}" \
        LD="${CC-gcc} ${ARCH_CFLAGS}" \
        V="true" \
        udevdir=/dev \
      > ${LOGFILE} 2>&1 &&
   echo " o Build OK" || barf

   min_log_init ${INSTLOGS} &&
   CFLAGS="${TGT_CFLAGS}" \
   make CC="${CC-gcc} ${ARCH_CFLAGS}" \
        LD="${CC-gcc} ${ARCH_CFLAGS}" \
        V="true" \
        udevdir=/dev install \
      > ${LOGFILE} 2>&1 &&
   echo " o Install OK" || barf

   # Create bare minimum devices required
   mknod -m 600 /dev/console c 5 1
   mknod -m 666 /dev/null c 1 3

   # create rules and permissions files
   echo " - Adding rules/permissions files"
   case ${UDEV_VER} in
      02[7-9] | 0[3-4]* | 050 )
         cp ${CONFIGS}/udev/udev-config-2.permissions \
            /etc/udev/permissions.d/25-lfs.permissions
         cp ${CONFIGS}/udev/udev-config-1.rules \
            /etc/udev/rules.d/25-lfs.rules
      ;;
      # This was last updated for 056, this will need to be tracked...
      05[1-9] | 0[6-9]* )
         cp ${CONFIGS}/udev/udev-config-3.rules \
            /etc/udev/rules.d/25-lfs.rules
      ;;
   esac
}

case "${KERNEL_VER}" in
   2.5* | 2.6* )
      if [ "Y" = "${UDEV}" ]; then
         do_udev
      elif [ "Y" = "${DEVFS}" ]; then
         do_devfsd
      else
         do_makedev
      fi
   ;;
   2.4* )
      if [ "Y" = "${DEVFS}" ]; then
         do_devfs
      else
         do_makedev
      fi
   ;;
   2.2* )
      do_makedev
   ;;
esac
