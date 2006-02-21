#!/bin/bash

# functions for cross-lfs gcc builds
# -----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$

gcc_specs_mod() {

   # LFS style build
   #----------------

   # Set ARCH for header modifications.
   # Set dl_hfiles to contain the list of header file(s) requiring modification
   # of the location for the dynmamic linker.
   # Set sf_hfiles to contain the list of header file(s) where we have to define
   # startfile_prefix_spec.
   case ${TGT_ARCH} in
      i?86 | x86_64 )
         ARCH=i386
         dl_hfiles="${ARCH}/linux.h ${ARCH}/linux64.h"
         sf_hfiles="linux.h"
      ;;
      ia64* )
         ARCH=ia64
         dl_hfiles="${ARCH}/linux.h"
         sf_hfiles="linux.h"
      ;;
      powerpc* | ppc* )
         ARCH=rs6000
         dl_hfiles="${ARCH}/sysv4.h ${ARCH}/linux64.h"
         sf_hfiles="${ARCH}/linux.h ${ARCH}/linux64.h"
      ;;
      sparc* )
         ARCH=sparc
         dl_hfiles="${ARCH}/linux.h ${ARCH}/linux64.h"
         sf_hfiles="${ARCH}/linux.h ${ARCH}/linux64.h"
      ;;
      alpha )
         ARCH=alpha
         dl_hfiles="${ARCH}/linux-elf.h"
         sf_hfiles="${ARCH}/linux.h"
      ;;
      arm* )
         ARCH=arm
         dl_hfiles="${ARCH}/linux-elf.h"
         sf_hfiles="linux.h"
      ;;
      s390* )
         ARCH=s390
         dl_hfiles="${ARCH}/linux.h"
         sf_hfiles="linux.h"
      ;;
      m68k )
         ARCH=m68k
         dl_hfiles="${ARCH}/linux.h"
         sf_hfiles="linux.h"
      ;;
      m32r* )
         ARCH=m32r
         dl_hfiles="${ARCH}/linux.h"
         sf_hfiles="linux.h"
      ;;
      mips* )
         ARCH=mips
         dl_hfiles="${ARCH}/linux.h ${ARCH}/linux64.h"
         sf_hfiles="linux.h"
      ;;
      parisc* | hppa* )
         ARCH=pa
         dl_hfiles="${ARCH}/pa-linux.h"
         sf_hfiles="linux.h"
      ;;
      xtensa )
         ARCH=xtensa
         dl_hfiles="${ARCH}/linux.h"
         sf_hfiles="linux.h"
      ;;
      * )
         # No support
         echo "No support for ${TGT_ARCH}" 1>&2
         barf
      ;;
   esac

   specs_set_dynamic_linker
   specs_set_startfile_prefix_spec
}

specs_set_dynamic_linker() {
   # We want our new gcc to use our new dynamic linker
   # ( ${TGT_TOOLS}/lib/ld-linux.so.2 ) so we will need to modify
   # gcc/config/$ARCH/linux.h and or linux64.h
   # also sysv4.h for ppc and linux-elf.h for alpha
   # (where $ARCH is cpu-series type)
   #
   # LINK_SPEC needs to get defined so that
   #  -dynamic-linker is ${TGT_TOOLS}/lib/ld-linux.so.2 or 
   #  ${TOOLS}/lib64/ld-linux.so.2#
   # This sets --dynamic-linker correctly in the generated spec file

   cd ${SRC}/${PKGDIR}/gcc/config
   for hfile in ${dl_hfiles} ; do
      if [ -f ${hfile} ]; then
         if [ ! -f ${hfile}-ORIG ]; then
            cp ${hfile} ${hfile}-ORIG
         fi

         sed -e "s@\(/lib\(\|32\|64\)\)\(/ld\(\|64\)\.so\.1\|/ld-linux\(\|-ia64\|-x86-64\)\.so\.\(1\|2\)\)@${TGT_TOOLS}&@g" \
             -e "/elf.._sparc -Y P/s@/usr/lib@${TGT_TOOLS}/lib@g" \
             ${hfile}-ORIG > ${hfile}
      else
         echo "${0}: specs_set_dynamic_linker" 1>&2
         echo "   header file ${hfile} does not exist" 1>&2
         echo "" 1>&2
         echo "   Please check that the gcc_specs_mod function" 1>&2
         echo "   ( in cross-lfs/scripts/funcs/cross_gcc_funcs }" 1>&2
         echo "   is correct for your target arch." 1>&2
         barf
      fi
   done

}

specs_set_startfile_prefix_spec() {

   # Set STARTFILE_PREFIX_SPEC appropriately.
   echo " o setting STARTFILE_PREFIX_SPEC"

   cd ${SRC}/${PKGDIR}/gcc/config
   for hfile in ${sf_hfiles} ; do
      if [ -f ${hfile} ]; then
         echo "" >> ${hfile}
         echo "#undef STARTFILE_PREFIX_SPEC" >> ${hfile}
         echo "#define STARTFILE_PREFIX_SPEC \"${TGT_TOOLS}/lib/\"" >> ${hfile}
      else
         echo "${0}: specs_set_startfile_prefix_spec" 1>&2
         echo "   header file ${hfile} does not exist" 1>&2
         echo "" 1>&2
         echo "   Please check that the gcc_specs_mod function" 1>&2
         echo "   ( in cross-lfs/scripts/funcs/cross_gcc_funcs }" 1>&2
         echo "   is correct for your target arch." 1>&2
         barf
      fi
   done
}

cpp_set_cross_system_header_dir() {

   # Set cpp's default include search path, and the path 
   # fixincludes uses to search for headers
   echo " o setting ${TGT_TOOLS}/include as cpp's default include search dir"
   cd ${SRC}/${PKGDIR}/gcc
   test -f Makefile.in-ORIG ||
      mv Makefile.in Makefile.in-ORIG

   sed "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 ${TGT_TOOLS}/include@g" \
      Makefile.in-ORIG > Makefile.in
}

cpp_undef_standard_include_dir() {

   # We need to stop cpp using /usr/include as the standard include directory
   # when cross-building a target-native gcc.
   # This is defined in gcc/cppdefault.c using STANDARD_INCLUDE_DIR
   cd ${SRC}/${PKGDIR}/gcc
   test ! -f cppdefault.c-ORIG &&
      cp -p cppdefault.c cppdefault.c-ORIG

   sed -e '/#define STANDARD_INCLUDE_DIR/s@"/usr/include"@0@g' \
      cppdefault.c-ORIG > cppdefault.c
}

fixincludes_set_native_system_header_dir() {
 
   # For cross-building a target native gcc.
   # Set the path fixincludes uses to search for headers
   echo " o setting NATIVE_SYSTEM_HEADER_DIR to ${TGT_TOOLS}/include"
   cd ${SRC}/${PKGDIR}/gcc
   test -f Makefile.in-ORIG ||
      mv Makefile.in Makefile.in-ORIG

   sed "s@\(^NATIVE_SYSTEM_HEADER_DIR =\).*@\1 ${TGT_TOOLS}/include@g" \
      Makefile.in-ORIG > Makefile.in

}

configure_fix_flags_for_target() {

   # This is only necessary if 
   #  o you are building a multi-lib cross-compiler
   #  o you are not building into a sys-root
   #  o if ${TGT_TOOLS} = ${HST_TOOLS}/${TARGET} 
   # but doesn't hurt to apply in general.

   if [ "${TGT_TOOLS}" = "${HST_TOOLS}/${TARGET}" -a ! "${USE_SYSROOT}" = "Y" ]
   then

      # -B${HST_TOOLS}/${TARGET}/lib (set in FLAGS_FOR_TARGET)
      # is passed during the build, which causes issues if you are installing 
      # all your target startfiles/libraries under 
      # ${HST_TOOLS}/${TARGET}/lib{,32,64}
      #
      # -B takes precedence over -L and doesn't get altered by
      # the multilib spec, so you always end up linking in startfiles
      # from ${HST_TOOLS}/${TARGET}/lib when creating a shared libgcc.
      #
      # This is kinda painful when it should be, say, linking 64bit 
      # startfiles in from under */lib64 when creating the 64bit shared libgcc
      #
      # Here we just remove -B*/lib from FLAGS_FOR_TARGET.
      #
      # NOTE: for gcc-3.3.3 all we had do edit was configure.in,
      #       FLAGS_FOR_TARGET was only specified here.
      #       As of gcc-3.4.0 we need to edit configure itself.
      #       So, we'll just attempt to edit both
   
      cd ${SRC}/${PKGDIR}
      for file in configure configure.in; do
         grep FLAGS_FOR_TARGET ${file} > /dev/null 2>&1 &&
         {
            test -f ${file}-ORIG ||
               cp -p ${file} ${file}-ORIG

            sed '/FLAGS_FOR_TARGET.*\/lib\//s@-B[^ ]*/lib/@@g' \
               ${file}-ORIG > ${file}
         }
      done
   fi

}

export -f specs_set_startfile_prefix_spec
export -f specs_set_dynamic_linker
export -f gcc_specs_mod

export -f fixincludes_set_native_system_header_dir

export -f cpp_set_cross_system_header_dir
export -f cpp_undef_standard_include_dir
export -f configure_fix_flags_for_target
