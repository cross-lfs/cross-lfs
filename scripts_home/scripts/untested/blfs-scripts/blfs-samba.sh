#!/bin/bash

### samba ###

cd ${SRC}
LOG=samba-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}/samba"
fi

unpack_tarball samba-${SAMBA_VER}

cd ${PKGDIR}/source

max_log_init samba ${SAMBA_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --sysconfdir=/etc \
   --with-configdir=/etc/samba \
   --localstatedir=/var \
   --with-piddir=/var/run \
   --with-fhs \
   --with-smbmount \
   --with-automount \
   --with-python \
   --with-pam \
   --with-expsam=xml,mysql,pgsql \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

# BAH, samba doesn't seem to want to honour --libdir
min_log_init ${BUILDLOGS} &&
make LIBDIR=/usr/${libdirname}/samba \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make LIBDIR=/usr/${libdirname}/samba install \
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
cp ../examples/smb.conf.default /tmp/${PKGDIR}-${BUILDENV}/etc/samba &&
install -m644 ../docs/*.pdf /usr/share/samba &&
if [ -f nsswitch/pam_winbind.so ]; then 
    install -m755 nsswitch/pam_winbind.so /${libdirname}/security
fi
