INITMODE=754
DIRMODE=755
SCRIPTMODE=755
RULESMODE=644
CONFMODE=644

all: help

install: device_dirs device_links rules scripts boot mknod_devices

rules:
	install -d ${DESTDIR}/etc/udev/rules.d
	install -m ${RULESMODE} 05-udev-early.rules ${DESTDIR}/etc/udev/rules.d/05-udev-early.rules
	install -m ${RULESMODE} 35-helper.rules ${DESTDIR}/etc/udev/rules.d/35-helper.rules
	install -m ${RULESMODE} 40-modprobe.rules ${DESTDIR}/etc/udev/rules.d/40-modprobe.rules
	install -m ${RULESMODE} 50-udev.rules ${DESTDIR}/etc/udev/rules.d/50-udev.rules
	install -m ${RULESMODE} 55-sound.rules ${DESTDIR}/etc/udev/rules.d/55-sound.rules
	install -m ${RULESMODE} 60-persistent.rules ${DESTDIR}/etc/udev/rules.d/60-persistent.rules
	install -m ${RULESMODE} 90-user.rules ${DESTDIR}/etc/udev/rules.d/90-user.rules
	install -m ${RULESMODE} 95-debug.rules ${DESTDIR}/etc/udev/rules.d/95-debug.rules

scripts:
	install -m ${SCRIPTMODE} load_floppy_module.sh ${DESTDIR}/lib/udev/load_floppy_module.sh
	install -m ${SCRIPTMODE} input.sh ${DESTDIR}/lib/udev/input.sh

boot:
	install -d ${DESTDIR}/usr/share/udev
	install -d ${DESTDIR}/etc/rc.d/rcsysinit.d
	install -d ${DESTDIR}/etc/rc.d/init.d
	install -m ${INITMODE} udev ${DESTDIR}/etc/rc.d/init.d/udev
	install -m ${INITMODE} udev_retry ${DESTDIR}/etc/rc.d/init.d/udev_retry
	install -m ${SCRIPTMODE} show_event_log ${DESTDIR}/usr/share/udev/show_event_log
	ln -sf ../init.d/udev ${DESTDIR}/etc/rc.d/rcsysinit.d/S10udev
	ln -sf ../init.d/udev_retry ${DESTDIR}/etc/rc.d/rcsysinit.d/S45udev_retry

device_dirs:
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/pts
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/shm
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/net

device_links:
	ln -snf /proc/self/fd ${DESTDIR}/lib/udev/devices/fd
	ln -snf /proc/self/fd/0 ${DESTDIR}/lib/udev/devices/stdin
	ln -snf /proc/self/fd/1 ${DESTDIR}/lib/udev/devices/stdout
	ln -snf /proc/self/fd/2 ${DESTDIR}/lib/udev/devices/stderr
	ln -snf /proc/kcore ${DESTDIR}/lib/udev/devices/core

mknod_devices:
	@if [ "$$UID" = "0" ]; then \
		if ! [ -e ${DESTDIR}/lib/udev/devices/null ]; then \
			mknod -m 0666 ${DESTDIR}/lib/udev/devices/null c 1 3 ;\
		fi \
	fi
	@if [ "$$UID" = "0" ]; then \
		if ! [ -e ${DESTDIR}/lib/udev/devices/console ]; then \
			mknod -m 0600 ${DESTDIR}/lib/udev/devices/console c 5 1 ;\
		fi \
	fi
	@if [ "$$UID" != "0" ]; then \
		if ! [ -e ${DESTDIR}/lib/udev/devices/null ]; then \
			echo "You will need to issue the following command as the root user" ;\
			echo "" ;\
			echo "mknod -m 0666 ${DESTDIR}/lib/udev/devices/null c 1 3" ;\
		fi \
	fi
	@if [ "$$UID" != "0" ]; then \
		if ! [ -e ${DESTDIR}/lib/udev/devices/console ]; then \
			echo "mknod -m 0600 ${DESTDIR}/lib/udev/devices/console c 5 1" ;\
			echo "" ;\
		fi \
	fi

help:
	@echo "command				description"
	@echo "---------------------------------------------------------------------------------------"
	@echo "make install			install udev rules package and helper scripts"
	@echo "make install-network		install network helper package"
	@echo "make install-network-upgrade	upgrades current network helper package"
	@echo "---------------------------------------------------------------------------------------"

install-helper-functions:
	install -m 644 contrib/common/helper.functions ${DESTDIR}/lib/udev/helper.functions
	install -m 644 contrib/common/udev_helper ${DESTDIR}/etc/sysconfig/udev_helper
	
install-network: install-helper-functions install-network-update
	@echo "Adding rules to ${DESTDIR}/etc/udev/rules.d/35-helper.rules."
	@cp ${DESTDIR}/etc/udev/rules.d/35-helper.rules /tmp/first
	@cat /tmp/first contrib/network/rules > ${DESTDIR}/etc/udev/rules.d/35-helper.rules 2>&1
	@rm ${DESTDIR}/etc/rc.d/rc2.d/K80network
	@rm ${DESTDIR}/etc/rc.d/rc{3,4,5}.d/S20network

install-network-update:
	install -m ${SCRIPTMODE} contrib/network/network_helper.sh ${DESTDIR}/lib/udev/network_helper.sh
	install -m ${INITMODE} contrib/network/network ${DESTDIR}/etc/rc.d/init.d/network

.PHONY: all install device_dirs device_links rules scripts boot mknod_devices \
	help install-helper-functions install-network install-network-update
