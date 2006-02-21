INITMODE=754
DIRMODE=755
SCRIPTMODE=755
RULESMODE=644
CONFMODE=644

all: install

install: device_dirs device_link rules scripts boot

rules:
	install -m ${RULESMODE} ${DESTDIR}/etc/udev/rules.d/10-wait-for-sysfs.rules
	install -m ${RULESMODE} ${DESTDIR}/etc/udev/rules.d/50-udev.rules
	install -m ${RULESMODE} ${DESTDIR}/etc/udev/rules.d/60-persistent.rules
	install -m ${RULESMODE} ${DESTDIR}/etc/udev/rules.d/80-sysconfig.rules
	install -m ${RULESMODE} ${DESTDIR}/etc/udev/rules.d/95-debug.rules

scripts:
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/remove_floppy_devices.sh
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/load_floppy_module.sh
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/load_ide_modules.sh
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/firmware.sh
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/input_device.sh
	install -m ${SCRIPTMODE) ${DESTDIR}/lib/udev/mount.sh
	install -m ${CONFMODE} ${DESTDIR}/etc/scsi_id.config
	install -m ${SCRIPTMODE) ${DESTDIR}/usr/bin/udev.count_events

boot:
	install -m ${INITMODE} ${DESTDIR}/etc/init.d/boot.udev
	install -m ${INITMODE} ${DESTDIR}/etc/init.d/boot.udev_retry
	install -m ${CONFMODE} ${DESTDIR}/var/adm/fillup-templates/sysconfig.storage
	install -m ${SCRIPTMODE) doc/show_event_log
	install -m ${CONFMODE} doc/README.Logging

device_dirs:
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/pts
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/shm
	install -d -m ${DIRMODE} ${DESTDIR}/lib/udev/devices/net

device_links:
	ln -sn /proc/self/fd ${DESTDIR}/lib/udev/devices/fd
	ln -sn /proc/self/fd/0 ${DESTDIR}/lib/udev/devices/stdin
	ln -sn /proc/self/fd/1 ${DESTDIR}/lib/udev/devices/stdout
	ln -sn /proc/self/fd/2 ${DESTDIR}/lib/udev/devices/stderr
	ln -sn /proc/kcore ${DESTDIR}/lib/udev/devices/core

.PHONY: all install device_dirs device_links rules scripts boot
