#!/bin/sh
#
# Freetype2
#
cd ${SRC}
LOG=freetype2-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball freetype-${FREETYPE2_VER} &&

cd ${PKGDIR}

case ${FREETYPE2_VER} in
   2.1.9 )
      apply_patch freetype-2.1.9-bytecode_interpreter-1
   ;;
   * )
      echo "WARNING: freetype-2.1.9-bytecode_interpreter-1 patch not applied"
      echo "         Please check if freetype-${FREETYPE2VER} requires this or not,"
      echo "         if so please update this script and send patches to"
      echo "         either ryan@pha.com.au or ryan@linuxfromscratch.org"
   ;;
esac

# TODO: May need to supply -fno-strict-aliasing for some architectures
#       Investigate

# TODO: should hack freetype-config during bi-arch so we dont hardcoe rpaths
#       in unnecessarily

max_log_init Freetype2 ${FREETYPE2_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
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

# Here is a hack, if we are biarch, move freetype-config 
# to freetype-config-32 or 64 and provide a symlink.
# This symlink will have to be adjusted for packages that use
# freetype-config so they get the right settings.

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/freetype-config
   create_stub_hdrs /usr/include/freetype2/freetype/config/ftconfig.h
fi
