#!/bin/bash

### hal ###

cd ${SRC}
LOG=hal-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

# This could be a little hairy... Uncomment to enable hal to update /etc/fstab
use_fstab_sync="Y"

unpack_tarball hal-${HAL_VER}
cd ${PKGDIR}

if [ "${use_fstab_sync}" = "Y" ]; then
   extra_conf="${extra_conf} --enable-fstab-sync"
fi

max_log_init hal ${HAL_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
CXXFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
LDFLAGS="-L/usr/${libdirname}" \
./configure --prefix=/usr ${extra_conf} \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --mandir=/usr/share/man \
  --infodir=/usr/share/info \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
(
   # for the moment create haldaemon group and user to be 65532...
   groupadd -g 65532 haldaemon
   useradd -u 65532 -g haldaemon -c "hal daemon user" -d /dev/null \
           -s /bin/false haldaemon
   mkdir -p /var/run/hald
   chmod haldaemon:haldaemon /var/run/hald

   make install || barf

   cp hald/haldaemon /etc/rc.d/init.d/
   chmod 755 /etc/rc.d/init.d/haldaemon

   sed -i -e 's@status \$processname@statusproc $processname@g' \
          -e 's@daemon --check .*@loadproc /usr/sbin/hald --retain-privileges@g' \
          -e 's@killall@killproc@g' \
          -e 's@servicename -TERM@processname -TERM@g' \
      /etc/rc.d/init.d/haldaemon

   for runlevel in 3 4 5; do
      ln -sf ../init.d/haldaemon /etc/rc.d/rc${runlevel}.d/S98haldaemon
   done

   for runlevel in 0 1 2 6; do
      ln -sf ../init.d/haldaemon /etc/rc.d/rc${runlevel}.d/K02haldaemon
   done
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf


