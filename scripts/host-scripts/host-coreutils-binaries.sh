#!/bin/bash

### COREUTILS BINARIES ###

# NOTE: Here we are only creating a small subset of the coreutils binaries.

cd ${SRC}
LOG=coreutils-buildhost.log

unpack_tarball coreutils-${COREUTILS_VER}
cd ${PKGDIR}

# If we don't want to conform to POSIX 200212L, override
# NOTE: This is coreutils 5.0 specific, later versions will have
#       a configure/compile time option
case ${COREUTILS_VER} in
   5.1.7 | 5.[2-9]* ) ;;
   * )   mv lib/posixver.c lib/posixver.c-ORIG
         sed '/\/\* The POSIX version that utilities should conform to/i\
#undef _POSIX2_VERSION\
#define _POSIX2_VERSION 199209L\
' lib/posixver.c-ORIG > lib/posixver.c
   ;;
esac

max_log_init Coreutils ${COREUTILS_VER} "buildhost echo (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc}" \
CFLAGS="-O2 -pipe" \
DEFAULT_POSIX2_VERSION=199209 \
./configure --prefix=${HST_TOOLS} \
   --disable-nls \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" -C lib \
   >> ${LOGFILE} 2>&1 || barf

case ${COREUTILS_VER} in
   5.2* )
      # coreutils-5.2.1+ - Create localedir.h
      make ${PMFLAGS} LDFLAGS="-s" -C src localedir.h
         >> ${LOGFILE} 2>&1 || barf
   ;;
esac

# glibc build gets upset by systems with a non BSDish echo program which
# always expands \n regardless if it is contained inside single quotes.
# (solaris)

# NOTE: building echo doesn't solve this issue when echo is issued from
#       make, as make invokes /bin/sh which for some reason doesn't use
#       what you would expect to be the first echo in PATH.
#       This is avoided later by passing SHELL="bash" to affected makes
#       to force use of bash's internal echo

make ${PMFLAGS} LDFLAGS="-s" -C src echo \
   >> ${LOGFILE} 2>&1 &&

# Fix issues with binutils brokenness when it cannot find a working
# bsd compatible install on the system
# (solaris)

make ${PMFLAGS} LDFLAGS="-s" -C src ginstall \
   >> ${LOGFILE} 2>&1 &&


# During kernel headers install, solaris expr causes a syntax error.

make ${PMFLAGS} LDFLAGS="-s" -C src expr \
   >> ${LOGFILE} 2>&1 &&


# ensure we have a cp which takes -a ( -dpR)

make ${PMFLAGS} LDFLAGS="-s" -C src cp \
   >> ${LOGFILE} 2>&1 &&


# ensure we have a ln which properly handles -sf
# (on solaris it errors out if name of link being created already exists)

make ${PMFLAGS} LDFLAGS="-s" -C src ln \
   >> ${LOGFILE} 2>&1 &&

echo " o Build OK" &&

cp -p src/echo ${HST_TOOLS}/bin/echo &&
cp -p src/ginstall ${HST_TOOLS}/bin/install &&
cp -p src/expr ${HST_TOOLS}/bin/expr &&
cp -p src/cp ${HST_TOOLS}/bin/cp &&
cp -p src/ln ${HST_TOOLS}/bin/ln &&
echo " o Install OK" 

