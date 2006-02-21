#!/bin/sh

### cracklib ###

cd ${SRC}
LOG=cracklib-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

# Install the wordlist
WORDLIST=cracklib_wordlist
install -d -m755 /usr/share/dict
install -m644 ${CONFIGS}/cracklib/${WORDLIST} /usr/share/dict
ln -sf ${WORDLIST} /usr/share/dict/words
echo `hostname` >> /usr/share/dict/extra.words

unpack_tarball cracklib,${CRACKLIB_VER}
cd ${PKGDIR}
apply_patch cracklib,2.7-blfs-1

if [ ! "${libdirname}" = "lib" ]; then
   sed -i -e "s@/lib@/${libdirname}@g" Makefile
   sed -i -e "s@/lib@/${libdirname}@g" cracklib/Makefile
fi

max_log_init cracklib ${CRACKLIB_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     LD="${LD-ld} ${ARCH_LDFLAGS}" \
     DICTPATH=/${libdirname}/cracklib_dict all \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make CC="${CC-gcc} ${ARCH_CFLAGS}" \
     LD="${LD-ld} ${ARCH_LDFLAGS}" \
     DICTPATH=/${libdirname}/cracklib_dict install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

