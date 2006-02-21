#!/bin/bash

### samba ###

cd ${SRC}
LOG=samba-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball samba-${MYSQL_VER}

# TODO, set --with-libdir here only when biarch...
#       remove from configure below
cd ${PKGDIR}/source

max_log_init samba ${MYSQL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --with-libdir=/usr/${libdirname}/samba \
   --sysconfdir=/etc \
   --with-configdir=/etc/samba \
   --localstatedir=/var \
   --with-piddir=/var/run \
   --with-fhs \
   --with-smbmount \
   --with-automount \
   --with-python=python${suffix} \
   --with-pam \
   --with-expsam=xml,mysql \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

mv /usr/${libdirname}/samba/libsmbclient.so /usr/${libdirname} &&
ln -sf ../libsmbclient.so /usr/${libdirname}/samba &&
#chmod 644 /usr/include/libsmbclient.h \
#          /usr/${libdir}/samba/libsmbclient.a &&
chmod 644 /usr/include/libsmbclient.h &&
install -m755 nsswitch/libnss_win{s,bind}.so /${libdirname} &&
ln -sf libnss_winbind.so /${libdirname}/libnss_winbind.so.2 &&
ln -sf libnss_wins.so /${libdirname}/libnss_wins.so.2 &&
cp ../examples/smb.conf.default /etc/samba &&
install -m644 ../docs/*.pdf /usr/share/samba &&
if [ -f nsswitch/pam_winbind.so ]; then 
    install -m755 nsswitch/pam_winbind.so /${libdirname}/security
fi
