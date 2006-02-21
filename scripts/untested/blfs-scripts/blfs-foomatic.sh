#!/bin/bash

### foomatic ###

cd ${SRC}
LOG=foomatic-db-blfs.log

set_libdirname
setup_multiarch

unpack_tarball foomatic-db-${FOOMATIC_DB_VER}
cd ${PKGDIR}

max_log_init foomatic-db ${FOOMATIC_DB_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${INSTLOGS}
make install 
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

cd ${SRC}
LOG=foomatic-db-hpijs-blfs.log

unpack_tarball foomatic-db-hpijs-${FOOMATIC_DB_HPIJS_VER}
cd ${PKGDIR}

max_log_init foomatic-db ${FOOMATIC_DB_HPIJS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${INSTLOGS}
make install 
  >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

cd ${SRC}
LOG=foomatic-filters-blfs.log

unpack_tarball foomatic-filters-${FOOMATIC_FILTERS_VER}
cd ${PKGDIR}

max_log_init foomatic-filters ${FOOMATIC_FILTERS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${INSTLOGS}
make install
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

#### we probably want libxml2 
cd ${SRC}
LOG=foomatic-db-engine-blfs.log

unpack_tarball foomatic-db-engine-${FOOMATIC_DB_ENG_VER}
cd ${PKGDIR}

max_log_init foomatic-db-engine ${FOOMATIC_DB_ENG_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure --prefix=/usr \
  >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${INSTLOGS}
make install
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

