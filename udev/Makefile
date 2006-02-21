INITMODE=754
DIRMODE=755
SCRIPTMODE=755
RULESMODE=644
CONFMODE=644

all: install

install: device_dirs device_links rules scripts boot

rules:
	install -m ${RULESMODE} 05-udev-early.rules ${DESTDIR}/etc/udev/rules.d/05-udev-early.rules
	install -m ${RULESMODE} 50-udev.rules ${DESTDIR}/etc/udev/rules.d/50-udev.rules
	install -m ${RULESMODE} 60-persistent.rules ${DESTDIR}/etc/udev/rules.d/60-persistent.rules
	install -m ${RULESMODE} 85-mount-fstab.rules ${DESTDIR}/etc/udev/rules.d/85-mount-fstab.rules
	install -m ${RULESMODE} 95-debug.rules ${DESTDIR}/etc/udev/rules.d/95-debug.rules

scripts:
	install -m ${SCRIPTMODE} load_floppy_module.sh ${DESTDIR}/lib/udev/load_floppy_module.sh
	install -m ${SCRIPTMODE} ide.sh ${DESTDIR}/lib/udev/ide.sh
	install -m ${SCRIPTMODE} input.sh ${DESTDIR}/lib/udev/input.sh
	install -m ${SCRIPTMODE} mount.sh ${DESTDIR}/lib/udev/mount.sh
	install -m ${CONFMODE} scsi_id.config ${DESTDIR}/etc/scsi_id.config
	install -m ${SCRIPTMODE} udev.count_events ${DESTDIR}/usr/bin/udev.count_events

boot:
	install -d ${DESTDIR}/usr/share/udev
	install -m ${INITMODE} udev ${DESTDIR}/etc/rc.d/init.d/udev
	install -m ${INITMODE} udev_retry ${DESTDIR}/etc/rc.d/init.d/udev_retry
	install -d ${DESTDIR}/var/adm/fillup-templates
	install -m ${CONFMODE} sysconfig.storage ${DESTDIR}/var/adm/fillup-templates/sysconfig.storage
	install -m ${SCRIPTMODE} show_event_log ${DESTDIR}/usr/share/udev/show_event_log
	install -m ${CONFMODE} README.Logging ${DESTDIR}/usr/share/udev/README.Logging
	ln -sf ../init.d/udev ${DESTDIR}/etc/rc.d/rcsysinit.d/S10udev
	ln -sf ../init.d/udev_retry ${DESTDIR}/etc/rc.d/rcsysinit.d/S15udev_retry

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

.PHONY: all install device_dirs device_links rules scripts boot
