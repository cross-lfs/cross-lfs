#!/bin/bash

# cross-lfs target gettext build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gettext-target.log
libdirname="lib"

SELF=`basename ${0}`
set_buildenv
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
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"
fi

unpack_tarball gettext-${GETTEXT_VER} &&
cd ${PKGDIR}

# Curse of getline again...
echo "am_cv_func_working_getline=yes" > config.cache

max_log_init Gettext ${GETTEXT_VER} "target (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${ARCH_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${ARCH_CFLAGS}" \
   ./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} ${extra_conf} \
   --cache-file=config.cache \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# libtools is a pain.
# with libasprintf it tries to link in the startfiles even though
# g++ will look after this itself. This is a hack, should really edit
# ltmain.sh...
test -f gettext-runtime/libasprintf/libtool-ORIG ||
   mv gettext-runtime/libasprintf/libtool gettext-runtime/libasprintf/libtool-ORIG
sed 's@^\(archive_cmds.*-shared \)\(.*predep_objects.*\)@\1 -nostartfiles -nostdlib \2@g' \
gettext-runtime/libasprintf/libtool-ORIG > gettext-runtime/libasprintf/libtool

min_log_init ${BUILDLOGS} &&
#make ${PMFLAGS} LDFLAGS="-s" \
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

