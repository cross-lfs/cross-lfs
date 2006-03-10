#!/bin/bash

# cross-lfs target bash build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=bash-target.log

unpack_tarball bash-${BASH_VER} &&
cd ${PKGDIR}

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

case ${BASH_VER} in
   2.05b )
      # Apply published official patches fro bash-2.05b
      apply_patch bash-2.05b-gnu_fixes-2
      if [ x${TGT_ARCH} = xm68k ]; then
         cat >config.cache <<END
ac_cv_func_setvbuf_reversed=${ac_cv_func_setvbuf_reversed=no}
bash_cv_dup2_broken=${bash_cv_dup2_broken=no}
bash_cv_func_sigsetjmp=${bash_cv_func_sigsetjmp=present}
bash_cv_func_strcoll_broken=${bash_cv_func_strcoll_broken=yes}
bash_cv_getcwd_calls_popen=${bash_cv_getcwd_calls_popen=no}
bash_cv_getenv_redef=${bash_cv_getenv_redef=yes}
bash_cv_have_mbstate_t=${bash_cv_have_mbstate_t=yes}
bash_cv_job_control_missing=${bash_cv_job_control_missing=present}
bash_cv_must_reinstall_sighandlers=${bash_cv_must_reinstall_sighandlers=no}
bash_cv_pgrp_pipe=${bash_cv_pgrp_pipe=no}
bash_cv_printf_a_format=${bash_cv_printf_a_format=yes}
bash_cv_sys_named_pipes=${bash_cv_sys_named_pipes=present}
bash_cv_sys_siglist=${bash_cv_sys_siglist=yes}
bash_cv_ulimit_maxfds=${bash_cv_ulimit_maxfds=yes}
bash_cv_under_sys_siglist=${bash_cv_under_sys_siglist=yes}
bash_cv_opendir_not_robust=${bash_cv_opendir_not_robust=no}
bash_cv_unusable_rtsigs=${bash_cv_unusable_rtsigs=no}
END
      else
         cat >config.cache <<END
bash_cv_have_mbstate_t=${bash_cv_have_mbstate_t=yes}
END
      fi

      # If using gcc-3.4.x, patch some syntax gcc-3.4 doesn't like
      # TODO: Get gcc version from cross-gcc itself
      case ${GCC_VER} in
         3.4* )
            apply_patch bash-2.05b-gcc34-1
         ;;
      esac
   ;;
   3.0 )
      # Reported on bug-bash by Tim Waugh <twaugh@redhat.com>
      # http://lists.gnu.org/archive/html/bug-bash/2004-09/msg00081.html 
      apply_patch bash-3.0-fixes-1
      apply_patch bash-3.0-avoid_WCONTINUED-1
   ;;
   3.1 )
      apply_patch bash-3.1-fixes-5
      cat >config.cache <<END
ac_cv_func_setvbuf_reversed=${ac_cv_func_setvbuf_reversed=no}
END
   ;;
esac

# Patch Makefile.in to use ${TARGET}-size instead of size
test -f Makefile.in-ORIG ||
   mv Makefile.in Makefile.in-ORIG

# Following defaults to powerpc if doing ppc* build...
#sed 's@size \$(Program)@\$(MACHTYPE)-&@g' Makefile.in-ORIG > Makefile.in
sed "s@size \$(Program)@${TARGET}-&@g" Makefile.in-ORIG > Makefile.in

max_log_init Bash ${BASH_VER} "target (shared)" ${CONFLOGS} ${LOG}
CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CXX="${TARGET}-g++ ${ARCH_CFLAGS}" \
AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} --with-curses --cache-file=config.cache \
   --without-bash-malloc \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# Don't build bash with parallelism, race conditions cause version.h
# not to be created
min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ln -sf bash ${INSTALL_PREFIX}/bin/sh
