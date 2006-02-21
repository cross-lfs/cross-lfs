#!/bin/bash

# functions for cross-lfs glibc builds
# -----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$

apply_glibc_patches() {
   
   # This function should only be called from inside the unpacked glibc source
   # This function also expects the following vars to be set by the caller
   #
   # target_gcc_ver   : should be derived either from gcc itself or gcc headers
   # target_glibc_ver : should be derived from glibc headers
   # kernver          : should be derived from kernel headers

   # Patching 
   #---------
   # TODO: check if patches still reqd for < glibc 2.3.3 with later gcc's
   #       (ie 3.4+)
   case ${target_gcc_ver} in
      4.* )
         echo " o compiling with gcc 4.x"
         case ${target_glibc_ver} in
            2.3.[7-9]* | 2.4.* ) ;;
            2.3.6 )
               apply_patch glibc-20051024-localedef_segfault-1

               case ${TGT_ARCH} in
               sparc* )
                  # fix CFLAGS-rtld to remove deprecated sparc compiler options
                  # from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile 
                  # ( -mv8 is no longer supported ). Use -mcpu -mtune options 
                  # from TGT_CFLAGS (which get passed regardless)
                  echo "   - removing deprecated gcc options from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  file="sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  if [ ! -f ${file}-ORIG ]; then cp -p ${file} ${file}-ORIG ; fi
                  grep -v \\-mv8 ${file}-ORIG > ${file}
               ;;
               esac

            ;;
            2.3.5 )
               # gcc4 support is working in CVS glibc

               if [ ! -d ${SRC}/${PKGDIR}/CVS ]; then
                  echo "   - applying gcc4 fixes"
                  apply_patch glibc-2.3.4-gcc4_elf_fixes
                  apply_patch glibc-2.3.4-allow-gcc-4.0-iconvdata
                  apply_patch glibc-2.3.4-allow-gcc-4.0-powerpc-procfs
                  apply_patch glibc-2.3.5-allow-gcc-4.0-wordexp
                  apply_patch glibc-2.3.5-allow-gcc4-string
                  apply_patch glibc-2.3.5-allow-gcc4-symbols
                  apply_patch glibc-2.3.5-allow-gcc4-wcstol_l
               fi

               case ${TGT_ARCH} in
               sparc* )
                  # fix CFLAGS-rtld to remove deprecated sparc compiler options
                  # from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile 
                  # ( -mv8 is no longer supported ). Use -mcpu -mtune options 
                  # from TGT_CFLAGS (which get passed regardless)
                  echo "   - removing deprecated gcc options from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  file="sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  if [ ! -f ${file}-ORIG ]; then cp -p ${file} ${file}-ORIG ; fi
                  grep -v \\-mv8 ${file}-ORIG > ${file}
               ;;
               esac
               
            ;;
            2.3.4* )
               echo "   - applying gcc4 fixes"
               apply_patch glibc-2.3.4-gcc4_elf_fixes
               apply_patch glibc-2.3.4-allow-gcc-4.0-iconvdata
               apply_patch glibc-2.3.4-allow-gcc-4.0-powerpc-procfs
               apply_patch glibc-2.3.5-allow-gcc4-string
               apply_patch glibc-2.3.5-allow-gcc4-symbols
               apply_patch glibc-2.3.5-allow-gcc4-wcstol_l

               case ${TGT_ARCH} in
               sparc* )
                  # fix CFLAGS-rtld to remove deprecated sparc compiler options
                  # from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile 
                  # ( -mv8 is no longer supported ). Use -mcpu -mtune options 
                  # from TGT_CFLAGS (which get passed regardless)
                  echo "   - removing deprecated gcc options from sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  file="sysdeps/unix/sysv/linux/sparc/sparc32/Makefile"
                  if [ ! -f ${file}-ORIG ]; then cp -p ${file} ${file}-ORIG ; fi
                  grep -v \\-mv8 ${file}-ORIG > ${file}
               ;;
               esac

            ;;
            * )
               echo " compiling with gcc4 for ${target_glibc_ver} not supported" 1>&2
               barf
            ;;
         esac
      ;;
      3.3* )
         echo " o compiling with gcc 3.3x"
         case ${target_glibc_ver} in
            2.3.[345] ) ;;
            2.3.2 )
               # CVS glibc doesn't require gcc-33 patch
               if [ ! -d ${SRC}/${PKGDIR}/CVS ]; then
                  apply_patch glibc-2.3.2-gcc33
               fi
            ;;
            2.3* )
               apply_patch glibc-2.3.2-gcc33
            ;;
         esac
      ;;
   esac
   
   # 20031008 - add patch to fix assertion in rtld.c
   #            this smells hackish but we will see...
   # TODO: should check for presence of sysinfo DSO in kernel source
   # 20040711 - not required for current ( 2.3.3 + 2.3.4 ) glibc's
   #apply_patch glibc-${XXX}2.3.2-fix-rtld
   
   case ${kernver} in
      2.[56].* )
         # 2.3.1b2 20030630
         # We have to patch sysdeps/unix/sysv/linux/sys/sysctl.h to
         # so we can build against 2.5/2.6 kernels (if not fixed already).
         fname="${SRC}/${PKGDIR}/sysdeps/unix/sysv/linux/sys/sysctl.h"
         grep "linux/compiler.h" ${fname} > /dev/null 2>&1 ||
         {
            echo " - patching ${fname}"
            mv ${fname} ${fname}-ORIG
            sed -e '/#include <linux\/sysctl.h>/i\
#include <linux/compiler.h>' \
            ${fname}-ORIG > ${fname}
         }

         case ${TGT_ARCH} in
            m68k* )
               echo - applying m68k no-precision-timers patch
               patch -p1 < ${PATCHES}/glibc-2.3.3-lfh-m68k-no-precision-timers.patch
            ;;
            arm* ) apply_patch glibc-arm-ctl_bus_isa ;;
         esac

      ;;
      2.4.2[4-9] | 2.4.3* )
         case ${TGT_ARCH} in
            arm* ) apply_patch glibc-arm-ctl_bus_isa ;;
         esac
      ;;
   esac

   case ${TGT_ARCH} in
      m68k* )
         # TODO: wrap some logic around this to check glibc ver
         #       before applying this patch
         apply_patch glibc-2.3.3-lfs-5.1-m68k_fix_fcntl
      ;;
      mips* )
         # Fix syscalls for mips w 2.3.4 
          case ${target_glibc_ver} in
             2.3.[45] ) apply_patch glibc-2.3.4-mips_syscall-2 ;;
          esac
      ;;
   esac
}

export -f apply_glibc_patches
