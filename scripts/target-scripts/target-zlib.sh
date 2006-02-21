#!/bin/bash

# cross-lfs target zlib build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

LOG=zlib-target.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX=${TGT_TOOLS}
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=${BUILD_PREFIX}/${libdirname}"
fi

export CC="${TARGET}-gcc ${ARCH_CFLAGS}"
export CXX="${TARGET}-g++ ${ARCH_CFLAGS}"

cd ${SRC}
unpack_tarball zlib-${ZLIB_VER}
cd ${PKGDIR}

# TODO: check to see how far back this applies...
apply_patch zlib-1.2.2-add_DESTDIR-1

#TODO - fix this for later zlibs
test "1.1.4" = "${ZLIB_VER}" &&
{
   # Fix up zlibs Makefile so we can properly pass in LDFLAGS from
   # the env without clobbering existing settings for zlib build
   test -f Makefile.in-ORIG ||
      cp Makefile.in Makefile.in-ORIG

   # make LDFLAGS in Makefile.in empty and move existing LDFLAGS
   # to ZLIB_LDFLAGS. Append $(ZLIB_LDFLAGS) wherever $(LDFLAGS) exists
   sed -e 's@LDFLAGS=.*@ZLIB_&@' \
       -e '/ZLIB_LDFLAGS=/i\
LDFLAGS=' \
       -e 's@$(LDFLAGS)@& $(ZLIB_LDFLAGS)@g' \
       Makefile.in-ORIG > Makefile.in
}

max_log_init Zlib ${ZLIB_VER} "target (shared)" ${CONFLOGS} ${LOG}

# Check to see if we are on alpha
# Req's a fix as specified on Kelledins Alpha page
# Pointed out by J.Schmelling
case "${TGT_ARCH}" in
   alpha | x86_64 ) extra_cflags="-fPIC" ;;
esac
# NOTE: It's probably not a bad idea in general to enable -fPIC...

test "1.1.4" = "${ZLIB_VER}" &&
{
   # Apply Kelledin's vsnprintf patch
   # see http://archive.linuxfromscratch.org/lfs-dev/2003/02/..... 
   apply_patch zlib-${ZLIB_VER}-vsnprintf
   CFLAGS="-O2 -pipe ${extra_cflags} ${TGT_CFLAGS}" CPPFLAGS="-DHAS_vsnprintf" \
   ./configure --prefix=${BUILD_PREFIX} --shared ${extra_conf} \
      >> ${LOGFILE} 2>&1 
} || {
   CFLAGS="-O2 -pipe ${extra_cflags} ${TGT_CFLAGS}" \
   ./configure --prefix=${BUILD_PREFIX} \
      --shared ${extra_conf} \
      >> ${LOGFILE} 2>&1 
}
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
#make LDFLAGS="-s" \
make ${PMFLAGS} \
      >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

