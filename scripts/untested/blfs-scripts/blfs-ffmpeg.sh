#!/bin/bash

### ffmpeg ###

cd ${SRC}
LOG=ffmpeg-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball FFMpeg-${FFMPEG_VER}
cd ${PKGDIR}

# Set this if you want to build a shared postproc library
use_shared_pp="Y"

#-------------------------------------------------------------------------------
# Configure doesn't actually check if anything exists, we do it
# manually here...

# Do we have faad2? If so, do we also have faac?
if [ -f /usr/include/faad.h -a -f /usr/${libdirname}/libfaad.a ]; then
   extra_conf="${extra_conf} --enable-faad"
   echo " - enabling faad2 support"
   if [ -f /usr/bin/faad ]; then
      extra_conf="${extra_conf} --enable-faadbin"
      echo " - enabling faad2bin support"
   fi
   if [ -f /usr/include/faac.h -a -f /usr/${libdirname}/libfaac.a ]; then
      extra_conf="${extra_conf} --enable-faac"
      echo " - enabling faac support"
   fi
fi

# Do we have xvid?
if [ -f /usr/include/xvid.h -a -f /usr/${libdirname}/libxvidcore.a ]; then
   extra_conf="${extra_conf} --enable-xvid"
   echo " - enabling xvid support"
fi

# Do we have lame?
if [ -f /usr/include/lame/lame.h -a -f /usr/${libdirname}/libmp3lame.a ]; then
   extra_conf="${extra_conf} --enable-mp3lame"
   echo " - enabling mp3lame support"
fi

# Do we have ogg? If so, check if we have vorbis and theora
if [ -f /usr/include/ogg/ogg.h -a -f /usr/${libdirname}/libogg.a ]; then
   extra_conf="${extra_conf} --enable-libogg"
   echo " - enabling libogg support"

   # Do we have vorbis?
   if [ -f /usr/include/vorbis/codec.h -a -f /usr/${libdirname}/libvorbis.a ]
   then
      extra_conf="${extra_conf} --enable-vorbis"
      echo " - enabling vorbis support"
   fi
   # Do we have theora?
   if [ -f /usr/include/theora/theora.h -a -f /usr/${libdirname}/libtheora.a ]
   then
      extra_conf="${extra_conf} --enable-theora"
      echo " - enabling theora support"
   fi
fi

# Do we have libgsm?
if [ -f /usr/include/gsm.h -a -f /usr/${libdirname}/libgsm.a ]; then
   extra_conf="${extra_conf} --enable-libgsm"
   echo " - enabling libgsm support"
fi
#-------------------------------------------------------------------------------

# Fix configure to generate pkgconfig files which set libdir properly
sed -i -e 's@^\(libdir=\)\\\${exec_prefix}/lib@\1${libdir}@g' \
   configure

# Fix issues with liba52
sed -i -e "s/static uint64/const uint64/" \
    libavcodec/liba52/resample_mmx.c

# Stop the vhook build bitching and moaning because it cant find the created
# libavcodec, libavformat and (if shared pp lib built) libpostproc
vhook_add_libs="-L../libavcodec -lavcodec -L../libavformat -lavformat"

if [ "${use_shared_pp}" = "Y" ]; then
   extra_conf="${extra_conf} --enable-shared-pp"
   vhook_add_libs="${vhook_add_libs} -L../libavcodec/libpostproc -lpostproc"
fi

sed -i -e "s@\$<@\$< ${vhook_add_libs}@g" \
   vhook/Makefile

# Hoorah, configure checks for -m32 in CFLAGS and configures amd64 build as
# a standard X86 build :-) So we define ARCH_CFLAGS in CFLAGS as well as
# with CC (still need it there for shared lib creation)
max_log_init ffmpeg ${FFMPEG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CFLAGS="${ARCH_CFLAGS} -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
 --cc="${CC-gcc} ${ARCH_CFLAGS}" \
 --mandir=/usr/share/man \
 --enable-gpl \
 --enable-a52 \
 --enable-pp \
 --enable-shared \
 --enable-pthreads \
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

