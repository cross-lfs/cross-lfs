#!/bin/sh
#
# Cyrus-SASL
#
cd ${SRC}
LOG=cyrus-sasl-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball cyrus-sasl-${CYRUS_SASL_VER} &&
cd ${PKGDIR}

# Apply patch to adjust the install location of the plugins so that
# it installs under ${libdir}/sasl2, instead of the default /usr/lib/sasl2
# This is so bi-arch builds stay neat
apply_patch  cyrus-sasl-2.1.20-set_plugindir_from_libdir

# Fix brokenness with gcc4
apply_patch cyrus-sasl-2.1.20-gcc4_fixes

max_log_init Cyrus-SASL ${CYRUS_SASL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
#CC="${CC-gcc} ${ARCH_CFLAGS}" \
#./configure --prefix=/usr --sysconfdir=/etc ${extra_conf} \
#   --with-dbpath=/var/lib/sasl/sasldb2 --with-saslauthd=/var/run \
#   >> ${LOGFILE} 2>&1 &&
#echo " o Configure OK" &&
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --sysconfdir=/etc --libdir=/usr/${libdirname} \
   --with-dbpath=/var/lib/sasl2/sasldb2 --with-saslauthd=/var/lib/sasl2 \
   --with-dblib=berkeley --with-openssl \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --enable-login \
   --enable-plain \
   --enable-ntlm \
   --enable-gssapi \
   --disable-krb4 \
   --disable-otp \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
#   --with-plugindir=/usr/lib/sasl2 \

# Doesn't like to be built parallel
min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

install -m644 -oroot -groot saslauthd/saslauthd.mdoc \
    /usr/share/man/man8/saslauthd.8 &&
install -d -m755 /usr/share/doc/sasl &&
install -m644 -oroot -groot doc/{*.{html,txt,fig},ONEWS,TODO} \
    /usr/share/doc/sasl &&
install -m644 -oroot -groot saslauthd/LDAP_SASLAUTHD \
    /usr/share/doc/sasl &&
install -d -m755 /var/lib/sasl2

