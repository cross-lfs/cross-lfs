#!/bin/sh

# cross-lfs target sysklogd build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=sysklogd-target.log

set_libdirname
setup_multiarch

unpack_tarball sysklogd-${SYSKLOGD_VER} &&
cd ${PKGDIR}

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX="/usr"
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
else
   INSTALL_PREFIX="${TGT_TOOLS}"
fi

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

apply_patch sysklogd-${SYSKLOGD_VER}-cross

# This package defaults to optimisation level -O3
# Following strips this out, allowing us to set CFLAGS
# with whatever optimisation we want via RPM_OPT_FLAGS
test -f Makefile-ORIG ||
   cp Makefile Makefile-ORIG
sed 's@CFLAGS= $(RPM_OPT_FLAGS) -O3@CFLAGS= $(RPM_OPT_FLAGS)@g' \
   Makefile-ORIG > Makefile

max_log_init Sysklogd ${SYSKLOGD_VER} "Final (shared)" ${BUILDLOGS} ${LOG}
make -k CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
        LDFLAGS="-s" RPM_OPT_FLAGS="-O2 -pipe ${TGT_CFLAGS}" \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
if [ ! -d ${INSTALL_PREFIX}/man/man8 ]; then mkdir -p ${INSTALL_PREFIX}/man/man8 ; fi
if [ ! -d ${LFS}/usr/sbin ]; then mkdir -p ${LFS}/usr/sbin ; fi

echo "Password: " &&
if [ "${USE_SYSROOT}" = "Y" ]; then
   su -c "make BINDIR=${INSTALL_PREFIX}/sbin MANDIR=${INSTALL_PREFIX}/man install &&
          ln -fs ${TGT_TOOLS}/sbin/syslogd ${LFS}/usr/sbin &&
          ln -fs ${TGT_TOOLS}/sbin/klogd ${LFS}/usr/sbin "
      >> ${LOGFILE} 2>&1 &&
   echo " o ALL OK" || barf
else
   su -c "make BINDIR=${INSTALL_PREFIX}/sbin MANDIR=${INSTALL_PREFIX}/man install"
      >> ${LOGFILE} 2>&1 &&
   echo " o ALL OK" || barf
fi

# Create /etc/syslog.conf
# NOTE: Using LFS syslog.conf, copy in real one later
cat > ${LFS}/etc/syslog.conf << "EOF"
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

