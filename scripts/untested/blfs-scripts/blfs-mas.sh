#!/bin/bash

### mas ###

cd ${SRC}
LOG=mas-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball mas-${MAS_VER}
cd ${PKGDIR}

apply_patch mas-cvs-add_amd64

max_log_init mas ${MAS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}

# Adjust config/host.def to install to /usr and to use standard
# installation
cat >> config/host.def <<EOF
#define ProjectRoot /usr
#define UsesSeparateInstallHierarchy NO
EOF

# use previously installed fftw2 libs
sed -i 's@\(HasFFTW\).*@\1 YES@g' config/host.def

imake -I./config \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
World \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# for some reason, mas-config and mas-launch are missing the #! line

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/{masmkmf,mas-config,mas-launch}
fi

cd ${SRC}
# Install libmas codec
unpack_tarball mas-codec_mp1a_mad-${MAS_MAD_CODEC_VER}

cd ${PKGDIR}
mkdir -p build/lib
masmkmf -a
make \
CC="${CC-gcc} ${ARCH_CFLAGS} ${TGT_CFLAGS}" \
make install

