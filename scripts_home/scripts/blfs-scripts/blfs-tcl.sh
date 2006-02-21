#!/bin/sh
#
# Tcl ( Reqd for expect )
#
# TODO: work to be done to make tclConfig.sh behave
cd ${SRC}
LOG=tcl-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball tcl${TCL_VER}-src &&
cd ${PKGDIR}/unix

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
   # change TCL_LIBRARY in Makefile so it is under $(libdir)
   if [ ! -f Makefile.in-ORIG ]; then cp -p Makefile.in Makefile.in-ORIG ; fi
   sed '/TCL_LIBRARY/s@\$(prefix)/lib@$(libdir)@g' Makefile.in-ORIG > Makefile.in
fi

max_log_init Tcl ${TCL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
 ./configure --prefix=/usr --enable-threads ${extra_conf} \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make test \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&
# clock test may fail... not a real concern for our purposes...

# TODO: get version from tcl itself
V=`echo ${TCL_VER} | cut -d "." -f 1,2`

sed -i "s@${SRC}/${PKGDIR}/unix@/usr/${libdirname}@" tclConfig.sh &&
sed -i "s@${SRC}/${PKGDIR}@/usr/include/tcl${V}@" tclConfig.sh &&
sed -i "s@^TCL_LIB_FILE='libtcl${V}..TCL_DBGX..so'@TCL_LIB_FILE=\"libtcl${V}\$\{TCL_DBGX\}.so\"@" \
    tclConfig.sh

# The following isn't required for tcl 8.4.9 ...
# TODO: check which versions (apart from 8.4.6) this is needed for
case ${TCL_VER} in
   8.4.6 )
      mv ../doc/{,Tcl_}Thread.3 &&
      sed -i 's/ Thread.3/ Tcl_Thread.3/' mkLinks
   ;;
esac

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

install -d /usr/include/tcl${V}/unix &&
install -m644 *.h /usr/include/tcl${V}/unix/ &&
install -d /usr/include/tcl${V}/generic &&
install -c -m644 ../generic/*.h /usr/include/tcl${V}/generic/ &&
rm -f /usr/include/tcl${V}/generic/{tcl,tclDecls,tclPlatDecls}.h &&
ln -nsf ../../include/tcl${V} /usr/${libdirname}/tcl${V}/include &&
ln -sf libtcl${V}.so /usr/${libdirname}/libtcl.so

# Create symlink for tclsh
TCLSH=$(basename $(find /usr/bin -type f -name tclsh\*))
test "tclsh" != "${TCLSH}" &&
   ln -sf ./${TCLSH} /usr/bin/tclsh

