#!/bin/bash
#
# Berkeley DB
# (script needs to be checked)
#
cd ${SRC}
LOG=bdb-blfs.log

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball db-${BDB_VER} &&

# Patching goes here
cd ${PKGDIR}

case ${BDB_VER} in
   4.2.52 )
      #apply_patch patch.4.2.52.1 -Np0
      #apply_patch patch.4.2.52.2 -Np0
      patch -Np0 -i ${PATCHES}/patch.4.2.52.1
      patch -Np0 -i ${PATCHES}/patch.4.2.52.2 -Np0

      # Issue with older libtool stuff determining if ld used is GNU ld
      # Breaks when linking with g++ as non-gnu ld case for linking does not 
      # pass -nostdlib .
      # see 'Re: libtool update - the "duplicate _init and _fini" problem' 
      # http://lists.gnu.org/archive/html/libtool-patches/2003-06/msg00056.html
      apply_patch db-4.2.52-libtool_fixes
   ;;
   4.3.27 )
      patch -Np0 -i ${PATCHES}/patch.4.3.27.1
      patch -Np0 -i ${PATCHES}/patch.4.3.27.2
      patch -Np0 -i ${PATCHES}/patch.4.3.27.3
   ;;
esac

cd ${SRC}/${PKGDIR}/build_unix

max_log_init BDB ${BDB_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
../dist/configure --prefix=/usr ${extra_conf} \
   --enable-compat185 --enable-cxx \
   --with-tcl=/usr/${libdirname} --enable-tcl \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LIBSO_LIBS="-lpthread" LIBXSO_LIBS="-lpthread" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make docdir=/usr/share/doc/${PKGDIR} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

