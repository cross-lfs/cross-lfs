#!/bin/bash

### SDL ###

cd ${SRC}
LOG=SDL-blfs.log

USE_DIRECTFB=Y
USE_LIBCACA=Y

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball SDL-${SDL_VER}
cd ${PKGDIR}

apply_patch SDL-1.2.8-gentoo-fixes

if [ "${USE_DIRECTFB}" = "Y" ]; then
   extra_conf="${extra_conf} --enable-video-directfb"
fi

if [ "${USE_LIBCACA}" = "Y" ]; then
   # Patch from libcaca home page
   apply_patch patch-libsdl1.2-libcaca0.7
   ./autogen.sh || barf
   extra_conf="${extra_conf} --enable-video-caca"
fi

# Hack configure to produce correct rpath settings
sed -i "/SDL_RLD_FLAGS=/s@lib@${libdirname}@g" \
   configure

# HACK - 
#echo "====================== H A C K ============================"
#echo "for some reason -lgcc_s doesn't get brought in when linking"
#echo "other packages against libSDL (lgcc_s needed by libstdc++)"
#echo "on amd64... here we hack -lgcc_s to the end of the list of"
#echo "shared libraries in sdl-config.in (but only on amd64)."
#echo "Please check whether things are sane on other arches..."
#echo "====================== H A C K ============================"
#case ${TGT_ARCH} in
#   x86_64 )
#      sed -i '/^@ENABLE_SHARED_TRUE@/s|@SHARED_SYSTEM_LIBS@|& -lgcc_s|' \
#         sdl-config.in
#   ;;
#esac
echo "====================== H A C K ============================"
echo "for some reason -lgcc_s doesn't get brought in when linking"
echo "against libstdc++ on amd64  (lgcc_s needed by libstdc++)."
echo "Here we add -Wl,--as-needed -lgcc_s -Wl,--no-as-needed to"
echo "LDFLAGS so that it is provided when needed..."
echo "Please check whether things are sane on other arches..."
echo "====================== H A C K ============================"

max_log_init SDL ${SDL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname} -Wl,--as-needed -lgcc_s -Wl,--no-as-needed" \
./configure --prefix=/usr ${extra_conf} \
   --disable-debug --enable-video-aalib \
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

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper /usr/bin/sdl-config
fi

