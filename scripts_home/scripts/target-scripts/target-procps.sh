#!/bin/bash

# cross-lfs target procps build
# -----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=procps-final.log

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS="DESTDIR=${TGT_TOOLS}"
fi

unpack_tarball procps-${PROCPS_VER} &&
cd ${PKGDIR}

# Following sed implements the LFS procps patch 
#   apply_patch procps-${PROCPS_VER}
# (20030404: works for procps 3.1.5 - 3.1.8)
# Not required for 3.2.x
#test -f w.c-ORIG ||
#   cp w.c w.c-ORIG
#sed 's@setlocale(LC_ALL, "")@setlocale(LC_NUMERIC, "C")@' w.c-ORIG \
#   > w.c

# Mod Makefile, pass extra LDFLAGS from env
# remove strip from install invocation, change install dirs to lib64 if biarch
# and change hard coded ncurses include search path of /usr/include/ncurses
# to look in ${TGT_TOOLS}/include

test -f Makefile-ORIG ||
   cp Makefile Makefile-ORIG

LDFLAGS="-s" 

# modify install invocation to set --owner and --group to the 
# user running this script.
# ( avoids issues during install if building as a non-root user )
uid=`id -u`
gid=`id -g`

# TODO: need to check how lib64  is handled better in procps
#       This is here based upon x86_64 only...
sed -e "s/LDFLAGS :=.*/& ${LDFLAGS}/" \
    -e 's@--strip @@g' \
    -e "s@^\(lib64.*:= \).*@\1${libdirname}@g" \
    -e "s@/usr/include/ncurses@${BUILD_PREFIX}/include/ncurses@g" \
    -e "/^install/s/--owner 0 --group 0/--owner ${uid} --group ${gid}/g" \
    Makefile-ORIG > Makefile

# same deal with --strip in proc/module.mk
# also remove invocation of ldconfig 
test -f proc/module.mk-ORIG ||
   mv proc/module.mk proc/module.mk-ORIG

sed -e 's@--strip @@g' \
    -e 's@$(ldconfig)@@g' \
    -e "s@strip@${TARGET}-strip@g" \
    proc/module.mk-ORIG > proc/module.mk

# same deal with --strip in ps/module.mk
test -f ps/module.mk-ORIG ||
   mv ps/module.mk ps/module.mk-ORIG

sed -e 's@--strip @@g' \
    ps/module.mk-ORIG > ps/module.mk

max_log_init Procps ${PROCPS_VER} "Final (shared)" ${BUILDLOGS} ${LOG}
make CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
     lib64=${libdirname} \
     CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

# As per LFS CVS
min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} \
     lib64=${libdirname} \
     CC="${TARGET}-gcc ${ARCH_CFLAGS}" install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # if ${LFS}/bin does not exist, create it.
   if [ ! -d ${LFS}/bin ]; then
      mkdir ${LFS}/bin
   fi

   cd ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/kill .
fi
