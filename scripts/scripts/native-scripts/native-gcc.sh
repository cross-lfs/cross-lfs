#!/bin/bash

# cross-lfs native gcc build
# --------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

LOG="gcc-native.log"

set_libdirname
setup_multiarch

unpack_tarball gcc-${GCC_VER}

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

#3.0 20030427
# Cannot trust ${GCC_VER} to supply us with the correct
# gcc version (especially if cvs).
# Grab it straight from version.c
cd ${SRC}/${PKGDIR}
target_gcc_ver=`grep version_string gcc/version.c | \
                sed 's@.* = \(\|"\)\([0-9.]*\).*@\2@g'`
# As of gcc4, the above doesn't cut it... check gcc/BASE-VER
if [ -z "${target_gcc_ver}" -a -f gcc/BASE-VER ]; then
   target_gcc_ver=`cat gcc/BASE-VER`
fi

# if target has no floating point unit, use soft float
if [ "${WITHOUT_FPU}" = "Y" ]; then
   extra_conf="${extra_conf} --with-float=soft"
fi

if [ ! "Y" = "${MULTIARCH}" ]; then
   # If we are not multi-arch, disable multilib
   extra_conf="${extra_conf} --enable-multilib=no"

   # HACK: this sets abi to n32 with mips... this should be handled
   # by the multiarch funcs somehow... and set according to DEFAULTENV
   case ${TGT_ARCH} in
      mips* )
         extra_conf="${extra_conf} --with-abi=${DEFAULTENV}"
      ;;
   esac
fi

# if we are using gcc-3.4x, set libexecdir to /usr/${libdirname}
case ${target_gcc_ver} in
   3.4* | 4.* )
      extra_conf="${extra_conf} --libexecdir=/usr/${libdirname}"
   ;;
esac

# Set in build-init to enable version specific runtime libs, and whether
# to use a program suffix
if [ "Y" = "${USE_VER_SPEC_RT_LIBS}" ]; then
   extra_conf="${extra_conf} --enable-version-specific-runtime-libs" ; fi
if [ "Y" = "${USE_PROGRAM_SUFFIX}" ]; then
   extra_conf="${extra_conf} --program-suffix=-${target_gcc_ver}" ; fi

cd ${SRC}/${PKGDIR}
case ${target_gcc_ver} in
   3.4.3 )
      # Apply linkonce patch for gcc (should be fixed come gcc 3.4.4)
      apply_patch gcc-3.4.3-linkonce-1 
      # Remove library search paths that cause issues with libtool on 
      # multi-arch systems
      # TODO: check to see if this applies to ealier gcc versions, and
      #       decide if this should only be applied if doing a multi-archi
      #       build
      apply_patch gcc-3.4.3-remove_standard_startfile_prefix_from_startfile_prefixes-1

      # Arm fixes
      apply_patch gcc-3.4.0-arm-bigendian
      apply_patch gcc-3.4.0-arm-nolibfloat
      apply_patch gcc-3.4.0-arm-lib1asm
   ;;
   4.0.0 )
      apply_patch gcc-4.0.0-fix_tree_optimisation_PR21173
      apply_patch gcc-4.0.0-reload_check_uninitialized_pseudos_PR20973
      apply_patch gcc-4.0.0-remove_standard_startfile_prefix_from_startfile_prefixes-1
   ;;
   4.0.* | 4.1.* )
      apply_patch gcc-4.0.0-remove_standard_startfile_prefix_from_startfile_prefixes-1
   ;;
esac


# Dont run fixincludes
# ( Following mimics the nofixincludes patch )
# NOTE: This needs to be fixed for gcc4
# Also avoid debug symbols in libgcc2
cd ${SRC}/${PKGDIR}/gcc

test -f Makefile.in-ORIG ||
   cp Makefile.in Makefile.in-ORIG
                                                                                
#grep -Ev '(README| ./fixinc.sh )' Makefile.in-ORIG | \
sed 's@LIBGCC2_DEBUG_CFLAGS = -g@LIBGCC2_DEBUG_CFLAGS =@g' Makefile.in-ORIG \
   > Makefile.in

# Problems arise when building 64bit libgcc_s during a multilib
# build if the 64bit crt objects reside under */lib64 as
# -B${HST_TOOLS}/${TARGET}/lib is passed during the build causing
# us to link in the 32bit crt objects.,
# This is because -B*/lib overrides the specs file so the  multilib
# spec isnt used to determine lib dir.
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
      # copy instead of move, we will want to retain perms
      test -f ${file}-ORIG ||
         cp -p ${file} ${file}-ORIG

      sed '/FLAGS_FOR_TARGET.*\/lib\//s@-B[^ ]*/lib/@@g' \
         ${file}-ORIG > ${file}
   }
done

test -d ${SRC}/gcc-${GCC_VER}-native &&
   rm -rf ${SRC}/gcc-${GCC_VER}-native

mkdir -p ${SRC}/gcc-${GCC_VER}-native &&
cd ${SRC}/gcc-${GCC_VER}-native &&

max_log_init Gcc ${GCC_VER} native ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
../${PKGDIR}/configure --prefix=/usr \
   --host=${TARGET} \
   --enable-languages=c,c++ --enable-__cxa_atexit \
   --enable-c99 --enable-long-long --enable-threads=posix \
   --enable-shared ${extra_conf} \
   --mandir=/usr/share/man \
   --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf
#   --enable-languages=c,c++,f77,objc,ada,java,pascal,treelang --enable-__cxa_atexit \

min_log_init ${BUILDLOGS} &&
if [ "Y" = "${NOBOOTSTRAP}" ]; then
   make ${PMFLAGS} LDFLAGS="-s" \
      >> ${LOGFILE} 2>&1
else 
   make ${PMFLAGS} BOOT_LDFLAGS="-s" BOOT_CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
      STAGE1_CFLAGS="-O2 -pipe ${TGT_CFLAGS}" bootstrap \
      >> ${LOGFILE} 2>&1
fi && 
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make -k check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

#3.0 20030503
# Create symlinks if we chose to add a version suffix
if [ "Y" = "${USE_PROGRAM_SUFFIX}" ]; then
   for prog in c++ c++filt cpp g++ gcc gccbug gcov ; do
      if [ -f /usr/bin/${prog}-${target_gcc_ver} ]; then
         echo " o Creating ${prog} -> ${prog}-${target_gcc_ver} symlink..."
         ln -sf ${prog}-${target_gcc_ver} /usr/bin/${prog}
      fi
   done
   for prog in gcc g++ c++ ; do
      if [ -f /usr/bin/${TARGET}-${prog}-${target_gcc_ver} ]; then
         echo " o Creating ${TARGET}-${prog} -> ${TARGET}-${prog}-${target_gcc_ver} symlink ..."
         ln -sf ${TARGET}-${prog}-${target_gcc_ver} \
            /usr/bin/${TARGET}-${prog}
      fi
   done
fi # USE_PROGRAM_SUFFIX

ln -s ../usr/bin/cpp /lib &&
ln -sf gcc /usr/bin/cc
rm /usr/${libdirname}/libiberty.a

# Following req'd when using --enable-version-specific-runtime-libs
if [ Y = "${USE_VER_SPEC_RT_LIBS}" ]; then
   # TODO: BIG TODO HERE 
   #       MAKE THIS HANDLE "libdirname"
   #       -----------------------------
   #       look into gcc_libdir/../lib/libdirname symlinks for multiarch
   #       This is appropriate for x86_64, bit others need to be checked...
   #       We will also in the future want to modify these default gcc .so
   #       install directories
   #

   gcc_libdir=`/usr/bin/gcc --print-file-name include | \
            sed 's@include@@g'`

   # Better make a symlink for the c++ includes
   mkdir /usr/include/c++
   ln -s ${gcc_libdir}/include/c++ /usr/include/c++/${target_gcc_ver}
                                                                                
   # Add the path to our new c++ libs in /etc/ld.so.conf
   echo "${gcc_libdir}" >> /etc/ld.so.conf
   if [ Y = "${MULTIARCH}" ]; then 
      echo "${gcc_libdir}/32" >> /etc/ld.so.conf
   fi

   # TODO: choose whether to just delete existing libgcc_s.so links pointing to
   # ${TOOLS} or just create the following over the top
                                                                                
   # Create hardlink and symlinks for libgcc_s in /usr/lib
   case ${target_gcc_ver} in
      3.4* | 4.* )
         if [ Y = "${MULTIARCH}" ]; then
            # 32bit libs
            ln -f ${gcc_libdir}/../lib/libgcc_s.so.1 \
               /usr/lib/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 \
               /usr/lib/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s_32.so
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s.so
            # 64bit libs
            ln -f ${gcc_libdir}/../lib64/libgcc_s.so.1 \
               /usr/lib64/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 \
               /usr/lib64/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib64/libgcc_s.so
         else
            ln -f ${gcc_libdir}/../lib/libgcc_s.so.1 \
               /usr/lib/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 /usr/lib/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s.so
         fi
      ;;
      * )
         # TODO: Have to check this for gcc < 3.4   
         ln -f ${gcc_libdir}/libgcc_s.so.1 \
            /usr/${libdirname}/libgcc_s-${target_gcc_ver}.so.1
         if [ Y = "${MULTIARCH}" ]; then
            # 32bit libs
            ln -f ${gcc_libdir}/32/libgcc_s.so.1 \
               /usr/lib/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 \
               /usr/lib/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s_32.so
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s.so
            # 64bit libs
            ln -f ${gcc_libdir}/libgcc_s.so.1 \
               /usr/lib64/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 \
               /usr/lib64/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib64/libgcc_s.so
         else
            ln -f ${gcc_libdir}/libgcc_s.so.1 \
               /usr/lib/libgcc_s-${target_gcc_ver}.so.1
            ln -sf libgcc_s-${target_gcc_ver}.so.1 \
               /usr/lib/libgcc_s.so.1
            ln -sf libgcc_s.so.1 /usr/lib/libgcc_s.so
         fi
      ;;
   esac

fi
