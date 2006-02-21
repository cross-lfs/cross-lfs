#!/bin/bash

# cross-lfs native perl build
# ---------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=perl-native.log

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

test "${SELF}" = "native-perl-64.sh" && LIB64=Y

unpack_tarball perl-${PERL_VER} &&
cd ${PKGDIR}

chmod u+w hints/linux.sh          # For those not running as a root user

if [ ! "${libdirname}" = "lib" ]; then
   # We need to adjust Configure so that it understands 
   # installstyle=lib64/perl5 and sets up directory paths accordingly
   # NOTE: may need to check how this affects vendor libs...
   if [ ! -f Configure-ORIG ]; then cp Configure Configure-ORIG ;fi
   sed "/\*lib\/perl5\*).*/{
        h
        s/\([^a-zA-Z]\)lib/\1${libdirname}/g
        x
        G }" Configure-ORIG > Configure

   # edit linux.sh
   if [ ! -f hints/linux.sh-ORIG ]; then
      cp hints/linux.sh hints/linux.sh-ORIG
   fi
   sed -e "s@/lib/libc.so.6@/${libdirname}/libc.so.6@g" \
       -e "s@libc=/lib/\$libc@libc=/${libdirname}/\$libc@g" \
       hints/linux.sh-ORIG > hints/linux.sh

   # Now that installstyle can handle lib64, specify our
   # our installstyle in linux.sh
   echo "installstyle=\"${libdirname}/perl5\"" >> hints/linux.sh
   # override standard glibpth
   echo "glibpth=\"/${libdirname} /usr/${libdirname}\"" >> hints/linux.sh
fi

# override loclibpth
# NOTE: by rights during this stage of the build there shouldn't be
#       any libs in the local lib paths 
#       (ie /usr/local/lib{,64} ,  /opt/local/lib{,64}) 
#       so we just clear this (as we do ch5). 
#
#       Other option is to set
#       loclibpth=\"/usr/local/${libdir} /opt/local/${libdir}\" 
#       (and optionally /usr/gnu/${libdir})
#
echo "loclibpth=\"\"" >> hints/linux.sh
cd ${SRC}/${PKGDIR}

# if not creating a shared libperl (ie useshrplib not true), still use pic
sed -i -e "s@pldlflags=''@pldlflags=\"\$cccdlflags\"@g" \
       -e "s@static_target='static'@static_target='static_pic'@g" \
   Makefile.SH

max_log_init Perl ${PERL_VER} "native (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure.gnu --prefix=/usr \
   -Doptimize="-O2 -pipe ${TGT_CFLAGS}" \
   -Dman1dir='/usr/share/man/perl/man1' \
   -Dman3dir='/usr/share/man/perl/man3' \
   -Dcccdlflags='-fPIC' \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make LDFLAGS="-s" \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/bin/{perl,perl${PERL_VER}}
fi
