#!/bin/bash

# cross-lfs target ncurses build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=ncurses-target.log
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
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

export CC="${TARGET}-gcc ${ARCH_CFLAGS}"
export CXX="${TARGET}-g++ ${ARCH_CFLAGS}"
export RANLIB="${TARGET}-ranlib"
export AR="${TARGET}-ar"
export LD="${TARGET}-ld"

unpack_tarball ncurses-${NCURSES_VER} &&
cd ${PKGDIR}

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"

   # Patch misc/run_tic.in to create 
   # ${libdirname}/terminfo -> share/terminfo link
   test -f misc/run_tic.in-ORIG ||
      mv misc/run_tic.in misc/run_tic.in-ORIG

   sed "s:^\(TICDIR.*/\)lib\(.*\):\1${libdirname}\2:g" \
      misc/run_tic.in-ORIG > misc/run_tic.in
fi

# replace some deprecated headers
# strstream deprecated in favour of sstream
test -f c++/cursesw.h-ORIG ||
   mv c++/cursesw.h c++/cursesw.h-ORIG
sed 's/include <strstream.h>/include <sstream>/g' c++/cursesw.h-ORIG > c++/cursesw.h

# CHECK THIS... Should only affect ncurses 5.2 and less, 
# must check whether vsscanf is picked up or not in 5.3

test 5.2 = "${NCURSES_VER}" &&
{
   # Apply cursesw.cc vsscanf patch
   # Unsure who provided the original patch used.
   # Please contact the authors so we can attribute you correctly.
   test -f c++/cursesw.cc-ORIG ||
      cp c++/cursesw.cc c++/cursesw.cc-ORIG
   grep -v strstreambuf c++/cursesw.cc-ORIG |
   sed 's@ss.vscan(@::vsscanf(buf, @' > c++/cursesw.cc
}

# Force xterm to always be colour
# ( thanks Alexander Patrakov ;-) )
# TODO: this is the default w ncurses-20040711
sed -i -e '/^xterm|/,+1s,^\(.use\)=xterm-r6,\1=xterm-xfree86,' \
   misc/terminfo.src

max_log_init Ncurses ${NCURSES_VER} "target (shared)" ${CONFLOGS} ${LOG}
./configure --prefix=${BUILD_PREFIX} --with-shared \
   --host=${TARGET} --with-build-cc=gcc \
   --without-debug ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

chmod 755 ${INSTALL_PREFIX}/${libdirname}/*.${NCURSES_VER} &&
ln -s libncurses.a ${INSTALL_PREFIX}/${libdirname}/libcurses.a
ln -sf libncurses.so.5 ${INSTALL_PREFIX}/${libdirname}/libcurses.so

#ldconfig

if [ ! -f ${INSTALL_PREFIX}/include/term.h -a -f ${INSTALL_PREFIX}/include/ncurses/term.h ]; then
   ln -sf ncurses/term.h ${INSTALL_PREFIX}/include
fi

# also create a curses.h symlink
if [ ! -f ${INSTALL_PREFIX}/include/curses.h -a -f ${INSTALL_PREFIX}/include/ncurses/curses.h ]; then
   ln -sf ncurses/curses.h ${INSTALL_PREFIX}/include
fi

