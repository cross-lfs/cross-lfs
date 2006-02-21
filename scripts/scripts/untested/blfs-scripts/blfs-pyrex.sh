#!/bin/bash

### pyrex ###

cd ${SRC}
LOG=pyrex-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball Pyrex-${PYREX_VER}
cd ${PKGDIR}

max_log_init Pyrex ${PYREX_VER} "blfs (shared)" ${INSTLOGS} ${LOG}
python setup.py install \
   > ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

