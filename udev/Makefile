INITMODE=754
DIRMODE=755
SCRIPTMODE=755
RULESMODE=644
CONFMODE=644
LIBDIR=lib

all: help

install: device_dirs device_links rules scripts boot mknod_devices

install-minimal: install-netboot boot

install-netboot: device_dirs device_links rules-netboot mknod_devices

rules:
	install -d ${DESTDIR}/etc/udev/rules.d
	install -m ${RULESMODE} 05-udev-early.rules ${DESTDIR}/etc/udev/rules.d/05-udev-early.rules
	install -m ${RULESMODE} 35-helper.rules ${DESTDIR}/etc/udev/rules.d/35-helper.rules
	install -m ${RULESMODE} 40-modprobe.rules ${DESTDIR}/etc/udev/rules.d/40-modprobe.rules
	install -m ${RULESMODE} 50-udev.rules ${DESTDIR}/etc/udev/rules.d/50-udev.rules
	install -m ${RULESMODE} 60-persistent-disk.rules ${DESTDIR}/etc/udev/rules.d/60-persistent-disk.rules
	install -m ${RULESMODE} 61-persistent-input.rules ${DESTDIR}/etc/udev/rules.d/61-persistent-input.rules
	install -m ${RULESMODE} 90-user.rules ${DESTDIR}/etc/udev/rules.d/90-user.rules
	install -m ${RULESMODE} 95-debug.rules ${DESTDIR}/etc/udev/rules.d/95-debug.rules

rules-netboot:
	install -d ${DESTDIR}/etc/udev/rules.d
	install -m ${RULESMODE} 05-udev-early.rules ${DESTDIR}/etc/udev/rules.d/05-udev-early.rules
	install -m ${RULESMODE} 50-udev.rules ${DESTDIR}/etc/udev/rules.d/50-udev.rules

scripts:
	install -d -m ${DIRMODE} ${DESTDIR}/udev
	install -m ${SCRIPTMODE} load_floppy_module.sh ${DESTDIR}/${LIBDIR}/udev/load_floppy_module.sh
	install -m ${SCRIPTMODE} cdsymlink_helper.sh ${DESTDIR}/${LIBDIR}/udev/cdsymlink_helper.sh

boot:
	install -d ${DESTDIR}/usr/share/udev
	install -d ${DESTDIR}/etc/rc.d/rcsysinit.d
	install -d ${DESTDIR}/etc/rc.d/init.d
	install -m ${INITMODE} udev ${DESTDIR}/etc/rc.d/init.d/udev
	install -m ${SCRIPTMODE} show_event_log ${DESTDIR}/usr/share/udev/show_event_log
	ln -sf ../init.d/udev ${DESTDIR}/etc/rc.d/rcsysinit.d/S10udev

device_dirs:
	install -d -m ${DIRMODE} ${DESTDIR}/${LIBDIR}/udev/devices
	install -d -m ${DIRMODE} ${DESTDIR}/${LIBDIR}/udev/devices/pts
	install -d -m ${DIRMODE} ${DESTDIR}/${LIBDIR}/udev/devices/shm
	install -d -m ${DIRMODE} ${DESTDIR}/${LIBDIR}/udev/devices/net

device_links: device_dirs
	ln -snf /proc/self/fd ${DESTDIR}/${LIBDIR}/udev/devices/fd
	ln -snf /proc/self/fd/0 ${DESTDIR}/${LIBDIR}/udev/devices/stdin
	ln -snf /proc/self/fd/1 ${DESTDIR}/${LIBDIR}/udev/devices/stdout
	ln -snf /proc/self/fd/2 ${DESTDIR}/${LIBDIR}/udev/devices/stderr
	ln -snf /proc/kcore ${DESTDIR}/${LIBDIR}/udev/devices/core

mknod_devices: device_dirs
	@if [ "$$UID" = "0" ]; then \
		if ! [ -e ${DESTDIR}/${LIBDIR}/udev/devices/null ]; then \
			mknod -m 0666 ${DESTDIR}/${LIBDIR}/udev/devices/null c 1 3 ;\
		fi \
	fi
	@if [ "$$UID" = "0" ]; then \
		if ! [ -e ${DESTDIR}/${LIBDIR}/udev/devices/console ]; then \
			mknod -m 0600 ${DESTDIR}/${LIBDIR}/udev/devices/console c 5 1 ;\
		fi \
	fi
	@if [ "$$UID" != "0" ]; then \
		if ! [ -e ${DESTDIR}/${LIBDIR}/udev/devices/null ]; then \
			echo "You will need to issue the following command as the root user" ;\
			echo "" ;\
			echo "mknod -m 0666 ${DESTDIR}/${LIBDIR}/udev/devices/null c 1 3" ;\
		fi \
	fi
	@if [ "$$UID" != "0" ]; then \
		if ! [ -e ${DESTDIR}/${LIBDIR}/udev/devices/console ]; then \
			echo "mknod -m 0600 ${DESTDIR}/${LIBDIR}/udev/devices/console c 5 1" ;\
			echo "" ;\
		fi \
	fi

help:
	@echo "command				description"
	@echo "---------------------------------------------------------------------------------------"
	@echo "make install			install udev rules package and helper scripts"
	@echo "make install-device-mapper	install device-mapper rules"
	@echo "make install-netboot		install udev rules package for netboot"
	@echo "make install-network		install network helper package"
	@echo "make install-network-upgrade	upgrades current network helper package"
	@echo "make install-sound		install sound rules"
	@echo "---------------------------------------------------------------------------------------"
	@echo "add LIBDIR=lib64 		when using /lib64/"
	@echo "example	make  LIBDIR=lib64 install"
	@echo "---------------------------------------------------------------------------------------"

install-helper-functions:
	install -d ${DESTDIR}/${LIBDIR}/udev
	install -d ${DESTDIR}/etc/sysconfig
	install -m 644 contrib/common/helper.functions ${DESTDIR}/${LIBDIR}/udev/helper.functions
	install -m 644 contrib/common/udev_helper ${DESTDIR}/etc/sysconfig/udev_helper
	
install-device-mapper:
	install -d ${DESTDIR}/${LIBDIR}/udev
	install -d ${DESTDIR}/etc/rc.d/init.d
	install -m ${RULESMODE} 64-device-mapper.rules ${DESTDIR}/etc/udev/rules.d/64-device-mapper.rules

install-network: install-helper-functions install-network-update
	install -d ${DESTDIR}/etc/udev/rules.d/
	@echo "Adding rules to ${DESTDIR}/etc/udev/rules.d/35-helper.rules."
	@cp ${DESTDIR}/etc/udev/rules.d/35-helper.rules /tmp/first
	@cat /tmp/first contrib/network/rules > ${DESTDIR}/etc/udev/rules.d/35-helper.rules 2>&1
	@rm -f ${DESTDIR}/etc/rc.d/rc2.d/*network
	@rm -f ${DESTDIR}/etc/rc.d/rc{3,4,5}.d/*network

install-sound:
	install -d ${DESTDIR}/${LIBDIR}/udev
	install -d ${DESTDIR}/etc/rc.d/init.d
	install -m ${RULESMODE} 55-sound.rules ${DESTDIR}/etc/udev/rules.d/55-sound.rules

install-network-update:
	install -d ${DESTDIR}/${LIBDIR}/udev
	install -d ${DESTDIR}/etc/rc.d/init.d
	install -m ${SCRIPTMODE} contrib/network/network_helper.sh ${DESTDIR}/${LIBDIR}/udev/network_helper.sh
	install -m ${INITMODE} contrib/network/network ${DESTDIR}/etc/rc.d/init.d/network

.PHONY: all install device_dirs device_links rules scripts boot mknod_devices \
	help install-helper-functions install-network install-network-update \
	install-netboot rules-netboot
