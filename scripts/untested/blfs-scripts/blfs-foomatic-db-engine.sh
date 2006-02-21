#!/bin/bash

### foomatic ###

cd ${SRC}
LOG=foomatic-db-engine-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

cd ${SRC}

unpack_tarball foomatic-db-engine-${FOOMATIC_DB_ENG_VER}
cd ${PKGDIR}

max_log_init foomatic-db-engine ${FOOMATIC_DB_ENG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS}
make \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS}
make install \
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

if [ ! "${libdirname}" = "lib" ]; then
   # additional symlinks for lib64 cups, ppr to get the foomatic filters
   # TODO: this needs to be done better

   mkdir -p /usr/${libdirname}/cups/filter
   ln -sf /usr/bin/foomatic-rip /usr/${libdirname}/cups/filter
   mkdir -p /usr/${libdirname}/ppr/interfaces
   mkdir -p /usr/${libdirname}/ppr/lib
   ln -sf /usr/bin/foomatic-rip /usr/${libdirname}/ppr/interfaces
   ln -sf /usr/bin/foomatic-rip /usr/${libdirname}/ppr/lib
fi

