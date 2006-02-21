#!/bin/bash
#
# Kernel stub header creation functions for cross-lfs build
# ---------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

set_stub_arch_switch() {
   case ${TGT_ARCH} in
   x86_64 | x86-64 )
      ARCH_SWITCH=__x86_64__
#      ARCH1=x86_64
#      ARCH2=i386
   ;;
   sparc* | ultrasparc* )
      ARCH_SWITCH=__arch64__
#      ARCH1=sparc64
#      ARCH2=sparc
   ;;
   ppc* | powerpc* )
      ARCH_SWITCH=__powerpc64__
#      ARCH1=ppc64
#      ARCH2=ppc
   ;;
   s390* )
      ARCH_SWITCH=__s390x__
#      ARCH1=s390x
#      ARCH2=s390
   ;;
   esac
}

# Creates kernel header stubs for biarch builds
create_kernel_stubs() {
   ARCH1=${1}
   ARCH1_SWITCH=${2}
   ARCH2=${3}
   KERN_HDR_DIR=${4}

   # Store the current directory so we can return.
   startdir=`pwd`
   for arch in ${ARCH1} ${ARCH2}; do
      cd ${KERN_HDR_DIR}/asm-${arch}
      dirs=`find . -type d | sed 's@^\.*\(\|/\)@@g'`
      hdrs=`find . -type f -name \*.h | sed 's@^\.*\(\|/\)@@g'`
      DIRS=`echo ${DIRS} ${dirs} | sort | uniq`
      HDRS=`echo ${HDRS} ${hdrs} | sort | uniq`
   done
   cd ${startdir}

   # Create directories (if required) under include/asm
   if [ "${DIRS}" != "" ]; then
      for dir in ${DIRS}; do
         mkdir -p ${KERN_HDR_DIR}/asm/${dir}
      done
   fi

   for hdr in ${HDRS}; do
      # include barrier
      name=`basename ${hdr} | tr [a-z]. [A-Z]_`
      cat > ${KERN_HDR_DIR}/asm/${hdr} << EOF
#ifndef __STUB__${name}__
#define __STUB__${name}__

EOF

      # check whether we exist in arch1
      if [ -f ${KERN_HDR_DIR}/asm-${ARCH1}/${hdr} ]; then
         # check if we also exist arch2
         if [ -f ${KERN_HDR_DIR}/asm-${ARCH2}/${hdr} ]; then
            # we exist in both
            cat >> ${KERN_HDR_DIR}/asm/${hdr} << EOF
#ifdef ${ARCH1_SWITCH}
#include <asm-${ARCH1}/${hdr}>
#else
#include <asm-${ARCH2}/${hdr}>
#endif
EOF
         else
            # we only exist in arch1
            cat >> ${KERN_HDR_DIR}/asm/${hdr} << EOF
#ifdef ${ARCH1_SWITCH}
#include <asm-${ARCH1}/${hdr}>
#endif
EOF
         fi
      # end arch1
      else
         # if we get here we only exist in arch2
         cat >> ${KERN_HDR_DIR}/asm/${hdr} << EOF
#ifndef ${ARCH1_SWITCH}
#include <asm-${ARCH2}/${hdr}>
#endif
EOF

      fi
      cat >> ${KERN_HDR_DIR}/asm/${hdr} << EOF

#endif /* __STUB__${name}__ */
EOF
      echo " - ${KERN_HDR_DIR}/asm/${hdr} created"

   done
}

# Export functions
export -f set_stub_arch_switch
export -f create_kernel_stubs

