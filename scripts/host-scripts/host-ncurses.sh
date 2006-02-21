#!/bin/bash

### NCURSES ###

cd ${SRC}
LOG=ncurse-buildhost.log

unpack_tarball ncurses-${NCURSES_VER} &&
cd ${PKGDIR}

# replace some deprecated headers
# strstream deprecated in favour of sstream
cd c++
test -f cursesw.h-ORIG ||
   mv cursesw.h cursesw.h-ORIG
sed 's/include <strstream.h>/include <sstream>/g' ./cursesw.h-ORIG > ./cursesw.h

# CHECK THIS... Should only affect ncurses 5.2 and less, 
# must check whether vsscanf is picked up or not in 5.3

test 5.2 = "${NCURSES_VER}" &&
{
   # Apply cursesw.cc vsscanf patch
   # Unsure who provided the original patch used.
   # Please contact the authors so we can attribute you correctly.
   test -f ./cursesw.cc-ORIG ||
      cp cursesw.cc cursesw.cc-ORIG
   grep -v strstreambuf cursesw.cc-ORIG |
   sed 's@ss.vscan(@::vsscanf(buf, @' > cursesw.cc
}
cd ${SRC}/${PKGDIR}

max_log_init Ncurses ${NCURSES_VER} "buildhost (static)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" ./configure --prefix=${HST_TOOLS} \
   --without-debug \
   --without-cxx \
   --without-cxx-binding \
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

chmod 755 ${HST_TOOLS}/lib/*.${NCURSES_VER} &&
ln -s libncurses.a ${HST_TOOLS}/lib/libcurses.a

#ldconfig

# Some braindead apps (util-linux) don't check for term.h under include/ncurses
# Create link
ln -sf ncurses/term.h ${HST_TOOLS}/include
# Also create curses.h symlink
ln -sf ncurses/curses.h ${HST_TOOLS}/include

