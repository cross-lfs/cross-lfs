#!/bin/bash

### doxygen ###

cd ${SRC}
LOG=doxygen-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball doxygen-${DOXYGEN_VER}.src
cd ${PKGDIR}

# overwrite src/unistd.h with the systems
cp -p /usr/include/unistd.h src/

# Setup platform template for linux-g++-64
if [ ! "${libdirname}" = "lib" ]; then
   mkdir -p ./tmake/lib/linux-g++-${BUILDENV} &&
   cp -Rp ./tmake/lib/linux-g++/* ./tmake/lib/linux-g++-${BUILDENV}
   platform=linux-g++-${BUILDENV}
else
   platform=linux-g++
fi

extra_conf="--platform ${platform}"

sed -i -e "/TMAKE_LIBDIR.*/s@lib@${libdirname}@g" \
       -e '/TMAKE_LIBS_OPENGL/s@Mesa@@g' \
       -e "s@^TMAKE_CC\s.*@& ${ARCH_CFLAGS}@g" \
       -e "s@^TMAKE_CFLAGS\s.*@& ${TGT_CFLAGS}@g" \
       -e "s@^TMAKE_CXX\s.*@& ${ARCH_CFLAGS}@g" \
       -e "s@^TMAKE_LINK\s.*@& ${ARCH_CFLAGS}@g" \
       -e "s@^TMAKE_LINK_SHLIB\s.*@& ${ARCH_CFLAGS}@g" \
      tmake/lib/${platform}/tmake.conf
touch src/scanner.cpp

#for file in src/libdoxycfg.t src/Makefile.libdoxycfg \
#            src/doxytag.t src/libdoxygen.t \
#            addon/doxywizard/doxywizard.t \
#            addon/doxywizard/Makefile.doxywizard; do
#   sed -i '/^LEX.*=/s@flex@flex -l@g' ${file}
#done

max_log_init doxygen ${DOXYGEN_VER} "blfs (shared)" ${CONFLOGS} ${LOG}

CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix /usr \
   --docdir /usr/share/doc \
   --with-doxywizard ${extra_conf} \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS}
make \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}
(
   make install &&
   make doxywizard_install &&
   make docs &&
   make pdf &&
   install -d -m755 /usr/share/doc/doxygen/src &&
   install -m644 src/translator{,_adapter,_en}.h \
      /usr/share/doc/doxygen/src &&
   install -m644 VERSION /usr/share/doc/doxygen &&
   make install_docs 
)  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf
