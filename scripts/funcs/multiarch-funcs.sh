#!/bin/bash
#
# Multi-arch handling functions for cross-lfs build
# -------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# TODO: should really check if DEFAULTENV and LIBDIRENV have been set
#       in plfs-config and bail out if they have not...

set_buildenv() {
   case ${SELF} in
      *-64.sh )  BUILDENV=64 ;;
      *-32.sh )  BUILDENV=32 ;;
      *-n32.sh ) BUILDENV=n32 ;;
      *-o32.sh ) BUILDENV=o32 ;;
      *-o64.sh ) BUILDENV=o64 ;;
      * )        BUILDENV=${DEFAULTENV} ;;
   esac

   export BUILDENV
}

set_libdirname() {
   # TODO: this will barf on mips if setting 64bit libs to go to */lib
   #       but will work if setting
   if [ -z "${BUILDENV}" ]; then 
      BUILDENV=${DEFAULTENV}
      export BUILDENV
   fi
   if [ ! "${BUILDENV}" = "${LIBDIRENV}" ]; then
      case ${BUILDENV} in
         32 | o32 | n32 )   libdirname=lib32 ;;
         64 | o64 )         libdirname=lib64 ;;
         * )   echo "unknown buildenv ${BUILDENV}"; return 1
      esac
      LOG=`echo ${LOG} | sed "s@\.log@-${BUILDENV}&@"`
   else
      libdirname=lib
   fi

   # Adjust PKG_CONFIG_PATH 
   PKG_CONFIG_PATH=`echo "${PKG_CONFIG_PATH}" | \
                    sed -e "s@lib[36][124]@lib@g"  -e "s@lib@${libdirname}@g" `

   # Adjust GNOME_LIBCONF_PATH
   GNOME_LIBCONF_PATH=`echo "${GNOME_LIBCONF_PATH}" | \
                    sed -e "s@lib[36][124]@lib@g"  -e "s@lib@${libdirname}@g" `

   if [ "${MULTIARCH}" = "Y" ]; then
      export PERL=`which_func perl-${BUILDENV}`
      export PYTHON=`which_func python-${BUILDENV}`
   else
      export PERL=`which_func perl`
      export PYTHON=`which_func python`
   fi

}

which_func() {
   type ${1} | \
   sed -e 's@.* \(.*\)$@\1@g' \
       -e 's@[()]@@g'
}


# Following function sets compiler options
setup_multiarch() {
   if [ "Y" = "${MULTIARCH}" ]; then
      vendor_os=`echo ${TARGET} | sed 's@\([^-]*\)-\(.*\)@\2@'`
      TGT_ARCH=`echo ${TARGET} | sed 's@\([^-]*\).*@\1@'`

      ARCH_CFLAGS=""
      ALT_TGT=""

      case ${BUILDENV} in
      64 )
         case ${TGT_ARCH} in
            x86_64 )   ARCH_CFLAGS="-m${BUILDENV}" 
                       ARCH_LDFLAGS="-m elf_x86_64" ;;
            powerpc* | ppc* | s390* )
                       ARCH_CFLAGS="-m${BUILDENV}" ;;
            sparc* )   ARCH_CFLAGS="-m${BUILDENV}" 
                       ALT_TGT=sparc64-${vendor_os} ;;
            mips*el* ) ARCH_CFLAGS="-mabi=${BUILDENV}"
                       ALT_TGT="mips64el-${vendor_os}" ;;
            * )
               echo "### Unknown: ${TGT_ARCH} -  ${BUILDENV} ###" 1>&2
               return 1
            ;;
         esac
      ;;
      32 )
         case ${TGT_ARCH} in
            x86_64 | x86-64 )   ARCH_CFLAGS="-m${BUILDENV}"
                                ARCH_LDFLAGS="-m elf_i386"
                                ALT_TGT="i686-${vendor_os}" ;;
            powerpc* | ppc* )   ARCH_CFLAGS="-m${BUILDENV}"
                                ALT_TGT="ppc-${vendor_os}" ;;
            sparc* )            ARCH_CFLAGS="-m${BUILDENV}"
                                ALT_TGT="sparcv9-${vendor_os}" ;;
            mips*el* )          ARCH_CFLAGS="-mabi=${BUILDENV}"
                                ALT_TGT="mipsel-${vendor_os}" ;;
            * )
               echo "### Unknown: ${TGT_ARCH} -  ${BUILDENV} ###" 1>&2
               return 1
            ;;
         esac
      ;;
      n32 )
         case ${TGT_ARCH} in
            mips*el* )          ARCH_CFLAGS="-mabi=${BUILDENV}" ;;
            * )
               echo "### Unknown: ${TGT_ARCH} -  ${BUILDENV} ###" 1>&2
               return 1
            ;;
         esac
      ;;
      31 )
         case ${TGT_ARCH} in
            s390* ) ARCH_CFLAGS="-m${BUILDENV}"
                    ALT_TGT="s390-${vender_os}" ;;
            * )
               echo "### Unknown: ${TGT_ARCH} -  ${BUILDENV} ###" 1>&2
               return 1
            ;;
         esac
      ;;
      * )
         echo "### Unknown biarch system ###" 1>&2
         return 1
      ;;
      esac

      suffix="-${BUILDENV}"
   fi
}

create_wrapper() {
   # want one arg only, the name of the wrapper file to create
   if [ ! "${#}" = "1" ]; then
      echo "create_wrapper: error, use create_wrapper /path/to/wrapper" 1>&2
      return 1
   fi
   wrapper=${1}

   if [ -z "${DEFAULTENV}" ]; then
      echo "create_wrapper: error, DEFAULTENV not set" 1>&2
      return 1
   fi

   wrapperdir=`dirname ${wrapper}`
   if [ ! -d ${wrapperdir} ]; then mkdir -p ${wrapperdir} ; fi

   cat > ${wrapper} <<EOF
#!/bin/sh

# Set to default if BUILDENV not set
if [ -z \${BUILDENV} ]; then BUILDENV=${DEFAULTENV} ; fi
export BUILDENV
exec \${0}-\${BUILDENV} \${@}
EOF

   chmod 755 ${wrapper}

}

use_wrapper() {
   # Use full path
   wrapper=/usr/bin/multilib_wrapper

   if [ "${#}" = "0" ]; then
         echo "use_wrapper: error, no files specified" 1>&2
         return 1
   fi
   if [ -z "${BUILDENV}" ]; then
         echo "use_wrapper: error, BUILDENV not set" 1>&2
         return 1
   fi

   echo " o set files to use multi-arch wrapper ( ${wrapper} )"
   if [ ! -f ${wrapper} ]; then create_wrapper ${wrapper} || return 1 ; fi

   for file in ${@} ; do
      if [ ! -f ${file} ]; then
         echo "use_wrapper: error, ${file} is not a regular file" 1>&2
         return 1
      fi

      # do the work
      mv ${file} ${file}-${BUILDENV} &&
      ln -sf ${wrapper} ${file} &&
      echo "   - ${file}" || {
         echo "use_wrapper: error creating ${file}" 1>&2 
         return 1
      }

   done
}

export -f set_buildenv
export -f set_libdirname
export -f setup_multiarch
export -f create_wrapper
export -f use_wrapper
export -f which_func
