#!/bin/bash
#
# Tk
#
# Dependencies: tcl X
#

cd ${SRC}
LOG=tk-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball tk${TK_VER}-src &&
cd ${PKGDIR}/unix

if [ ! "${libdirname}" = "lib" ]; then
      # change TK_LIBRARY in Makefile so it is under $(libdir)
      test -f Makefile.in-ORIG ||
         cp -p Makefile.in Makefile.in-ORIG
      sed '/TK_LIBRARY/s@\$(prefix)/lib@$(libdir)@g' \
         Makefile.in-ORIG > Makefile.in
fi

max_log_init Tcl ${TK_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
 ./configure --prefix=/usr --enable-threads ${extra_conf} \
   --with-tcl=/usr/${libdirname} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

#min_log_init ${TESTLOGS} &&
#make test \
#   >>  ${LOGFILE} 2>&1 &&
#echo " o Test OK" &&

# TODO: get version from tk itself
V=`echo ${TK_VER} | cut -d "." -f 1,2`

sed -i "s@${SRC}/${PKGDIR}/unix@/usr/${libdirname}@" tkConfig.sh &&
sed -i "s@${SRC}/${PKGDIR}@/usr/include/tk${V}@" tkConfig.sh &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

install -d /usr/include/tk${V}/unix &&
install -m644 *.h /usr/include/tk${V}/unix/ &&
install -d /usr/include/tk${V}/generic &&
install -c -m644 ../generic/*.h /usr/include/tk${V}/generic/ &&
rm -f /usr/include/tk${V}/generic/{tk,tkDecls,tkPlatDecls}.h &&
ln -nsf ../../include/tk${V} /usr/${libdirname}/tk${V}/include &&
ln -sf libtk${V}.so /usr/${libdirname}/libtk.so &&
ln -sf wish${V} /usr/bin/wish

