#!/bin/bash

# cross-lfs native gettext build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=gettext-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball gettext-${GETTEXT_VER} &&
cd ${PKGDIR}

max_log_init Gettext ${GETTEXT_VER} "native (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
   ./configure --prefix=/usr \
   --mandir=/usr/share/man --infodir=/usr/share/info ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# libtool is a pain.
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

min_log_init ${TESTLOGS} &&
make check \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

