#!/bin/sh

### OPENLDAP ###
# deps
# zlib
# krb5 (optional)
# TODO: for krb5 support some hackery is required

cd ${SRC}
LOG=openldap-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball openldap-${OPENLDAP_VER} &&
cd ${PKGDIR}

max_log_init OpenLDAP ${OPENLDAP_VER} "native (shared)" ${CONFLOGS} ${LOG}
# May not need extra LDFLAGS...
CC="${CC-gcc} ${ARCH_CFLAGS}" LDFLAGS="-lpthread" CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr \
   --libexecdir=/usr/${libdirname}/openldap ${extra_conf} \
   --infodir=/usr/share/info --mandir=/usr/share/man \
   --sysconfdir=/etc \
   --localstatedir=/var/lib/ldap \
   --enable-bdb \
   --enable-wrappers \
   --with-cyrus-sasl \
   --enable-crypt \
   --enable-spasswd \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
#   --disable-debug \

# default is without this
#   --enable-dynamic \

min_log_init ${BUILDLOGS} &&
make depend \
   >> ${LOGFILE} 2>&1 &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
env -i make test \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# create a slapd wrapper script so we can specify the krb5 keytab
file /usr/sbin/slapd | grep -q text || {
   cat > /usr/sbin/slapd <<EOF
#!/bin/sh
# slapd wrapper script
#
# export the location of the krb5 keytab for slapd
env KRB5_KTNAME=/etc/openldap/slapd.keytab /usr/${libdiriname}/openldap/slapd \${@}

EOF
}

chmod 755 /usr/sbin/slapd

