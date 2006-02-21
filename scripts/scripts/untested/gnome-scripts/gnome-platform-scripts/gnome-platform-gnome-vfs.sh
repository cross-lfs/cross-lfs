#!/bin/bash

### gnome-vfs ###

cd ${SRC}
LOG=gnome-vfs-gnome-platform.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${GNOME_PREFIX}/${libdirname}"
fi

if [ "${GNOME_PREFIX}" = "/usr" ]; then 
   extra_conf="${extra_conf} --sysconfdir=/etc/gnome"
fi

# override TARBALLS to point at gnome/platform tree
GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`
export TARBALLS=${GNOME_TARBALLS}/platform/${GNOME_REL_MAJ}/${GNOME_REL}/sources

# override PATCHES 
export PATCHES=`dirname ${0}`/../../gnome-patches

unpack_tarball gnome-vfs-${GNOME_VFS_VER}
cd ${PKGDIR}
case ${GNOME_VFS_VER} in
   2.10.1 )
      case ${HAL_VER} in
         0.5.* )
            apply_patch gnome-vfs-2.10.1-hal_0.5.0-1
         ;;
      esac
   ;;
esac

max_log_init gnome-vfs ${GNOME_VFS_VER} "gnome-platform (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=${GNOME_PREFIX} ${extra_conf} \
   --libexecdir=${GNOME_PREFIX}/${libdirname}/gnome-vfs \
   --sysconfdir=/etc/gnome \
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

# Have to update with later releases of gnome-vfs
if [ "${MULTIARCH}" = "Y" ]; then
   create_stub_hdrs ${GNOME_PREFIX}/include/gnome-vfs-2.0/libgnomevfs/gnome-vfs-file-size.h
fi

