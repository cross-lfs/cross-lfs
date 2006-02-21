#!/bin/bash

# cross-lfs native ncurses build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=ncurses-native.log
libdir="lib"

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball ncurses-${NCURSES_VER} &&
cd ${PKGDIR}

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"

   # Patch misc/run_tic.in to create lib64/terminfo -> share/terminfo link
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

max_log_init Ncurses ${NCURSES_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
./configure --prefix=/usr --with-shared \
   --without-debug ${extra_conf} \
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

chmod 755 /usr/${libdirname}/*.${NCURSES_VER} &&
chmod 644 /usr/${libdirname}/libncurses++.a &&
mv /usr/${libdirname}/libncurses.so.* /${libdirname}
ln -s libncurses.a /usr/${libdirname}/libcurses.a
ln -sf ../../${libdirname}/libncurses.so.5 /usr/${libdirname}/libncurses.so
ln -sf ../../${libdirname}/libncurses.so.5 /usr/${libdirname}/libcurses.so

#ldconfig

if [ ! -f /usr/include/term.h -a -f /usr/include/ncurses/term.h ]; then
   ln -sf ncurses/term.h /usr/include
fi

# also create a curses.h symlink
if [ ! -f /usr/include/curses.h -a -f /usr/include/ncurses/curses.h ]; then
   ln -sf ncurses/curses.h /usr/include
fi

/sbin/ldconfig
