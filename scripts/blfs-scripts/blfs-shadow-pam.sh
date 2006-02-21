#!/bin/sh

### SHADOW ###
cd ${SRC}
LOG="shadow-pam-native.log"

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball shadow-${SHADOW_VER} &&
cd ${PKGDIR}

apply_patch shadow-${SHADOW_VER}-pam-1
# HACK
# Issue noted with glibc-2.3-20040701 and linux-libc-headers-2.6.7
test -f libmisc/xmalloc.c-ORIG ||
   cp -p libmisc/xmalloc.c libmisc/xmalloc.c-ORIG

sed 's@^extern char \*malloc ();@/* & */@g' \
   libmisc/xmalloc.c-ORIG > libmisc/xmalloc.c

# Set to Y if you want a shared libmisc and libshadow and have
# passwd etc linked dynamically to these
BUILD_SHADOW_SHARED="Y"
if [ "Y" = "${BUILD_SHADOW_SHARED}" ]; then 
   extra_conf="${extra_conf} --enable-shared"
fi

# If not there touch /usr/bin/passwd
if [ ! -f /usr/bin/passwd ]; then touch /usr/bin/passwd ; fi

max_log_init Shadow ${SHADOW_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LIBS="-lpam -lpam_misc" \
./configure --prefix=/usr ${extra_conf} \
   --with-libpam --without-libcrack \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

echo '#define HAVE_SETLOCALE 1' >> config.h

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make check \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

shadowfiles="limits login.access"
for file in ${shadowfiles} ; do
   if [ ! -f /etc/${file} ]; then
      cp -v etc/${file} /etc
      chmod -c 644 /etc/limits
   fi
done

# LFS:  User mailboxes belong in /var/mail not /var/spool/mail
# From Nico's: use MD5
sed -e 's%/var/spool/mail%/var/mail%' \
    -e 's%^#MD5_CRYPT_ENAB.*no%MD5_CRYPT_ENAB yes%' \
    etc/login.defs.linux > /etc/login.defs 

#ln -sf vipw /usr/sbin/vigr
# Nico: create symlink for vigr man page
#ln -sf vipw.8 /usr/share/man/man8/vigr.8

# Broken symlinks
mv -f /bin/vigr /usr/sbin
mv -f /bin/sg /usr/bin 
# Wrong location
mv -f /usr/bin/passwd /bin

# Only need to move these if we built shared
if [ "Y" = "${BUILD_SHADOW_SHARED}" ]; then
   mv -f /usr/${libdiriname}/lib{shadow,misc}.so.0* /${libdirname} 
   ln -sf ../../${libdirname}/libshadow.so.0 /usr/${libdirname}/libshadow.so 
   ln -sf ../../${libdirname}/libmisc.so.0 /usr/${libdirname}/libmisc.so 
   ldconfig
fi

# Create shadow password file if not already built
if [ ! -f /etc/shadow ]; then /usr/sbin/pwconv ; fi

if [ ! -d /etc/pam.d ]; then mkdir /etc/pam.d ; fi
# Will blow the existing files away...
cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

auth        requisite      pam_securetty.so
auth        requisite      pam_nologin.so
auth        required       pam_env.so
auth        required       pam_unix.so
account     required       pam_access.so
account     required       pam_unix.so
session     required       pam_motd.so
session     required       pam_limits.so
session     optional       pam_mail.so     dir=/var/mail standard
session     optional       pam_lastlog.so
session     required       pam_unix.so

# End /etc/pam.d/login
EOF

cat > /etc/pam.d/passwd-nocracklib << "EOF"
# Begin /etc/pam.d/passwd

password    required       pam_unix.so     md5 shadow 

# End /etc/pam.d/passwd
EOF

cat > /etc/pam.d/shadow << "EOF"
# Begin /etc/pam.d/shadow

auth        sufficient      pam_rootok.so
auth        required        pam_unix.so
account     required        pam_unix.so
session     required        pam_unix.so
password    required        pam_permit.so

# End /etc/pam.d/shadow
EOF

cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

auth        sufficient      pam_rootok.so
auth        required        pam_unix.so
account     required        pam_unix.so
session     required        pam_unix.so

# End /etc/pam.d/su
EOF
cat > /etc/pam.d/useradd << "EOF"
# Begin /etc/pam.d/useradd

auth        sufficient      pam_rootok.so
auth        required        pam_unix.so
account     required        pam_unix.so
session     required        pam_unix.so
password    required        pam_permit.so

# End /etc/pam.d/useradd
EOF
cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

auth        sufficient      pam_rootok.so
auth        required        pam_unix.so
account     required        pam_unix.so
session     required        pam_unix.so
password    required        pam_permit.so

# End /etc/pam.d/chage
EOF

cat > /etc/pam.d/passwd << "EOF" 
# Begin /etc/pam.d/passwd

password    required    pam_cracklib.so     \
    retry=3  difok=8  minlen=5  dcredit=3  ocredit=3  ucredit=2  lcredit=2
password    required    pam_unix.so     md5 shadow use_authtok

# End /etc/pam.d/passwd
EOF

cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_deny.so
auth        required        pam_warn.so
account     required        pam_deny.so
session     required        pam_deny.so
password    required        pam_deny.so
password    required        pam_warn.so

# End /etc/pam.d/other
EOF

# MORE TO DO FOR login.defs edits...
