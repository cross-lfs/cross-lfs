#!/bin/bash

# cross-lfs target hotplug build
# ------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

LOG="hotplug.log"
cd ${SRC}

unpack_tarball hotplug-${HOTPLUG_VER}
cd ${PKGDIR}

max_log_init hotplug ${HOTPLUG_VER} "target" ${INSTLOGS} ${LOG}
echo "Password: " 
su -c "make prefix=${LFS} install" \
   > ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

