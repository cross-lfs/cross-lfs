#!/bin/bash

### faad2 ###

cd ${SRC}
LOG=faad2-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball faad2-${FAAD2_VER}
cd ${PKGDIR}

case ${FAAD2_VER} in
   2.0 )
      apply_patch faad2-2.0-gentoo_fixes_and_generated
      chmod 755 config.guess config.sub compile configure depcomp \
                install-sh ltmain.sh missing mkinstalldirs
   ;;
esac

# Need LDFLAGS to get around libtool pulling in wrong libstdc++ when
# multilib... should really come up with a better method for generating
# sys_lib_dlsearch_path_spec than just using $CC -print-search-dirs, as
# that does not get processed by the multilib spec...
max_log_init faad2 ${FAAD2_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --with-xmms --with-mp4v2 \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

