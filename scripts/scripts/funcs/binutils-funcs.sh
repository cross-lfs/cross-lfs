#!/bin/bash
#
# functions for cross-lfs binutils build
# -----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

check_binutils () {
   # This should be run immediately after unpack_tarballs for binutils
   # so PKGDIR is set to the right directory

   # Check if this version of binutils requires
   # 'make configure-host'
   echo -e "Checking Binutils features...\n${BRKLN}"
   grep configure-host ${SRC}/${PKGDIR}/Makefile.in > /dev/null 2>&1 &&
      export BINUTILS_CONF_HOST=Y ||
      export BINUTILS_CONF_HOST=N 
   echo -e " o Requires 'make configure-host' ........... ${BINUTILS_CONF_HOST}"

   # Do we have --with-lib-path option to ld/configure 
   grep with-lib-path ${SRC}/${PKGDIR}/ld/configure > /dev/null 2>&1 &&
      export BINUTILS_WITH_LIB_PATH=Y ||
      export BINUTILS_WITH_LIB_PATH=N
   echo -e " o Has '--with-lib-path=' configure option .. ${BINUTILS_WITH_LIB_PATH}\n"

   # Modify ld/Makefile.in if necessary
   grep "GENSCRIPTS = LIB_PATH" ${SRC}/${PKGDIR}/ld/Makefile.in \
      > /dev/null 2>&1 ||
   {
      echo " o adding 'LIB_PATH = \$(LIB_PATH)' to GENSCRIPTS definition"
      echo "   in ld/Makefile.in"
      echo "   ( Passes value of LIB_PATH to genscripts.sh environment"
      echo -e "     for ldscript creation. )\n"

      test -f ${SRC}/${PKGDIR}/ld/Makefile.in-ORIG ||
         cp ${SRC}/${PKGDIR}/ld/Makefile.in \
            ${SRC}/${PKGDIR}/ld/Makefile.in-ORIG
      
      #TODO: fix this sed
      sed 's@^GENSCRIPTS = @GENSCRIPTS = LIB_PATH=\$\(LIB_PATH\) @g' \
         ${SRC}/${PKGDIR}/ld/Makefile.in-ORIG \
         > ${SRC}/${PKGDIR}/ld/Makefile.in
   }
}

# Export functions
export -f check_binutils

