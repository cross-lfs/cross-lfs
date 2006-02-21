#!/bin/bash

# cross-lfs native sysklogd build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=sysklogd-native.log

set_libdirname
setup_multiarch

unpack_tarball sysklogd-${SYSKLOGD_VER} &&
cd ${PKGDIR}

# If using 2.5+ kernels, patch (klogd linux/modules.h)
case ${KERNEL_VER} in
   2.[56].* )
      case ${SYSKLOGD_VER} in
        1.4.[1-9]* )
            apply_patch sysklogd-${SYSKLOGD_VER}
         ;;
      esac
   ;;
esac

# This package defaults to optimisation level -O3
# Following strips this out, allowing us to set CFLAGS
# with whatever optimisation we want via RPM_OPT_FLAGS
test -f Makefile-ORIG ||
   cp Makefile Makefile-ORIG
sed 's@CFLAGS= $(RPM_OPT_FLAGS) -O3@CFLAGS= $(RPM_OPT_FLAGS)@g' \
   Makefile-ORIG > Makefile

max_log_init Sysklogd ${SYSKLOGD_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     LDFLAGS="-s" RPM_OPT_FLAGS="-O2 -pipe ${TGT_CFLAGS}" \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make MANDIR=/usr/share/man install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Create /etc/syslog.conf
# NOTE: Using LFS syslog.conf, copy in real one later
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.*		-/var/log/auth.log
*.*;auth,authpriv.none	-/var/log/sys.log
daemon.*		-/var/log/daemon.log
kern.*			-/var/log/kern.log
mail.*			-/var/log/mail.log
user.*			-/var/log/user.log
*.emerg			*

# End /etc/syslog.conf
EOF

