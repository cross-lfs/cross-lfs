#!/bin/bash

### polypaudio ###

cd ${SRC}
LOG=polypaudio-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball polypaudio-${POLYPAUDIO_VER}
cd ${PKGDIR}

# Fix the generated polypaudio pkgconfig files to look at the right libdir
files=`ls *.pc.in`
for file in ${files}; do
   sed -i -e "/^libdir=/s@\(.*\)lib.*@\1${libdirname}@g" $file
done

# Fix the symlinking of pacat to parec during install when pacat already exists
sed -i -e 's@ln -s pacat@ln -sf pacat@g' polyp/Makefile.in

# Use LDFLAGS to appease libtool
max_log_init polypaudio ${POLYPAUDIO_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --sysconfdir=/etc ${extra_conf} \
   --mandir=/usr/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# polypaudio generates a conf file which points to its modules under
# /usr/${libdirname} . Here we will keep 2 copies and generate a symlink
if [ "${MULTIARCH}" = "Y" ]; then
   mv /etc/polypaudio/daemon.conf /etc/polypaudio/daemon.conf-${BUILDENV}
   ln -sf daemon.conf-${BUILDENV} /etc/polypaudio/daemon.conf
fi
