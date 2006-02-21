#!/bin/sh
#
# NSS LDAP
#
cd ${SRC}
LOG=nssldap-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/${libdirname}"
fi

# hmmm, tarball has no version...
unpack_tarball nss_ldap &&
cd ${PKGDIR}

max_log_init nss_ldap ${NSSLDAP_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
 ./configure --enable-threads ${extra_conf} \
   --enable-rfc2307bis \
   --enable-schema-mapping \
   --enable-paged-results \
   --enable-configurable-krb5ccname-gssapi \
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

