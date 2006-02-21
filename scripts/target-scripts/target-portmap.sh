#!/bin/sh

# cross-lfs target portmap build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=portmap-target.log

set_libdirname
setup_multiarch

# TODO: should probably just install into
#       ${LFS} and be done with it
if [ "${USE_SYSROOT}" = "Y" ]; then
   BASEDIR=${LFS}
else
   BASEDIR=${TGT_TOOLS}
fi

unpack_tarball portmap_${PORTMAP_VER}
cd ${PKGDIR}
apply_patch portmap-5beta-compilation_fixes-3 
apply_patch portmap-5beta-glibc_errno_fix-1

# Do not strip during install
chmod 644 Makefile
if [ ! -f Makefile-ORIG ]; then cp Makefile Makefile-ORIG ; fi
sed '/install.*-s /s@-s @@g' Makefile-ORIG > Makefile

max_log_init portmap ${PORTMAP_VER} "target (shared)" ${BUILDLOGS} ${LOG}
make CC="${TARGET}-gcc ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
su -c "make BASEDIR=${BASEDIR} install" \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

