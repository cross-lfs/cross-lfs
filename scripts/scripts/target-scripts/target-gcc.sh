#!/bin/bash

# cross-lfs target gcc build
# --------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}

LOG="gcc-target.log"

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="${extra_conf} --libdir=${BUILD_PREFIX}/${libdirname}"
fi

if [ "Y" = "${MULTIARCH}" ]; then
   vendor_os=`echo ${TARGET} | sed 's@\([^-]*\)-\(.*\)@\2@'`
   case ${TGT_ARCH} in
      x86_64 )
         TARGET=x86_64-${vendor_os}
      ;;
      sparc64* )
         TARGET=sparc64-${vendor_os}
      ;;
      sparc* )
         TARGET=sparc64-${vendor_os}
      ;;
      powerpc* | ppc* )
         TARGET=powerpc64-${vendor_os}
      ;;
      s390* )
         TARGET=s390x-${vendor_os}
      ;;
      mips*el* )
         TARGET=mips64el-${vendor_os}
      ;;
      * )
         # TODO: add some error messages etc
         barf
      ;;
   esac
else
   # If we are not bi-arch, disable multilib
   extra_conf="${extra_conf} --enable-multilib=no"

   # HACK: this sets abi to n32 with mips... this should be handled
   # by the multiarch funcs somehow... and set according to DEFAULTENV
   case ${TGT_ARCH} in
      mips* )
         extra_conf="${extra_conf} --with-abi=${DEFAULTENV}"
      ;;
   esac
fi

# if target has no floating point unit, use soft float
if [ "${WITHOUT_FPU}" = "Y" ]; then
   extra_conf="${extra_conf} --with-float=soft"
fi

unpack_tarball gcc-${GCC_VER}

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

# Apply linkonce patch for gcc (should be fixed come gcc 3.4.4)
cd ${SRC}/${PKGDIR}
case ${target_gcc_ver} in
   3.4.3 ) apply_patch gcc-3.4.3-linkonce-1
           apply_patch gcc-3.4.0-arm-bigendian
           apply_patch gcc-3.4.0-arm-nolibfloat
           apply_patch gcc-3.4.0-arm-lib1asm
           apply_patch gcc-3.4.3-clean_exec_and_lib_search_paths_when_cross-1
   ;;
   4.0.0 ) apply_patch gcc-4.0.0-fix_tree_optimisation_PR21173
           apply_patch gcc-4.0.0-reload_check_uninitialized_pseudos_PR20973
           apply_patch gcc-4.0.0-clean_exec_and_lib_search_paths_when_cross-1
   ;;
   4.0.* ) apply_patch gcc-4.0.0-clean_exec_and_lib_search_paths_when_cross-1 ;;
   4.1.* ) apply_patch gcc-4.0.0-clean_exec_and_lib_search_paths_when_cross-1 ;;
esac

# if we are using gcc-3.4x, set libexecdir to */${libdirname}
case ${target_gcc_ver} in
   3.4* | 4.* )
      extra_conf="${extra_conf} --libexecdir=${BUILD_PREFIX}/${libdirname}"
   ;;
esac

# HACK: should at least check if any of these are set first 
ARCH_CFLAGS="${TGT_CFLAGS} ${ARCH_CFLAGS}"

# if target is same as build host, adjust build slightly to avoid running
# configure checks which we cannot run
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # LFS style build
   #----------------

   # source functions for required gcc modifications
   . ${SCRIPTS}/funcs/cross_gcc-funcs.sh

   # Alter the generated specs file to 
   #  o set dynamic linker to be under ${TGT_TOOLS}/lib{,32,64}
   #  o set startfile_prefix_spec so we search for startfiles
   #    under ${TGT_TOOLS}/lib/lib{,32,64}
   gcc_specs_mod

   # We need to stop cpp using /usr/include as the standard include directory.
   # This is defined in gcc/cppdefault.c using STANDARD_INCLUDE_DIR
   cpp_undef_standard_include_dir

   # We need to override SYSTEM_HEADER_DIR so fixincludes only fixes
   # headers under ${TGT_TOOLS}
   fixincludes_set_native_system_header_dir
fi

# HACKS
#-------
# This here is a hack. mklibgcc runs the created xgcc for determining
# the multilib dirs and multilib os dirs. Only problem here is we are
# cross building a native compiler so we cannot actually run xgcc.
# We get around this by substituting our cross-compiler here for xgcc,
# by rights it should have the same specs and produce the expected results
#
# NOTE: with gcc-4.1 onwards we can just set GCC_FOR_TARGET to our cross-compiler
#       and be done with the shenannigans

extra_makeopts=""
case ${target_gcc_ver} in
   4.[1-9].* )
      extra_makeopts="${extra_makeopts} GCC_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-gcc"
   ;;
   * )
      cd ${SRC}/${PKGDIR}/gcc
      test -f mklibgcc.in-ORIG ||
         mv mklibgcc.in mklibgcc.in-ORIG

      sed "s@\./xgcc@${HST_TOOLS}/bin/${TARGET}-gcc@g" \
         mklibgcc.in-ORIG > mklibgcc.in

      # A similar problem exists when setting MULTILIBS on the environment
      # for the mklibgcc script for generation of libgcc.mk .
      # Here we will force it to use our cross-compiler to produce the results
      # of gcc --print-multi-lib
      sed -i "/MULTILIBS/s@\$(GCC_FOR_TARGET)@${HST_TOOLS}/bin/${TARGET}-gcc@g" \
         Makefile.in
   ;;
esac

# When cross-building a target native compiler we run into big issues
# when determining assembler and linker features required for tls support,
# ( not to mention which nm, objdump et al to use ) during the configures
# triggered by make.
#
# Gcc's configury does not take into account the fact that when cross
# building the target native compiler we are _still_ actually cross-compiling.
# As far as it is concerned during the final configure fragment host = target,
# it doesn't check whether host = build. 
#
# It then performs its checks for binutils components as if this was a standard 
# host native build.
#
# If a target native binutils was installed before attempting to build gcc
# it will try to use the created ld, as etc under ${TGT_TOOLS}
# This obviously will not work, they will not run on the host.
#
# If the target native binutils hasn't been built yet it will use the
# as ld et al from the _build_ host.
# This quite frankly sucks rocks.
#
# The following patch fixes this behaviour, enforcing usage of our
# cross-tools for configure checks if host = target and host != build
#
# NOTE: 20050507 This doesn't appear to be necessary for gcc 4.x :-)
#       This of course will have to be checked thoroughly...

# TODO: Add patches for gcc-3.3 series as well
cd ${SRC}/${PKGDIR}
case ${target_gcc_ver} in
   3.4* )
      apply_patch gcc-3.4.1-fix_configure_for_target_native
   ;;
   4.* )
      # Testing only... set AS_FOR_TARGET and LD_FOR_TARGET so these are used
      # for feature checks... will have to check for unintended side effects
      extra_makeopts="${extra_makeopts} AS_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-as"
      extra_makeopts="${extra_makeopts} LD_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-ld"
   ;;
esac
#
# End HACKS

test -d ${SRC}/gcc-${GCC_VER}-target &&
   rm -rf ${SRC}/gcc-${GCC_VER}-target

mkdir -p ${SRC}/gcc-${GCC_VER}-target &&
cd ${SRC}/gcc-${GCC_VER}-target &&

max_log_init Gcc ${GCC_VER} cross-pt2 ${CONFLOGS} ${LOG}
#CONFIG_SHELL=/bin/bash \
CFLAGS="-O2 -pipe" \
CXXFLAGS="-O2 -pipe" \
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --build=${BUILD} --host=${TARGET} --target=${TARGET} \
   --enable-languages=c,c++ --enable-__cxa_atexit \
   --enable-c99 --enable-long-long --enable-threads=posix \
   --disable-nls --enable-shared ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf
#   --enable-languages=c,c++,f77,objc,ada,java,pascal,treelang --enable-__cxa_atexit \
#   --enable-version-specific-runtime-libs \

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} BOOT_LDFLAGS="-s" BOOT_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" \
   STAGE1_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" ${extra_makeopts} all \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # Prep new root for target native glibc build
   libdirs="${libdirname}"
   if [ "Y" = "${MULTIARCH}" ]; then libdirs="lib lib32 lib64" ; fi
   for dir in ${libdirs} ; do
      if [ -d ${TGT_TOOLS}/${dir} ]; then
         test -d ${LFS}/usr/${dir} || mkdir -p ${LFS}/usr/${dir}
         ln -sf ../..${TGT_TOOLS}/${dir}/libgcc_s.so.1 \
            ${LFS}/usr/${dir}/libgcc_s.so.1
         test -f ${TGT_TOOLS}/${dir}/libgcc_s.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s.so
         test -f ${TGT_TOOLS}/${dir}/libgcc_s_32.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s_32.so
         test -f ${TGT_TOOLS}/${dir}/libgcc_s_64.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s_64.so
      fi
   done
fi

test -L ${INSTALL_PREFIX}/bin/cc || ln -s gcc ${INSTALL_PREFIX}/bin/cc

esac

# if we are using gcc-3.4x, set libexecdir to */${libdirname}
case ${target_gcc_ver} in
   3.4* | 4.* )
      extra_conf="${extra_conf} --libexecdir=${BUILD_PREFIX}/${libdirname}"
   ;;
esac

# HACK: should at least check if any of these are set first 
ARCH_CFLAGS="${TGT_CFLAGS} ${ARCH_CFLAGS}"

# if target is same as build host, adjust build slightly to avoid running
# configure checks which we cannot run
if [ "${TARGET}" = "${BUILD}" ]; then
   BUILD=`echo ${BUILD} | sed 's@\([_a-zA-Z0-9]*\)\(-[_a-zA-Z0-9]*\)\(.*\)@\1\2x\3@'`
fi

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # LFS style build
   #----------------

   # source functions for required gcc modifications
   . ${SCRIPTS}/funcs/cross_gcc-funcs.sh

   # Alter the generated specs file to 
   #  o set dynamic linker to be under ${TGT_TOOLS}/lib{,32,64}
   #  o set startfile_prefix_spec so we search for startfiles
   #    under ${TGT_TOOLS}/lib/lib{,32,64}
   gcc_specs_mod

   # We need to stop cpp using /usr/include as the standard include directory.
   # This is defined in gcc/cppdefault.c using STANDARD_INCLUDE_DIR
   cpp_undef_standard_include_dir

   # We need to override SYSTEM_HEADER_DIR so fixincludes only fixes
   # headers under ${TGT_TOOLS}
   fixincludes_set_native_system_header_dir
fi

# HACKS
#-------

# This here is a hack. mklibgcc runs the created xgcc for determining
# the multilib dirs and multilib os dirs. Only problem here is we are
# cross building a native compiler so we cannot actually run xgcc.
# We get around this by substituting our cross-compiler here for xgcc,
# by rights it should have the same specs and produce the expected results
#
# NOTE: with gcc-4.1 onwards we can just set GCC_FOR_TARGET to our cross-compiler
#       and be done with the shenannigans

extra_makeopts=""
case ${target_gcc_ver} in
   4.[1-9].* )
      extra_makeopts="${extra_makeopts} GCC_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-gcc"
   ;;
   * )
      cd ${SRC}/${PKGDIR}/gcc
      test -f mklibgcc.in-ORIG ||
         mv mklibgcc.in mklibgcc.in-ORIG

      sed "s@\./xgcc@${HST_TOOLS}/bin/${TARGET}-gcc@g" \
         mklibgcc.in-ORIG > mklibgcc.in

      # A similar problem exists when setting MULTILIBS on the environment
      # for the mklibgcc script for generation of libgcc.mk .
      # Here we will force it to use our cross-compiler to produce the results
      # of gcc --print-multi-lib
      sed -i "/MULTILIBS/s@\$(GCC_FOR_TARGET)@${HST_TOOLS}/bin/${TARGET}-gcc@g" \
         Makefile.in
   ;;
esac

# When cross-building a target native compiler we run into big issues
# when determining assembler and linker features required for tls support,
# ( not to mention which nm, objdump et al to use ) during the configures
# triggered by make.
#
# Gcc's configury does not take into account the fact that when cross
# building the target native compiler we are _still_ actually cross-compiling.
# As far as it is concerned during the final configure fragment host = target,
# it doesn't check whether host = build. 
#
# It then performs its checks for binutils components as if this was a standard 
# host native build.
#
# If a target native binutils was installed before attempting to build gcc
# it will try to use the created ld, as etc under ${TGT_TOOLS}
# This obviously will not work, they will not run on the host.
#
# If the target native binutils hasn't been built yet it will use the
# as ld et al from the _build_ host.
# This quite frankly sucks rocks.
#
# The following patch fixes this behaviour, enforcing usage of our
# cross-tools for configure checks if host = target and host != build
#
# NOTE: 20050507 This doesn't appear to be necessary for gcc 4.x :-)
#       This of course will have to be checked thoroughly...

# TODO: Add patches for gcc-3.3 series as well
cd ${SRC}/${PKGDIR}
case ${target_gcc_ver} in
   3.4* )
      apply_patch gcc-3.4.1-fix_configure_for_target_native
   ;;
   4.* )
      # set AS_FOR_TARGET and LD_FOR_TARGET so these are used for feature checks... 
      extra_makeopts="${extra_makeopts} AS_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-as"
      extra_makeopts="${extra_makeopts} LD_FOR_TARGET=${HST_TOOLS}/bin/${TARGET}-ld"
   ;;
esac
# End HACKS

test -d ${SRC}/gcc-${GCC_VER}-target &&
   rm -rf ${SRC}/gcc-${GCC_VER}-target

mkdir -p ${SRC}/gcc-${GCC_VER}-target &&
cd ${SRC}/gcc-${GCC_VER}-target &&

max_log_init Gcc ${GCC_VER} cross-pt2 ${CONFLOGS} ${LOG}
#CONFIG_SHELL=/bin/bash \
CFLAGS="-O2 -pipe" \
CXXFLAGS="-O2 -pipe" \
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
../${PKGDIR}/configure --prefix=${BUILD_PREFIX} \
   --build=${BUILD} --host=${TARGET} --target=${TARGET} \
   --enable-languages=c,c++ --enable-__cxa_atexit \
   --enable-c99 --enable-long-long --enable-threads=posix \
   --disable-nls --enable-shared ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf
#   --enable-languages=c,c++,f77,objc,ada,java,pascal,treelang --enable-__cxa_atexit \
#   --enable-version-specific-runtime-libs \

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} BOOT_LDFLAGS="-s" BOOT_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" \
   STAGE1_CFLAGS="-O2 ${HOST_CFLAGS} -pipe" ${extra_makeopts} all \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # Prep new root for target native glibc build
   libdirs="${libdirname}"
   if [ "Y" = "${MULTIARCH}" ]; then libdirs="lib lib32 lib64" ; fi
   for dir in ${libdirs} ; do
      if [ -d ${TGT_TOOLS}/${dir} ]; then
         test -d ${LFS}/usr/${dir} || mkdir -p ${LFS}/usr/${dir}
         ln -sf ../..${TGT_TOOLS}/${dir}/libgcc_s.so.1 \
            ${LFS}/usr/${dir}/libgcc_s.so.1
         test -f ${TGT_TOOLS}/${dir}/libgcc_s.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s.so
         test -f ${TGT_TOOLS}/${dir}/libgcc_s_32.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s_32.so
         test -f ${TGT_TOOLS}/${dir}/libgcc_s_64.so &&
            ln -sf libgcc_s.so.1 ${LFS}/usr/${dir}/libgcc_s_64.so
      fi
   done
fi

test -L ${INSTALL_PREFIX}/bin/cc || ln -s gcc ${INSTALL_PREFIX}/bin/cc

