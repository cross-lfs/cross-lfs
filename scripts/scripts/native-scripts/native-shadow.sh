#!/bin/bash

# cross-lfs native shadow build
# -----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG="shadow-native.log"

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball shadow-${SHADOW_VER} &&
cd ${PKGDIR}

# HACK
# Issue noted with glibc-2.3-20040701 and linux-libc-headers-2.6.7
test -f libmisc/xmalloc.c-ORIG ||
   cp -p libmisc/xmalloc.c libmisc/xmalloc.c-ORIG

sed 's@^extern char \*malloc ();@/* & */@g' \
   libmisc/xmalloc.c-ORIG > libmisc/xmalloc.c

# fix lastlog for shadow-4.0.7
case ${SHADOW_VER} in
   4.0.7 )
      apply_patch shadow-4.0.7-fix_lastlog-1
   ;;
esac

# Set to Y if you want a shared libmisc and libshadow and have
# passwd etc linked dynamically to these
BUILD_SHADOW_SHARED="Y"

# If not there touch /usr/bin/passwd
test -f /usr/bin/passwd || touch /usr/bin/passwd

test Y = "${BUILD_SHADOW_SHARED}" &&
   extra_conf="${extra_conf} --enable-shared"

max_log_init Shadow ${SHADOW_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr ${extra_conf} \
   --mandir=/usr/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

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
   test -f /etc/${file} ||
   {
      cp -v etc/${file} /etc
      chmod -c 644 /etc/limits
   }
done

# LFS:  User mailboxes belong in /var/mail not /var/spool/mail
# From Nico's: use MD5
sed -e 's%/var/spool/mail%/var/mail%' \
    -e 's%^#MD5_CRYPT_ENAB.*no%MD5_CRYPT_ENAB yes%' \
    etc/login.defs.linux > /etc/login.defs 

ln -sf vipw /usr/sbin/vigr
# Nico: create symlink for vigr man page
ln -sf vipw.8 /usr/share/man/man8/vigr.8
rm -f /bin/vipw
mv -f /bin/sg /usr/bin 

# Only need to move these if we built shared
# TODO: 4.0.6 seems we only need to move libshadow...
#       4.0.7, the below shouldn't be required
#       Must revisit this script... though what we do here doesn't hurt...
test Y = "${BUILD_SHADOW_SHARED}" &&
{
   mv -f /usr/${libdirname}/lib{shadow,misc}.so.0* /${libdirname} 
   ln -sf ../../${libdirname}/libshadow.so.0 /usr/${libdirname}/libshadow.so 
   ln -sf ../../${libdirname}/libmisc.so.0 /usr/${libdirname}/libmisc.so 
   ldconfig
}

# Create shadow password file if not already built
test -f /etc/shadow ||
   /usr/sbin/pwconv 

