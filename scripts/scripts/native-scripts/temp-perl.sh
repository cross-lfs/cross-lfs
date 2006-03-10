#!/bin/bash

# cross-lfs temporary perl build (for running testsuites)
# -------------------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=perl-temp.log

# Test if the 64 script has been called.
# This should only really get called during bi-arch builds
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

test "${SELF}" = "temp-perl-64.sh" && LIB64=Y

unpack_tarball perl-${PERL_VER} &&
cd ${PKGDIR}

chmod u+w hints/linux.sh          # For those not running as a root user

#--------------------------------------------------------------------
# edit linux.sh
#--------------------------------------------------------------------
if [ ! -f hints/linux.sh-ORIG ]; then
   cp hints/linux.sh hints/linux.sh-ORIG
fi

sed -e "s@/lib/libc.so.6@${TGT_TOOLS}/${libdirname}/libc.so.6@g" \
    -e "s@libc=/lib/\$libc@libc=${TGT_TOOLS}/${libdirname}/\$libc@g" \
    hints/linux.sh-ORIG > hints/linux.sh

# adjust Configure and append to linux.sh if not installing to */lib
#--------------------------------------------------------------------
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

   # Now that installstyle can handle lib64, specify our
   # our installstyle in linux.sh
   echo "installstyle=\"${libdirname}/perl5\"" >> hints/linux.sh
fi

echo "locincpth=\"\"
loclibpth=\"\"
glibpth=\"${TGT_TOOLS}/${libdirname}\"
static_ext=\"IO re Fcntl\"" >> hints/linux.sh
#--------------------------------------------------------------------

cd ${SRC}/${PKGDIR}

max_log_init Perl ${PERL_VER} "temp (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
./configure.gnu --prefix=${TGT_TOOLS} \
   -Doptimize="-O2 -pipe ${TGT_CFLAGS}" \
   >> ${LOGFILE} 2>&1 &&

min_log_init ${BUILDLOGS} &&
make perl \
   >> ${LOGFILE} 2>&1 &&
echo -e "${BRKLN}\n" >> ${LOGFILE} &&
make utilities \
   >> ${LOGFILE} 2>&1 &&

min_log_init ${INSTLOGS} &&
{
   rm -f ${TGT_TOOLS}/bin/perl
   cp perl ${TGT_TOOLS}/bin/perl &&
   cp pod/pod2man ${TGT_TOOLS}/bin &&
   mkdir -p ${TGT_TOOLS}/${libdirname}/perl5/${PERL_VER} &&
   cp -R lib/* ${TGT_TOOLS}/${libdirname}/perl5/${PERL_VER}
}  >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "${MULTIARCH}" = "Y" ]; then
   use_wrapper ${TGT_TOOLS}/bin/perl
fi
