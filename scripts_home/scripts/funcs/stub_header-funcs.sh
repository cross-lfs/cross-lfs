#!/bin/bash
#
# Stub Header Functions for cross-lfs build
# -----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

set_stub_arch_switch() {
   # TODO: this needs to be revisited... only handles 2 arches
   case ${TGT_ARCH} in
   x86_64 )
      LIBDIRENV=${LIBDIRENV-32}
      DEFAULTENV=${DEFAULTENV-64}
      ARCH_SWITCH=__x86_64__
      ENV1=64
      ENV2=32
   ;;
   sparc* | ultrasparc* )
      LIBDIRENV=${LIBDIRENV-32}
      DEFAULTENV=${DEFAULTENV-64}
      ARCH_SWITCH=__arch64__
      ENV1=64
      ENV2=32
   ;;
   ppc* | powerpc* )
      LIBDIRENV=${LIBDIRENV-32}
      DEFAULTENV=${DEFAULTENV-64}
      ARCH_SWITCH=__powerpc64__
      ENV1=64
      ENV2=32
   ;;
   s390* )
      LIBDIRENV=${LIBDIRENV-31}
      DEFAULTENV=${DEFAULTENV-64}
      ARCH_SWITCH=__s390x__
      ENV1=64
      ENV2=31
   ;;
   * )
      echo "set_stub_arch_switch: error, TGT_ARCH=${TGT_ARCH} unknown" 1>&2
      return 1
   ;;
   esac
}

create_stub_hdrs() {
   if [ "${#}" = "0" ]; then
      echo "create_stub_hdrs: error, no headers specified" 1>&2
      return 1
   fi

   if [ -z "${BUILDENV}" ]; then
      echo "create_stub_hdrs: error, BUILDENV not set" 1>&2
      return 1
   fi

   set_stub_arch_switch || return 1

   echo " o creating stub headers"

   for file in ${@} ; do
      hdr=`basename ${file}`
      hdrdir=`dirname ${file}`
      barrier="__STUB__$( echo ${hdr} | tr [a-z]. [A-Z]_ )__"

      if [ ! -f ${file} ]; then
         echo "create_stub_hdrs: error, header ${file} does not exist" 1>&2
         return 1
      fi

      # If the header we are making a stub for is a stub header we created earlier,
      # do not continue as something has gone wrong...
      head -n 1 ${file} | grep "#ifndef ${barrier}" > /dev/null 2>&1 && {
         echo "create_stub_hdrs: error, ${file} is a stub header" 1>&2
         return 1
      }

      # create the dirctory to house the real header (if it does not already exist)
      if [ ! -d ${hdrdir}/${BUILDENV} ]; then
         mkdir ${hdrdir}/${BUILDENV}
      fi

      # move the real header
      mv ${file} ${hdrdir}/${BUILDENV} || {
         echo "create_stub_hdrs: error, unable to move ${file} to ${hdrdir}/${BUILDENV}" 1>&2
         return 1
      }

      # Generate the header stub

      # include barrier
      echo "#ifndef ${barrier}" > ${hdrdir}/${hdr}
      echo "#define ${barrier}" >> ${hdrdir}/${hdr}
      echo ""                   >> ${hdrdir}/${hdr}

      if [ -f ${hdrdir}/${ENV1}/${hdr} ]; then
         echo "#ifdef ${ARCH_SWITCH}"       >> ${hdrdir}/${hdr}
         echo "#include \"${ENV1}/${hdr}\"" >> ${hdrdir}/${hdr}
         if [ -f ${hdrdir}/${ENV2}/${hdr} ]; then
            echo "#else"                       >> ${hdrdir}/${hdr}
            echo "#include \"${ENV2}/${hdr}\"" >> ${hdrdir}/${hdr}
         fi
      elif [ -f ${hdrdir}/${ENV2}/${hdr} ]; then
         echo "#ifndef ${ARCH_SWITCH}"      >> ${hdrdir}/${hdr}
         echo "#include \"${ENV2}/${hdr}\"" >> ${hdrdir}/${hdr}
      else
         echo "create_stub_hdr: error, something really b0rked here" 1>&2
         return 1
      fi
      echo "#endif /* ${ARCH_SWITCH} */" >> ${hdrdir}/${hdr}
   
      echo ""                        >> ${hdrdir}/${hdr}
      echo "#endif /* ${barrier} */" >> ${hdrdir}/${hdr}

      echo "   - ${hdrdir}/${hdr}"

   done
}

create_stub_hdr() {
   hdr=`basename ${1}`
   hdrdir=`dirname ${1}`
   barrier="__STUB__$( echo ${hdr} | tr [a-z]. [A-Z]_ )__"

   set_stub_arch_switch

   # setup include barrier
   echo "#ifndef ${barrier}" > ${hdrdir}/${hdr}
   echo "#define ${barrier}" >> ${hdrdir}/${hdr}
   echo ""                   >> ${hdrdir}/${hdr}

   if [ -f ${hdrdir}/${ENV1}/${hdr} ]; then
      echo "#ifdef ${ARCH_SWITCH}"       >> ${hdrdir}/${hdr}
      echo "#include \"${ENV1}/${hdr}\"" >> ${hdrdir}/${hdr}
      if [ -f ${hdrdir}/${ENV2}/${hdr} ]; then
         echo "#else"                       >> ${hdrdir}/${hdr}
         echo "#include \"${ENV2}/${hdr}\"" >> ${hdrdir}/${hdr}
      fi
   elif [ -f ${hdrdir}/${ENV2}/${hdr} ]; then
      echo "#ifndef ${ARCH_SWITCH}"      >> ${hdrdir}/${hdr}
      echo "#include \"${ENV2}/${hdr}\"" >> ${hdrdir}/${hdr}
   else
      echo "create_stub_hdr: error, something really b0rked here" 1>&2
      return 1
   fi
   echo "#endif /* ${ARCH_SWITCH} */" >> ${hdrdir}/${hdr}

   echo ""                        >> ${hdrdir}/${hdr}
   echo "#endif /* ${barrier} */" >> ${hdrdir}/${hdr}

   echo "   - ${hdrdir}/${hdr}"

}

      
# Export functions
export -f set_stub_arch_switch
export -f create_stub_hdrs
