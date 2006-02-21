#!/bin/bash

### espgs ###

cd ${SRC}
LOG=espgs-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball espgs-${ESPGS_VER}
cd ${PKGDIR}

# NOTE: check /usr/bin/cups-config(-32,-64} to ensure no rpaths are set 

max_log_init espgs ${ESPGS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --without-gimp-print --without-omni ${extra_conf} \
   --with-ijs \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
make CFLAGS_SO='-fPIC $(ACDEFS)' so \
   >> ${LOGFILE} 2>&1 &&
make soinstall \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

install -d -m755 /usr/include/ps &&
install -m644 src/*.h /usr/include/ps

# Now, install fonts
cd /usr/share/ghostscript
unpack_tarball ghostscript-fonts-std-${GS_FONTS_STD_VER}
unpack_tarball gnu-gs-fonts-other-${GS_FONTS_OTHER_VER}
chown -R root:root *
