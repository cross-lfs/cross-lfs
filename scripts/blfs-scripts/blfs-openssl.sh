#!/bin/bash

### OPENSSL ###
# deps
# zlib
# krb5 (optional)
# TODO: for krb5 support some hackery is required

cd ${SRC}
LOG=openssl-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball openssl-${OPENSSL_VER} &&
cd ${PKGDIR}

# patching...
# TODO: check 0.9.7e to see which patches apply
case ${OPENSSL_VER} in
   0.9.7d ) 
      # Adds a Configure target for linux-x86_64-32
      apply_patch openssl-0.9.7d-32bit_x86_64
      # Adds a make option ( LIBDIR ) for setting ${libdirname}
      apply_patch openssl-0.9.7d-allow_lib64
      # Fix for brokenness in kssl.h 
      # ( applies to 0.9.7f. For mit krb5 1.3.5, test for 1.4 )
      apply_patch openssl-0.9.7d-mit_krb5
   ;;
   0.9.7f ) 
      # Adds a Configure target for linux-x86_64-32
      apply_patch openssl-0.9.7f-32bit_x86_64
      # Adds a make option ( LIBDIR ) for setting ${libdirname}
      apply_patch openssl-0.9.7f-allow_lib64
      # Fix for brokenness in kssl.h 
      # ( applies to 0.9.7f. For mit krb5 1.3.5, test for 1.4 )
      apply_patch openssl-0.9.7d-mit_krb5
   ;;
   0.9.7g ) 
      # Adds a Configure target for linux-x86_64-32
      apply_patch openssl-0.9.7f-32bit_x86_64
      # Adds a make option ( LIBDIR ) for setting ${libdirname}
      apply_patch openssl-0.9.7f-allow_lib64
   ;;
esac

# TODO: *** MORE WILL NEED TO GO HERE ###
#       Only known to work with x86_64 so far... further edits to Configure
#       may be required to hardcode ARCH_CFLAGS in (depending on arch)
CONFIG="config"
if [ "Y" = "${MULTIARCH}" ]; then
   case ${BUILDENV} in
      64 )
         # set arch specific 64 bit compilation flags
         case ${TGT_ARCH} in
            x86_64 )
               CONFIG_TARGET="linux-x86_64"
               CONFIG="Configure"
            ;;
            sparc* )
               CONFIG_TARGET="linux64-sparcv9"
               CONFIG="Configure"
            ;;
            powerpc* | ppc* )
            ;;
            s390* )
               CONFIG_TARGET="linux-s390x"
               CONFIG="Configure"
            ;;
         esac
      ;;
      32 )
         case ${TGT_ARCH} in
            x86_64 | x86-64 )
               CONFIG_TARGET="linux-x86_64-32"
               CONFIG="Configure"
            ;;
            sparc* )
               # ultrasparc specific here ...
               CONFIG_TARGET="linux-sparcv9"
               CONFIG="Configure"
            ;;
            powerpc* | ppc* )
            ;;
         esac
      ;;
      31 )
         case ${TGT_ARCH} in
            s390* )
               CONFIG_TARGET="linux-s390"
               CONFIG="Configure"
            ;;
         esac
      ;;
   esac
fi

# Dont clobber existing docs
sed 's/^passwd/openssl-passwd/' doc/apps/passwd.pod \
    > doc/apps/openssl-passwd.pod &&
rm doc/apps/passwd.pod &&
mv doc/crypto/{,openssl_}threads.pod &&

#TODO: use -mtune or -march?
#      also need to cater for non-x86
sed -i -e 's/-m486/-mtune=i486/' \
       -e 's/-mcpu=/-mtune=/' Configure

# HACK: hack Configure to find krb libraries under ${libdirname}...
#if [ ! "${libdirname}" = "lib" ]; then
#   sed -i -e "s@/lib\( \|\"\)@/${libdirname}\1@g" Configure
#fi

max_log_init OpenSSL ${OPENSSL_VER} "native (shared)" ${CONFLOGS} ${LOG}
./${CONFIG} ${CONFIG_TARGET} \
  --prefix=/usr \
  --openssldir=/etc/ssl \
  --with-krb5-dir=/usr \
  --with-krb5-flavor=MIT \
  threads zlib-dynamic shared \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make ${PMFLAGS} LIBDIR=${libdirname} MANPATH=/usr/share/man \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${TESTLOGS} &&
make LIBDIR=${libdirname} test \
   >>  ${LOGFILE} 2>&1 &&
echo " o Test OK" &&

min_log_init ${INSTLOGS} &&
make MANDIR=/usr/share/man LIBDIR=${libdirname} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

