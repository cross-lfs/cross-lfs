#!/bin/bash

# cross-lfs native zlib build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

LOG=zlib-native.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

cd ${SRC}
unpack_tarball zlib-${ZLIB_VER}
cd ${PKGDIR}

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
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CXX="${CXX-g++} ${ARCH_CFLAGS}" \
   CFLAGS="-O2 -pipe ${extra_cflags} ${TGT_CFLAGS}" \
   CPPFLAGS="-DHAS_vsnprintf" \
   ./configure --prefix=/usr --shared ${extra_conf} \
      >> ${LOGFILE} 2>&1 
} || {
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CXX="${CXX-g++} ${ARCH_CFLAGS}" \
   CFLAGS="-O2 -pipe ${extra_cflags} ${TGT_CFLAGS}" \
   ./configure --prefix=/usr \
      --shared ${extra_conf} \
      >> ${LOGFILE} 2>&1 
}
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make test \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || errmsg

min_log_init ${INSTLOGS} &&
make LIBS="libz.so.${ZLIB_VER} libz.a" install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

mv /usr/${libdirname}/libz.so.* /${libdirname}
ln -sf ../../${libdirname}/libz.so.1 /usr/${libdirname}/libz.so
cp -f zlib.3 /usr/share/man/man3

ldconfig
