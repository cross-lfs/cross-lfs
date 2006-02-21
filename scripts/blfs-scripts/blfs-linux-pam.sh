#!/bin/bash

### Linux-PAM ###
cd ${SRC}

LOG=linux-pam-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
    extra_conf="--libdir=/${libdirname}"
fi

unpack_tarball Linux-PAM-${LINUX_PAM_VER}
cd ${PKGDIR}

apply_patch Linux-PAM-0.77-linkage-3
autoconf

# Fixes
sed -i -e "s@^LD\(\|_L\)=.*@& ${ARCH_LDFLAGS}@g" Make.Rules.in
sed -i -e "s@^\(CC\|CC_STATIC\|LD_D\)=.*@& ${ARCH_CFLAGS} -fPIC@g" Make.Rules.in

max_log_init Linux-PAM ${LINUX_PAM_VER} "native (shared)" ${CONFLOGS} ${LOG}
./configure --enable-static-libpam --with-mailspool=/var/mail \
   --enable-read-both-confs --sysconfdir=/etc ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make CC="gcc ${ARCH_CFLAGS} -fPIC" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

mv /${libdirname}/libpam.a /${libdirname}/libpam_misc.a /${libdirname}/libpamc.a \
   /usr/${libdirname} &&

ln -sf ../../${libdirname}/libpam.so.0.77 /usr/${libdirname}/libpam.so &&
ln -sf libpam.so.0.77 /${libdirname}/libpam.so.0 &&
ln -sf ../../${libdirname}/libpam_misc.so.0.77 /usr/${libdirname}/libpam_misc.so &&
ln -sf libpam_misc.so.0.77 /${libdirname}/libpam_misc.so.0 &&
ln -sf ../../${libdirname}/libpamc.so.0.77 /usr/${libdirname}/libpamc.so
ln -sf libpamc.so.0.77 /${libdirname}/libpamc.so.0

# Create some sample pam files
mkdir /etc/pam.d
cat > /etc/pam.d/other <<EOF
# Begin /etc/pam.d/other

auth            required        pam_unix.so     nullok
account         required        pam_unix.so
session         required        pam_unix.so
password        required        pam_unix.so     nullok

# End /etc/pam.d/other
EOF

cat > /etc/pam.conf <<EOF
# Begin /etc/pam.conf

other           auth            required        pam_unix.so     nullok
other           account         required        pam_unix.so
other           session         required        pam_unix.so
other           password        required        pam_unix.so     nullok

# End /etc/pam.conf
EOF

