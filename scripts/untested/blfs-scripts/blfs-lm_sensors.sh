#!/bin/bash

### lm_sensors ###

cd ${SRC}
LOG=lm_sensors-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball lm_sensors-${LM_SENSORS_VER}
cd ${PKGDIR}

max_log_init lm_sensors ${LM_SENSORS_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
make \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CFLAGS="${TGT_CFLAGS}" \
   PREFIX=/usr \
   LIBDIR=/usr/${libdirname} \
   user \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make \
   CC="${CC-gcc} ${ARCH_CFLAGS}" \
   CFLAGS="${TGT_CFLAGS}" \
   PREFIX=/usr \
   LIBDIR=/usr/${libdirname} \
   user_install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

echo"
###############################################################
# TODO: This should be handled by udev, devices don't get 
#       automatically created...
#       Also, sensors-detect needs to be run, startup scripts
#       installed ...
###############################################################
#prog/mkdev/mkdev.sh
#sensors-detect
#cp prog/init/lm_sensors.init /etc/rc.d/init.d/lm_sensors
#echo \"alias char-major-89 i2c-dev\" >> /etc/modules.conf
#mkdir -p /var/lock/subsys
"
