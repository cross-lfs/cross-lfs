#!/bin/sh

setup_biarch() {

   libdir=lib
   # This to be set in the calling script if building libs into */lib64
   if [ "Y" = "${LIB64}" ]; then
      # Are we building 64bit userspace and bi-arch?
      # If so we want to install our libs into */lib64
      LOG=`echo $LOG | sed 's@\.log@-64&'`
      libdir=lib64
      extra_conf=" --libdir=/usr/lib64"
   fi

   if [ "Y" = "${BIARCH}" ]; then
      vendor_os=`echo ${TARGET} | sed 's@\([^-]*\)-\(.*\)@\2@'`
      if [ "Y" = "${LIB64}" ]; then
            # set arch specific 64 bit compilation flags
            case ${TGT_ARCH} in
               x86_64 )
                  export BUILDENV=64
                  ARCH_CFLAGS="-m${BUILDENV}"
                  unset ALT_TGT
               ;;
               sparc* )
                  export BUILDENV=64
                  ARCH_CFLAGS="-m${BUILDENV}"
                  unset ALT_TGT
               ;;
               powerpc* | ppc* )
                  export BUILDENV=64
                  ARCH_CFLAGS="-m${BUILDENV}"
                  unset ALT_TGT
               ;;
               s390* )
                  export BUILDENV=64
                  ARCH_CFLAGS="-m${BUILDENV}"
                  unset ALT_TGT
               ;;
            esac
         else
            # If not LIB64 we are building 32 (or 31) bit
            case ${TGT_ARCH} in
               x86_64 | x86-64 )
                  export BUILDENV=32
                  ARCH_CFLAGS="-m${BUILDENV}"
                  export ALT_TGT="i686-${vender_os}"
               ;;
               sparc* )
                  export BUILDENV=32
                  ARCH_CFLAGS="-m${BUILDENV}"
                  export ALT_TGT="sparcv9-${vender_os}"
               ;;
               powerpc* | ppc* )
                  export BUILDENV=32
                  ARCH_CFLAGS="-m${BUILDENV}"
                  export ALT_TGT="ppc-${vender_os}"
               ;;
               s390* )
                  export BUILDENV=31
                  ARCH_CFLAGS="-m${BUILDENV}"
                  export ALT_TGT="s390-${vender_os}"
               ;;
            esac
         fi

      suffix="-${BUILDENV}"
   fi
}
