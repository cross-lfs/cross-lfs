#!/bin/bash
#
# python
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-python.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball Python-${PYTHON_VER} &&
cd ${PKGDIR}

case ${PYTHON_VER}} in
   2.4 ) apply_patch Python-2.4-db43-1 ;;
esac
# Still applies to 2.4.1
apply_patch Python-2.4-gdbm-1

#------------------------------------------
# TODO: need to do some edits for lib64 ...
#------------------------------------------
if [ "lib64" = ${libdirname} ]; then
   case ${PYTHON_VER}} in
      2.4 )   apply_patch Python-2.4-lib64-1 ;;
      2.4.* ) apply_patch Python-2.4.1-lib64-1 ;;
   esac
fi

max_log_init python ${PYTHON_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --build="${TARGET}" \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --enable-shared ${extra_conf} \
   --enable-ipv6 \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/{python,python2.4}
   create_stub_hdrs /usr/include/python2.4/pyconfig.h
fi
#!/bin/bash
#
# python
#
# Dependencies: None
#

cd ${SRC}
LOG=blfs-python.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball Python-${PYTHON_VER} &&
cd ${PKGDIR}

case ${PYTHON_VER}} in
   2.4 ) apply_patch Python-2.4-db43-1 ;;
esac
# Still applies to 2.4.1
apply_patch Python-2.4-gdbm-1

#------------------------------------------
# TODO: need to do some edits for lib64 ...
#------------------------------------------
if [ "lib64" = ${libdirname} ]; then
   case ${PYTHON_VER}} in
      2.4 )   apply_patch Python-2.4-lib64-1 ;;
      2.4.* ) apply_patch Python-2.4.1-lib64-1 ;;
   esac
fi

max_log_init python ${PYTHON_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --build="${TARGET}" \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --enable-shared ${extra_conf} \
   --enable-ipv6 \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/{python,python2.4}
   create_stub_hdrs /usr/include/python2.4/pyconfig.h
fi
