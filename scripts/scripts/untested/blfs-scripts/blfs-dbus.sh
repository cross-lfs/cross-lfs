#!/bin/bash

### dbus ###

cd ${SRC}
LOG=dbus-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch
if [ ! "${libdirname}" = "lib" ]; then
   extra_conf="--libdir=/usr/${libdirname}"
fi

unpack_tarball dbus-${DBUS_VER}
cd ${PKGDIR}

max_log_init dbus ${DBUS_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
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
  --with-system-socket=/var/lib/dbus/system_bus_socket \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
(
   # for the moment create messagebus group and user to be 65533...
   groupadd -g 65533 messagebus
   useradd -u 65533 -g messagebus -c "dbus messagebus user" -d /dev/null \
           -s /bin/false messagebus
   mkdir /var/lib/dbus
   make install 

   cp bus/rc.messagebus /etc/rc.d/init.d/messagebus

   sed -i -e 's@status \$processname@statusproc $processname@g' \
          -e '/init.d\/functions/s@^#@@g' \
          -e '/^processname=/s@^#@@g' \
          -e 's@/usr/bin/dbus-daemon --system@loadproc &@g' \
          -e 's@killall@killproc@g' \
      /etc/rc.d/init.d/messagebus

   for runlevel in 3 4 5; do
      ln -sf ../init.d/messagebus /etc/rc.d/rc${runlevel}.d/S97messagebus
   done

   for runlevel in 0 1 2 6; do
      ln -sf ../init.d/messagebus /etc/rc.d/rc${runlevel}.d/K03messagebus
   done
) >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

cat <<EOF
--------------------------------------------------------
  Please edit /etc/rc.d/init.d/messagebus and fix up 
  the stop function so /var/run/dbus.pid gets removed
--------------------------------------------------------
EOF

