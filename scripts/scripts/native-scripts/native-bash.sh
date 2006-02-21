#!/bin/bash

# cross-lfs native bash build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=bash-native.log

set_libdirname
setup_multiarch

unpack_tarball bash-${BASH_VER} &&
cd ${PKGDIR}

# If using gcc-3.4.x, patch some syntax gcc-3.4 doesn't like
# TODO: Get gcc version from cross-gcc itself

case ${BASH_VER} in
   2.05b )
      # Apply published official patches for bash-2.05b
      apply_patch bash-2.05b-gnu_fixes-2
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
esac

if [ "${USE_READLINE}" = "Y" ]; then
   extra_conf="--with-installed-readline"
else
   # as was used with 2.05b w/o readline in the way old days
   extra_conf="--with-curses"
fi

max_log_init Bash ${BASH_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr --bindir=/bin \
   --without-bash-malloc ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make tests \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Added symlink for /bin/sh
ln -sf bash /bin/sh

