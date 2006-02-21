#!/bin/bash

# cross-lfs native coreutils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

#export COREUTILS_VER=5.2.1

cd ${SRC}
LOG=coreutils-native.log

set_libdirname
setup_multiarch

unpack_tarball coreutils-${COREUTILS_VER}
cd ${PKGDIR}

# If we don't want to conform to POSIX 200212L, override
# NOTE: This is coreutils 5.0 specific, later versions will have
#       a configure/compile time option
case ${COREUTILS_VER} in
   5.1.7 | 5.[2-9]* ) ;;
   * )   mv lib/posixver.c lib/posixver.c-ORIG
         sed '/\/\* The POSIX version that utilities should conform to/i\
#undef _POSIX2_VERSION\
#define _POSIX2_VERSION 199209L\
   ' lib/posixver.c-ORIG > lib/posixver.c
   ;;
esac

max_log_init Coreutils ${COREUTILS_VER} "native (shared)" ${CONFLOGS} ${LOG}
#env CFLAGS="-O2 -pipe ${TGT_CFLAGS}" ${extra_env} \
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" DEFAULT_POSIX2_VERSION=199209 \
./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
echo -e "\n Root Tests \n------------" >> ${LOGFILE} &&
make check-root \
   >> ${LOGFILE} 2>&1 &&
echo " o Root tests OK" || errmsg

echo "plfstest:x:1000:plfstest" >> /etc/group

echo -e "\n User Tests \n------------" >> ${LOGFILE} &&
su plfstest -c "env RUN_EXPENSIVE_TESTS=yes make check" \
   >> ${LOGFILE} 2>&1 &&
echo " o User tests OK" || errmsg

mv /etc/group /etc/Xgroup
grep -v plfstest /etc/Xgroup > /etc/group
rm -rf /etc/Xgroup
chmod 644 /etc/group

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# Fileutils binaries
mv -f /usr/bin/{chgrp,chmod,chown,cp,dd,df,install} /bin
mv -f /usr/bin/{ln,ls,mkdir,mknod,mv,rm,rmdir,sync} /bin
# Create /usr/bin/install -> /bin/install symlink
ln -sf ../../bin/install /usr/bin

# Textutils binaries
mv -f /usr/bin/{cat,head} /bin

# Sh-utils binaries
mv -f /usr/bin/{basename,date,echo,false,pwd} /bin
mv -f /usr/bin/{sleep,stty,su,test,true,uname} /bin
mv -f /usr/bin/chroot /usr/sbin

# For FHS compliance
ln -sf test "/bin/["
