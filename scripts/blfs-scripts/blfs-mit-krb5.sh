#!/bin/sh

### MIT_KRB5 ###
# deps
# zlib

cd ${SRC}
LOG=mit-krb5-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# This wont work, we will need to unpack the dist .tar file, then
# unpack the tarball it contains...
# Assuming we have stored the src tarball from the dist tarball under
# ${TARBALLS}

unpack_tarball krb5-${MIT_KRB5_VER} &&
cd ${PKGDIR}/src

# HACK: for x86_64 biarch, 64bit
echo "ac_cv_lib_resolv_res_search=${ac_cv_lib_resolv_res_search=yes}" \
  >> config.cache
extra_conf="${extra_conf} --cache-file=config.cache"

max_log_init MIT-krb5 ${MIT_KRB5_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="gcc ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure \
   --prefix=/usr --sysconfdir=/etc --localstatedir=/var/lib \
   --enable-dns --enable-shared \
   --infodir=/usr/share/info --mandir=/usr/share/man \
   --with-tcl=/usr/${libdirname} ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
#   --with-system-db --with-system-et --with-system-ss \
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

#min_log_init ${TESTLOGS} &&
#make test \
#   >>  ${LOGFILE} 2>&1 &&
#echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# TODO: Revisit these symlinks
test -f /bin/login.shadow ||
   mv /bin/login /bin/login.shadow
ln -sf login.shadow /bin/login

cp /usr/sbin/login.krb5 /bin/login.krb5 &&
mv /usr/bin/ksu /bin 

mv /usr/${libdirname}/libkrb5.so.3* /${libdirname} &&
ln -sf ../../${libdirname}/libkrb5.so.3 /usr/${libdirname} &&
ln -sf libkrb5.so.3 /usr/${libdirname}/libkrb5.so
 
mv /usr/${libdirname}/libkrb4.so.2* /${libdirname} &&
ln -sf ../../${libdirname}/libkrb4.so.2 /usr/${libdirname} &&
ln -sf libkrb4.so.2 /usr/${libdirname}/libkrb4.so
 
mv /usr/${libdirname}/libdes425.so.3* /${libdirname} &&
ln -sf ../../${libdirname}/libdes425.so.3 /usr/${libdirname} &&
ln -sf libdes425.so.3 /usr/${libdirname}/libdes425.so 

mv /usr/${libdirname}/libk5crypto.so.3* /${libdirname} &&
ln -sf ../../${libdirname}/libk5crypto.so.3 /usr/${libdirname} &&
ln -sf libk5crypto.so.3 /usr/${libdirname}/libk5crypto.so

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/krb5-config
   create_stub_hdrs /usr/include/krb5.h /usr/include/gssapi/gssapi.h
fi

