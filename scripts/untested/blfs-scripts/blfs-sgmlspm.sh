#!/bin/sh

### sgmlspm ###

cd ${SRC}
LOG=sgmlspm-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball SGMLSpm-${SGMLSPM_VER}
cd ${PKGDIR}

max_log_init sgmlspm ${SGMLSPM_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
sed -i -e "s@/usr/local/bin@/usr/bin@" \
       -e "s@/usr/local/lib/perl5@/usr/${libdirname}/perl5/site_perl/${PERL_VER}@" \
       -e "s@/usr/local/lib/www/docs@/usr/share/doc/perl5@" \
   Makefile \
   >> ${LOGFILE} 2>&1 &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

install -d -m 755 /usr/share/doc/perl5 &&
make install_html &&
rm -f /usr/share/doc/perl5/SGMLSpm/sample.pl &&
install -m 644 DOC/sample.pl /usr/share/doc/perl5/SGMLSpm

