#!/bin/bash

# cross-lfs target lfs bootscripts installation
# ---------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

LOG="lfs-bootscripts.log"
cd ${SRC}

unpack_tarball lfs-bootscripts-${LFS_BS_VER}
cd ${PKGDIR}

# Following commented lines are for using the *old* lfs bootscripts package
#cp -a rc.d sysconfig ${LFS}/etc
#chown -R root:root ${LFS}/etc/rc.d ${LFS}/etc/sysconfig

max_log_init lfs-bootscripts ${LFS_BS_VER} "target" ${INSTLOGS} ${LOG}
make DESTDIR=${LFS} install \
   > ${LOGFILE} 2>&1 &&
echo " o Install OK" || barf

if [ "Y" = "${USE_HOTPLUG}" ]; then
   # check if this version of the bootscripts has an 
   # intall-hotplug target
   grep ^install-hotplug: Makefile > /dev/null 2>&1 &&
   {
      make DESTDIR=${LFS} install-hotplug \
         >> ${LOGFILE} 2>&1 &&
      echo " o Install hotplug OK" || barf
   }
fi

# Bootscript Configuration
#--------------------------

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # The normal PATH won't find our TGT_TOOLS binaries; so use the default
   # PATH we give in /etc/profile later.
   sed -e 's/^export PATH=.*//' < lfs/init.d/functions \
      > ${LFS}/etc/rc.d/init.d/functions
fi

# setup system clock settings
test -f ${LFS}/etc/sysconfig/clock ||
{
   # hardware clock should be set to UTC
   cat > ${LFS}/etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock
UTC=1

# End /etc/sysconfig/clock
EOF
}

# TODO: Put these in plfs-config
NET_HOSTNAME="asuka"
NET_DOMAINNAME="pha.com.au"
NET_IP=192.168.0.6
NET_NETMASK=255.255.255.0
NET_PREFIX=24
NET_BCAST=192.168.0.255
NET_GATEWAY=192.168.0.1
NET_GATEWAY_IF=eth0

test -f ${LFS}/etc/hosts ||
{
echo "127.0.0.1	localhost.localdomain	localhost
${NET_IP}	${NET_HOSTNAME}.${NET_DOMAINNAME}	${NET_HOSTNAME}" > ${LFS}/etc/hosts
}

test -f ${LFS}/etc/sysconfig/network ||
{
   echo "HOSTNAME=${NET_HOSTNAME}" > ${LFS}/etc/sysconfig/network

# Following commented lines are for using the *old* lfs bootscripts package
#   test -z "${NET_GATEWAY}" ||
#   {
#      echo "GATEWAY=${NET_GATEWAY}
#GATEWAY_IF=${NET_GATEWAY_IF}" >> ${LFS}/etc/sysconfig/network
#   }
}

# Following commented lines are for using the *old* lfs bootscripts package
#test -f ${LFS}/etc/sysconfig/network-devices/ifconfig.${NET_GW_IF} ||
#{
#   echo "ONBOOT=yes
#SERVICE=static
#IP=${NET_IP}
#NETMASK=${NET_NETMASK}
#BROADCAST=${NET_BCAST}" \
#   > ${LFS}/etc/sysconfig/network-devices/ifconfig.${NET_GW_IF} 
#}

test -f ${LFS}/etc/sysconfig/network-devices/ifconfig.${NET_GW_IF} ||
{
   echo "ONBOOT=yes
SERVICE=ipv4-static
IP=${NET_IP}
GATEWAY=${NET_GATEWAY}
PREFIX=${NET_PREFIX}
BROADCAST=${NET_BCAST}" \
   > ${LFS}/etc/sysconfig/network-devices/ifconfig.${NET_GW_IF} 
}

