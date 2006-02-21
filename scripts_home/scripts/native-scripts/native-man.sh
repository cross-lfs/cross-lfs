#!/bin/sh

# cross-lfs native man build
# --------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=man-native.log

set_libdirname
setup_multiarch

unpack_tarball man-${MAN_VER} &&
cd ${PKGDIR}

# apply the man manpath, pager and 80cols patches
# The following replaces the below
#   apply_patch man-${MAN_VER}-manpath &&
#   apply_patch man-${MAN_VER}-pager
#   apply_patch man-${MAN_VER}-80cols
#
# ( Tested with man-1.5k and man-1.5l )

#apply_patch man-${MAN_VER}-grepsilent

case ${MAN_VER} in
1.5[klmn]* )
   # apply the man manpath patch
   test -f src/man.conf.in-ORIG ||
      cp src/man.conf.in src/man.conf.in-ORIG
   sed 's@MANPATH[[:blank:]]/usr/man@#&@' src/man.conf.in-ORIG > src/man.conf.in

   # apply the man pager patch
   test -f configure-ORIG ||
      cp configure configure-ORIG
   sed 's@DEFAULTLESSOPT="-is"@DEFAULTLESSOPT="-isR"@' configure-ORIG \
     > configure

   # apply the man 80 cols patch
   test -f src/man.c-ORIG ||
      cp src/man.c src/man.c-ORIG
   sed 's@.ll %d.%di@.nr LL %d.%di@' src/man.c-ORIG > src/man.c
   
   # apply the man 80 cols patch
   test -f src/gripes.c-ORIG ||
      cp src/gripes.c src/gripes.c-ORIG
   sed 's@is none$@&\\n\\@g' src/gripes.c-ORIG > src/gripes.c
   ;;
1.5p* )
   # apply the man manpath patch
   test -f src/man.conf.in-ORIG ||
      cp src/man.conf.in src/man.conf.in-ORIG
   sed 's@MANPATH[[:blank:]]/usr/man@#&@' src/man.conf.in-ORIG > src/man.conf.in

   # apply the man pager patch
   test -f configure-ORIG ||
      cp configure configure-ORIG
   sed 's@DEFAULTLESSOPT="-is"@DEFAULTLESSOPT="-isR"@' configure-ORIG \
     > configure
   ;;
* )
   echo "###### CHECK MAN SOURCE TO SEE IF IT REQUIRES PATCHING ###"
   ;;
esac

max_log_init Man ${MAN_VER} "Final (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
PATH="${PATH}:/usr/bin:/bin" \
   ./configure -default -confdir=/etc \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

