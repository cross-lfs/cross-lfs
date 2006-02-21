#!/bin/sh
#
# Openssh
#
# TODO: work to be done to make opensshConfig.sh behave
cd ${SRC}
LOG=openssh-blfs.log

set_libdirname
setup_multiarch

# We require an sshd user and group
# set to uid 22, gid 22
id sshd > /dev/null 2>&1 ||
{
   echo " o Adding sshd user"
   groupadd -g 22 sshd
   useradd -u 22 -g sshd -c 'sshd privsep' -d /var/empty -s /bin/false sshd
}

if [ ! -d /var/empty ]; then mkdir -p /var/empty; chown root:sys /var/empty; fi

unpack_tarball openssh-${OPENSSH_VER} &&
cd ${PKGDIR}

max_log_init Openssh ${OPENSSH_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CFLAGS="${TGT_CFLAGS}" \
./configure --prefix=/usr --sysconfdir=/etc/ssh \
   --libexecdir=/usr/${libdirname}/openssh \
   --mandir=/usr/share/man --infodir=/usr/share/info \
   --with-md5-passwords \
   --with-kerberos5=/usr \
   --with-tcp-wrappers \
   --without-pam \
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

# create an sshd wrapper script so we can specify the krb5 keytab
# Moce sshd to /usr/${libdirname}/openssh
file /usr/sbin/sshd | grep -q text || {
   mv /usr/sbin/sshd /usr/${libdirname}/openssh

   cat > /usr/sbin/sshd <<EOF
#!/bin/sh
# sshd wrapper script
#
# export the location of the krb5 keytab for sshd
export KRB5_KTNAME=/etc/ssh/sshd.keytab
/usr/${libdirname}/openssh/sshd \${@}

EOF
}

chmod 750 /usr/sbin/sshd

