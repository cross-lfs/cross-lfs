#!/bin/bash

# cross-lfs native sysvinit build
# -------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=sysvinit-native.log

set_libdirname
setup_multiarch

unpack_tarball sysvinit-${SYSVINIT_VER} &&
cd ${PKGDIR}

# TODO: add some logic around this...
#       this needs to be tracked
case ${SYSVINIT_VER} in
   2.85 )
      apply_patch sysvinit-2.85-proclen-1
   ;;
esac

# From LFS CVS 
cp src/init.c src/init.c-ORIG &&
sed 's/Sending processes/Sending processes started by init/g' \
    src/init.c-ORIG > src/init.c

# Modify Makefile
test -f src/Makefile-ORIG ||
   cp src/Makefile src/Makefile-ORIG

# 1: Add -pipe to CFLAGS ( default optimization is -O2 )
# 2: Also change BIN_OWNER and BIN_GROUP from "root" to 0
# 3: Modify instructions using chown $(BIN_COMBO) to do a 
#    chown $(BIN_OWNER) and a chgrp $(BIN_GROUP) instead
# 4: makefile works with /dev/initctl, NOT $(ROOT)/dev/initctl
#    change this so it operates on our target root, NOT the hosts
# 5: alter mknod of $(ROOT)/dev/initctl to not set mode while creating the fifo
#    instead set mode with chmod.

sed -e 's@^CFLAGS.*-O2@& -pipe@g' \
    -e 's@root@0@g' \
    -e 's@chown $(BIN_COMBO) \(.*\)@chown $(BIN_OWNER) \1 ;chgrp $(BIN_GROUP) \1@g' \
    -e 's@/dev/initctl@$(ROOT)&@g' \
    -e 's@\(mknod \)-m \([0-9]* \)\(.* \)p@\1\3p; chmod \2\3@g' \
   src/Makefile-ORIG > src/Makefile


max_log_init Sysvinit ${SYSVINIT_VER} "native (shared)" ${BUILDLOGS} ${LOG}
make -C src CC="${CC-gcc} ${ARCH_CFLAGS}" LDFLAGS="-s"  \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

mkdir -p /usr/share/man/man{1,5,8}

min_log_init ${INSTLOGS} &&
make -C src install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

# If we already have an /etc/inittab, move it out the way
test -f /etc/inittab &&
   mv /etc/inittab /etc/inittab-${DATE}

cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc sysinit

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin
EOF

# Check if we are using DEVFS or not before creating getty entries 
# If we are using DEVFS need to specify vc/x NOT ttyx
tty_string="tty"
test Y = "${DEVFS}" &&
   tty_string="vc/"

for vc_no in 1 2 3 4 5 6 ; do
   echo "${vc_no}:2345:respawn:/sbin/agetty ${tty_string}${vc_no} 9600" \
      >> ${LFS}/etc/inittab
done

echo -e "\n# End /etc/inittab" >> ${LFS}/etc/inittab

