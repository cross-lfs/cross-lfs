#!/bin/bash

# cross-lfs target nfs-utils build
# --------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# NOTE: rpc.* binaries aren't created, only standalone nfsd etc
#       I'm not too sure how we'd get rpcgen to work during a cross build

cd ${SRC}
LOG=nfsutils-target.log

set_libdirname
setup_multiarch

if [ "${USE_SYSROOT}" = "Y" ]; then
   BUILD_PREFIX=/usr
   INSTALL_PREFIX="${LFS}${BUILD_PREFIX}"
   INSTALL_OPTIONS="DESTDIR=${LFS}"
else
   BUILD_PREFIX="${TGT_TOOLS}"
   INSTALL_PREFIX="${TGT_TOOLS}"
   INSTALL_OPTIONS=""
fi

unpack_tarball nfs-utils-${NFSUTILS_VER} &&
cd ${PKGDIR}

max_log_init NFS-utils ${NFSUTILS_VER} "target (shared)" ${CONFLOGS} ${LOG}
echo "ac_cv_func_malloc_0_nonnull=yes
ac_cv_func_realloc_0_nonnull=yes" > config.cache

CC="${TARGET}-gcc ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe" \
./configure --prefix=${BUILD_PREFIX} \
   --host=${TARGET} \
   --cache-file=config.cache \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&
#   --sysconfdir=/etc \

# Target env clobbers makefile, unset
unset TARGET

# We cant use the newly built rpcgen when cross-compiling
# HACK: use the hosts
#RPCGEN=rpcgen \
min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
#su -c "export PATH=${PATH} ; make install" \
make ${INSTALL_OPTIONS} install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

